require "rexml/document"

require_relative "flag_set"
require_relative "host_set"
require_relative "host_group_set"
require_relative "ssh_util"
require_relative "job_manager"
require_relative "callback_factory"

# This module allows the user to load settings from file.
module Settings
  # Reads the settings from a file.
  # For the file format see the {file:docs/formats.md format documentation}.
  # @param filename [String] The name of the file to be read from.
  # @see {file:docs/formats.md Format documentation}.
  def Settings.load_settings(load_ssh_settings=true, filename = "settings.xml")
    doc = REXML::Document.new open(filename)
    $SLURM_POLL_DELAY = doc.elements["settings/slurm-poll-delay"].text.to_i
    
    if load_ssh_settings then
      ssh_agent_element = doc.elements["settings/ssh-agent"]
      if !ssh_agent_element.nil? then
        load_ssh_agent_settings ssh_agent_element
      end
    end

    doc.elements.each("settings/hostset-file") do |elem|
      load_hosts elem
    end
    doc.elements.each("settings/flagset-file") do |elem|
      load_flags elem
    end
    doc.elements.each("settings/hostgroupset-file") do |elem|
      load_hostgroups elem
    end

    init_jobmanager

    doc.elements.each("settings/callbacks/callback") do |elem|
      load_callbacks elem
    end

    doc.elements.each("settings/pre-exec") do |elem|
      run_pre_exec elem
    end
  end

  # @private
  def Settings.load_ssh_agent_settings(xml_element)
    SSHUtil.start_agent

    askpass = xml_element.attributes["askpass"]

    xml_element.elements.each("add-key") do |elem|
      if askpass.nil? then
        SSHUtil.add_key(elem.text)
      else
        SSHUtil.add_key(elem.text, askpass)
      end
    end
  end

  # @private
  def Settings.load_hosts(xml_element)
    init_hostset
    $HOSTSET.read_from_file File.expand_path(xml_element.text)
  end

  # @private
  def Settings.load_flags(xml_element)
    init_flagsets
    flagset = FlagSet.new
    flagset.read_from_file File.expand_path(xml_element.text)
    $FLAGSETS[flagset.name] = flagset
  end

  # @private
  def Settings.load_hostgroups(xml_element)
    init_hostgroupset
    $HOSTGROUPSET.read_from_file File.expand_path(xml_element.text)
  end

  # @private
  def Settings.init_hostset()
    $HOSTSET = HostSet.new if $HOSTSET.nil?
  end

  # @private
  def Settings.init_flagsets()
    $FLAGSETS = {} if $FLAGSETS.nil?
  end

  # @private
  def Settings.init_hostgroupset()
    $HOSTGROUPSET = HostGroupSet.new($HOSTSET) if $HOSTGROUPSET.nil?
  end

  # @private
  def Settings.init_jobmanager()
    $JOBMANAGER = JobManager.new $HOSTGROUPSET
  end

  # @private
  def Settings.load_callbacks(xml_element)
    callbacks = []

    type = case xml_element.attributes["type"]
           when "group_complete"
             :group_complete
           else
             raise ArgumentError,
               "currently only \"group_complete\" allowed for callback type"
           end

    callback_type = xml_element.attributes["callback-type"]

    arguments = {}
    xml_element.elements.each("argument") do |arg|
      arguments[arg.attributes["name"]] = arg.text.chomp
    end

    selector = xml_element.attributes[selector]

    case callback_type
    when "mail"
      CallbackFactory.generate_mail_for_batch_callback type, selector,
        arguments["batch_size"].to_i,  arguments["to"]
    else
      raise ArgumentError, "unknown callback-type #{callback_type}"
    end
  end

  # @private
  def Settings.run_pre_exec(xml_element)
    eval xml_element.text
  end
end

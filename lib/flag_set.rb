require "rexml/document"

require_relative "flag"
require_relative "flag_factory"
require_relative "logged_class"

# This class represets a set of {Flag}s.
class FlagSet
  include LoggedClass

  attr_accessor :flags, :name

  def initialize()
    @flags = []
    @flag_map = {}
  end

  # Returns the size of the set.
  # @return [Fixnum]
  def size()
    @flags.size
  end

  # Adds a flag to the set.
  # @raise [IndexError] if a {Flag} with the same name is already present in the set.
  # @param flag [Flag]
  def add(flag)
    if @flag_map.include?(flag.name) then
      raise IndexError, "Flag #{flag.name} already in Set #{name}"
    end
    @flag_map[flag.name] = flag
    @flags << flag
  end

  # Add all {Flag}s of another set to this one.
  #
  # If two {Flag}s from both sets have the same name, then the one in the called
  # instance will be retained.
  # @param other [FlagSet] The {FlagSet} containing the {Flag}s to be merged.
  def merge(other)
    other.each do |flag| 
      begin
        self << flag 
      rescue IndexError
      end
    end
  end

  # Removes a {Flag} from the set.
  # @raise [IndexError] if the argument is not a {Flag} present in the set and argument dosen't namen an {Flag} present in the set.
  # @param flag [String,Flag] The {Flag} object to be removed or the name of the {Flag} to be removed.
  def remove_flag(flag)
    if flag.is_a? Flag then
      flag_object = flag
      flag_string = flag.name
    else
      flag_object = self[flag]
      flag_string = flag
    end

    if flag_string.nil? or flag_object.nil? then
      raise IndexError,
        "Can't remove Flag; " +
        "Not in set or not a name of a flag contained in the set"
    end

    @flags -= [flag_object]
    @flag_map.delete(flag_string)
  end

  # Removes an entire groupe of {Flag}s from the set.
  # @param group [String] Name of the group of Flags to be removed.
  def remove_group(group)
    debug "removing group #{group} from #{name}"
    self.each do |flag|
      remove_flag flag if flag.in_group? group
    end
  end

  alias :<< :add

  # Queries the set for a {Flag} of a specific name.
  # @param name [String] Name of the Flag being queried for.
  # @raise [IndexError] if no {Flag} of that name can be found in the set.
  # @return [Flag]
  def [](name)
    raise IndexError,
      "No flag of name #{name} found in the set" if @flag_map[name].nil?
    @flag_map[name]
  end

  # Returns an iterator over all flags.
  # @yield [Flag] each {Flag} of this set.
  def each()
    @flags.each do |flag|
      yield flag
    end
  end

  # Reads {Flag}s from a file and adds them to the set.
  # For the file format see the {file:docs/formats.md format documentation}.
  # @param filename [String] The name of the file to be read from.
  # @see {file:docs/formats.md Format documentation}.
  def read_from_file(filename)
    debug "reading flags from file #{filename}"
    doc = REXML::Document.new open(filename)
    @name = doc.elements.first.attributes["name"]
    doc.elements.each('flags/flag') do |elem|
      name = elem.attributes["name"]
      type = elem.attributes["type"]

      groups = elem.attributes["group"]
      groups = groups.nil? ? [] : groups.split


      case type
      when "gcc", "gcc-define"
        delimiter = elem.attributes["delimiter"]
        if delimiter.nil? then
          delimiter = "="
        end
        prefix = elem.attributes["prefix"]
        if prefix.nil? then
          prefix = type == "gcc-define" ? "-D" : "-f"
        end
        domain_type = elem.attributes["domain-type"]
        case domain_type
        when "Range"
          domain = get_range elem
        when "boolean"
          domain = :boolean
        when "boolean_no"
          domain = :boolean_no
        when "list"
          list_elements = []
          elem.elements.each("list-element") do |list_elem|
            list_elements << list_elem.attributes["value"]
          end
          domain = list_elements
        end
        self << FlagFactory.generate_gcc_flag(name, domain, prefix, delimiter, groups)
      when "gcc-param"
        self << FlagFactory.generate_gcc_param_flag(name, domain, groups)
      when "gcc-machine"
        self << FlagFactory.generate_gcc_machine_flag(name, domain, groups)
      end
    end
  end

  private
  def get_range(elem)
    range_elem = elem.elements["range"]
    from = range_elem.attributes["from"]
    to = range_elem.attributes["to"]
    Range.new(from.to_i, to.to_i)
  end
end

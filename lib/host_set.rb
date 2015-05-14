require "rexml/document"

require_relative "host"
require_relative "slurm_host"
require_relative "logged_class"

# This class is a container for {Host}s.
class HostSet
  include LoggedClass

  def initialize()
    @hosts = {}
  end

  # Add a host to the set.
  # @param host [Host] Host to be added.
  def <<(host)
    @hosts[host.hostname] = host
  end

  # Looks up host by hostname, or alias.
  # @param name [String] Hostname or alias of the host to be retrieved.
  # @return [Host] The host queried for or nil if no host by this hostname or alias can be found.
  def [](name)
    @hosts[name]
  end

  # Returns an iterator over all flags.
  # @yield [Flag] each {Flag} of this set.
  def each()
    @hosts.each() do |host|
      yield host
    end
  end

  # @return [Fixnum] Number of hosts in the set.
  def size()
    @hosts.size
  end

  # Adds an alias for a hostname.
  # @param name [String] Alias under which the host will also be found.
  # @param hostname [String] Hostname of the host belonging to the alias.
  def add_alias(name, hostname)
    @hosts[name] = @hosts[hostname]
  end

  # Reads {Host}s from a file and adds them to the set.
  # For the file format see the {file:docs/formats.md format documentation}.
  # @param filename [String] The name of the file to be read from.
  # @see {file:docs/formats.md Format documentation}.
  def read_from_file(filename)
    debug "reading HostSet from file #{filename}"
    doc = REXML::Document.new open(filename)
    doc.elements.each('hosts/host') do |elem|
      hostname = elem.attributes["hostname"]

      aliases = elem.attributes["aliases"]

      if aliases.nil? then
        aliases = [hostname]
      else
        aliases = aliases.split + [hostname]
      end

      user = elem.attributes["user"]
      port = elem.attributes["port"]
      slurm_host = elem.attributes["slurm-host"]
      partition = elem.attributes["partition"]

      case slurm_host
      when nil
        if port.nil? then
          host = Host.new(user, hostname)
        else
          host = Host.new(user, hostname, port)
        end
      else
        if self[slurm_host].nil?
          raise ArgumentError,
            "slurm-host not found. " +
            "The slurm-host of a host needs to preceed it in the hostset file"
        end
        if port.nil? then
          host = SlurmHost.new(user, hostname, self[slurm_host], partition)
        else
          host = SlurmHost.new(user, hostname, self[slurm_host], partition,
                               port)
        end
      end

      self << host

      aliases.each() do |name| 
        self.add_alias(name, hostname)
      end
    end
  end
end

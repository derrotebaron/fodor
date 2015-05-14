require "rexml/document"

require_relative "host_group"

# This class is a container for {HostGroups}s.
class HostGroupSet
  include LoggedClass

  # @param host_set [HostSet] {HostSet} of {Host}s contained in the {HostGroup}s of this set. This is used for identifying hosts by their hostname or alias when reading the set from a file. Defaults to the global host set.
  def initialize(host_set=$HOSTSET)
    @host_set, @groups = host_set, {}
  end

  # Adds a host group to the set.
  # @param group [HostGroup] Host group to be added.
  def <<(group) 
    @groups[group.name] = group
  end

  # Looks up host group by its name.
  # @param name [String] Name of the host group to search for.
  # @return [HostGroup,NilClass] The host group if it can be found. Nil otherwise.
  def [](name)
    @groups[name]
  end

  # Returns an iterator over all host groups.
  # @yield [HostGroup] each {HostGroup} of this set.
  def each()
    @groups.each() { |group| yield group }
  end

  # @return [Fixnum] Number of host groups in the set.
  def size()
    @groups.size
  end

  # Reads {HostGroup}s from a file and adds them to the set.
  # For the file format see the {file:docs/formats.md format documentation}.
  # @param filename [String] The name of the file to be read from.
  # @see {file:docs/formats.md Format documentation}.
  def read_from_file(filename)
    debug "reading HostGroup from file #{filename}"
    doc = REXML::Document.new open(filename)
    doc.elements.each('host-groups/host-group') do |elem|
      name = elem.attributes["name"]
      description = elem.attributes["description"]
      host_group = HostGroup.new name, description
      elem.elements.each("host") do |host_elem|
        host_group << @host_set[host_elem.text]
      end
      self << host_group
    end
  end
end

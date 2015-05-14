require_relative "host"
require_relative "logged_class"

# This class represents a group of hosts. Its use is to partition all hosts and to provide allocation/deallocation features so that host are dedicated to maximal one job at a time.
# Don't create overlapping host groups, since they otherwise might be used twice.
# For {SlurmHost}s this class checks if the host is dead before it will be allocated.
class HostGroup
  include LoggedClass

  attr_reader :name, :description

  # Creates a new host group.
  # @param name [String] Name of the host group.
  # @param description [String] A short textual description of the host group. This is currently unused.
  def initialize(name, description="")
    @mutex, @condition = Mutex.new, ConditionVariable.new
    @hosts = {}
    @unused_hosts = []
    @name, @description = name, description
    @dead_hosts = []
    @hostnames = []
  end

  # Adds {Host} to host group.
  # @param host [Host] Host to be inserted into the host group.
  def <<(host)
    @mutex.synchronize {
      raise ArgumentError,
      "No duplicate hosts allowed" unless self[host.hostname].nil?
      @hosts[host.hostname] = { :used => false, :host => host }
      @unused_hosts << host.hostname
      @hostnames << host.hostname
    }
  end

  # Looks up host in the group by its hostname.
  # @param hostname [String] Hostname of the host to be queried.
  # @return [Host, NilClass] the found host if a host can be found, nil otherwise.
  def [](hostname)
    return nil if @hosts[hostname].nil?
    @hosts[hostname][:host]
  end

  # Checks if a host given by its hostname is in use.
  # @param hostname [String] Hostname of host, whose availiability should be checked.
  # @return [Boolean] true if the host is in use, false otherwise.
  def host_in_use?(hostname)
    @hosts[hostname][:used]
  end

  # Allocates a unused host.
  # If no unused hosts are availiable, this method blocks until one become availiable.
  # This is thread-safe and will never return the same host to two blocked callers.
  # This also checks in the case of the host being a {SlurmHost}, if the host is alive.
  # @return [Host] a host currently not in use.
  def allocate()
    filter_dead_nodes
    @mutex.synchronize {
      host = @unused_hosts.shift
      while host.nil? do
        @condition.wait(@mutex)
        host = @unused_hosts.shift
      end
      debug "allocating host #{@hosts[host][:host]} in HostGroup #{@name}"
      @hosts[host][:used] = true
      @hosts[host][:host]
    }
  end

  # Deallocates a host.
  # @param host [Host] The host to be deallocated.
  def free(host)
    debug "freeing Host #{host.hostname}"
    filter_dead_nodes
    @mutex.synchronize {
      @unused_hosts << host.hostname
      @hosts[host.hostname][:used] = false
    }
    @condition.signal
  end

  private
  def filter_dead_nodes()
    @mutex.synchronize {
      begin
        dead_hosts_new = (@hosts.values.map do |host|
          if host[:host].is_a? SlurmHost then
            host[:host].slurm_host
          end
        end).select do |host|
          !host.nil?
        end.uniq.map do |host|
          host.get_dead_slurm_hostnames
        end.flatten.uniq
      rescue RemoteFailure
      end

      non_dead_hosts = (@dead_hosts - @dead_hosts & dead_hosts_new & @hostnames)
      info "new dead Hosts " +
        (dead_hosts_new.join ", ") unless dead_hosts_new.empty?
      info "Hosts gone back to live" +
        (non_dead_hosts.join ", ") unless non_dead_hosts.empty?
      @unused_hosts += non_dead_hosts
      @dead_hosts = dead_hosts_new
      @unused_hosts.select! { |hostname| !(@dead_hosts.include? hostname) }
    }
  end
end

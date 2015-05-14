require "open3"

require_relative "logged_class"

# This class represents a SSH-controllable host and provides different methods
# to invoke commands remotely.
class Host
  include LoggedClass

  attr_reader :user, :hostname, :port

  # Create a new Host.
  # @param user [String] User to be used for authentication.
  # @param hostname [String] Hostname of the node.
  # @param port [Fixnum] Port that the SSH server listens to on this node.
  def initialize(user, hostname, port = 22)
    @user = user
    @hostname = hostname
    @port = port
  end

  # Runs a command remotely and returns a Hash consisting of the streams
  # associated with the connection.
  # @param command [String] The command to run.
  # @return [Hash{:in,:out,:err,:thread=>IO,Process}] A {Hash} with :in, :out and :err representing the Streams of the connection. :thread gives access to the {Process} object of the SSH process running the command; it can be used to check the return value of the command via the {#value} method.
  def run_with_streams(command)
    debug "Running #{command} per SSH on Host #{@hostname}"
    stdin, stdout, stderr, thread = Open3.popen3(
        "ssh -o \"ForwardAgent true\" #{@user}@#{@hostname} -p #{@port} " +
        "#{Shellwords.escape(command)}")
    { :in => stdin, :out => stdout, :err => stderr, :thread => thread }
  end

  # Runs a command with some optional input.
  # @param command [String] The command to run.
  # @param input [String] Some optional input to the process.
  # @raise [RemoteFailure] if the SSH process returns with a non-zero return value. This could indicate an non-zero return value of the executed command or some connection issue.
  def run(command, input="")
    handles = ssh_run_with_streams(command)
    handles[:in] << input
    handles[:in].close
    output = handles[:out].read
    handles[:out].close
    error = handles[:err].read
    handles[:err].close
    return_value = handles[:thread].value
    raise RemoteFailure.new(error, output, return_value),
      "ssh on host #{hostname} failed" unless return_value.success?
    output
  end

  # Writes a {String} to a file on the remote host.
  # @param string [String] The text to be written.
  # @param filename [String] The path on the remote host.
  # @raise [SCPFailure] If the file transfer is somehow not successful.
  def write_file(string, filename)
    tempfile = Tempfile.new "fodor"
    tempfile.write string + ?\n
    tempfile.close
    copy_file(tempfile.path, filename)
  end

  # Copies a file from the local host to the remote host.
  # @param filename_local [String] The path on the local host.
  # @param filename_remote [String] The path on the remote host.
  # @raise [SCPFailure] If the file transfer is somehow not successful.
  def copy_file(filename_local, filename_remote)
    debug "copying file from #{filename_local} " +
      "to Host #{@hostname} as #{filename_remote}"
    system "scp -P #{port} #{Shellwords.escape(filename_local)} " +
      "#{@user}@#{@hostname}:#{Shellwords.escape(filename_remote)}"
    raise SCPFailure unless $?.success?
  end

  # Copies a file from one remote host to this remote host.
  # @param from_host [String] Host to copy from.
  # @param filename_from_host [String] The path on the host containing the original file.
  # @param filename_to_host [String] The path on the remote host where the copy should be stored.
  # @raise [SCPFailure] If the file transfer is somehow not successful.
  def copy_file_from_host(from_host, filename_from_host, filename_to_host)
    debug "copying file from " +
      "Host #{from_host.hostname}:#{filename_from_host} to " +
      "Host #{@hostname} as #{filename_remote}"
    system "scp -P #{@port} #{from_host.user}@#{from_host.hostname}:" +
      "#{Shellwords.escape(filename_from_host)} " +
      "#{@user}@#{@hostname}:#{Shellwords.escape(filename_to_host)}"
    raise SCPFailure unless $?.success?
  end

  # Gets the contents of a file on the remote host.
  # @param filename [String] The filename of the file on the remote host to be read.
  # @return [String]
  def get_file_contents(filename)
    ssh_run "cat #{filename}"
  end

  # If this is a slurm control host, get a list of all dead or used slurm nodes.
  # @return [Array<String>]
  def get_dead_slurm_hostnames()
    # (run 'sinfo -dho "%n"').split
    (run 'sinfo -t unk,down,allocated,error,mixed,future,drain,drained,' +
         'draining,no_respond,completing,power_down,fail,maint -ho "%n"').split
  end

  def to_s
    "Host #{hostname}"
  end

  alias ssh_run_with_streams run_with_streams
  alias ssh_run run
end

# The Error will be raised if a SSH invocation returns with a non-zero return
# value.
class RemoteFailure < StandardError
  # FIXME the attribute documentation dosen't work.

  # @!attribute [r] err_output
  #   The output of the programm on standard error.
  #   @return [String]

  # @!attribute [r] std_output
  #   The output of the programm on standard out.
  #   @return [String]

  # @!attribute [r] return_value
  #   The return value of the programm.
  #   @return [Process::Status]
  attr_reader :err_output, :std_output, :return_value

  # @param err_output [String] The output of the programm on standard error.
  # @param std_output [String] The output of the programm on standard out.
  # @param return_value [Process::Status] The return value of the programm.
  def initialize(err_output, std_output, return_value)
    @err_output, @std_output = err_output, std_output
    @return_value =  return_value
  end
end

# The Error will be raised if a SCP invocation returns with a non-zero return
# value.
class SCPFailure < StandardError
end

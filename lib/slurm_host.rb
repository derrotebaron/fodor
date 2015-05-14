require "stringio"

require_relative 'host'

# This class represents a Slurm-controllable host.
class SlurmHost < Host
  attr_reader :slurm_host

  # Create a new SlurmHost. Optionally it can also be used as a SSH host.
  # @param user [String] User to be used for authentication.
  # @param hostname [String] Hostname of the node.
  # @param slurm_host [Host] Host object of the Slurm control host.
  # @param port [Fixnum] Port that the SSH server listens to on this node. This is only useful if you intend to use this a ssh-controllable host too. If you want to dispatch commands via SSH use the {#ssh_run} and {#ssh_run_with_streams}.
  def initialize(user, hostname, slurm_host, partition, port = 22)
    super(user, hostname, port)
    @slurm_host = slurm_host
    @partition = partition
  end

  # @deprecated This command is useless with SlurmHosts, since they don't have input or output streams.
  def run_with_streams(command)
    info "running #{command} on #{hostname} via Slurm"

    # build a script
    script = ""
    script << "#!/bin/bash\n"
    script << "#SBATCH -w #{@hostname}\n"
    script << command + ?\n

    # run it!
    output = @slurm_host.ssh_run "sbatch -p #{@partition}", script

    { :thread => nil,
      :out => StringIO.new(output),
      :err => StringIO.new(""),
      :in => nil }
  end

  # Runs a command with some optional input.
  # @param command [String] The command to run.
  # @param input [String] Some optional input to the process.
  # @raise [RemoteFailure] if the SSH process returns with a non-zero return value. This could indicate an non-zero return value of the executed command or some connection issue.
  def run(command, input="")
    command_with_input = "echo #{Shellwords.escape(input)} | (#{command})"
    handles = slurm_run_with_streams command_with_input

    output = handles[:out].read
    id = output.scan(/Submitted batch job (\d+)/)[0][0]

    wait_for_job id

    get_output id
  end

  alias slurm_run_with_streams run_with_streams
  alias slurm_run run

  private

  def wait_for_job(id)
    until (@slurm_host.ssh_run "squeue -hj #{id}").empty? do
      sleep $SLURM_POLL_DELAY
    end
  end

  def get_output(id)
    @slurm_host.get_file_contents "slurm-#{id}.out"
  end

  def to_s
    "SlurmHost #{hostname}"
  end
end

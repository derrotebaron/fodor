require_relative "job"
require_relative "host"

# This class represents a {Job} that will be executed remotely.
class RemoteJob < Job
  # Creates a new remote job.
  # @param description [String] Textual description of the job. This is used for logging and debugging purposes.
  # @param job_group [String] Job group of the job. For an explanation see the Documentation of the {JobManager} class.
  # @param host_group [String] Name of the host group on which the job is allowd to run. For more on this see the documentation of the {HostGroup} class.
  # @param result_transformer [Proc] Function that will be applied to the result.
  def initialize(description, job_group, host_group,
                 command, result_transformer)
    super description, job_group, host_group, result_transformer
    @command = command
  end

  # @private
  def run_on_host(host, job_result)
    begin
      job_result.complete!(host.run @command)
    rescue RemoteFailure => e
      job_result.fail!(e)
    end
  end
end

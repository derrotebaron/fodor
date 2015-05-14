require_relative "job"

# This class represents a job that will be run locally.
class LocalJob < Job
  # Creates a new local job.
  # @param description [String] Textual description of the job. This is used for logging and debugging purposes.
  # @param job_group [String] Job group of the job. For an explanation see the Documentation of the {JobManager} class.
  # @param code [Proc] A proc containing the code to be executed in this job.
  # @param result_transformer [Proc] Function that will be applied to the result.
  def initialize(description, job_group, code, result_transformer = nil)
    super description, job_group, :local, result_transformer
    @code = code
  end

  # @private
  def run_local(job_result)
    thread = Thread.new {
      job_result.complete! @code[]
    }
    job_result
  end
end

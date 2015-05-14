require_relative "job"

# A {MetaJob} is used to model the parallel and sequential execution of {Job}s.
# This just supports the parallel execution of sequentially executed arrays of
# {Job}s.
#
# The {Job}s are given as an array of arrays. The inner arrays are executed
# sequentially, while the {Job}s in different arrays are executed in parallel.
#
# Example: +\[ \[ job1, job2 \], \[ job3, job4 \] \]+; +job1+ is always executed
# before +job2+, +job3+ is always executed before +job4+, +job1+ and +job2+ can
# be in parallel to +job3+ and +job4+.
#
# This datastructure must be provided in the Constructur as the 3rd
# (dependent_jobs) argument.
#
# Arbitrary dependency DAGs are not (yet?) supported.
class MetaJob < Job
  # Creates a new meta job.
  # @param description [String] Textual description of the job. This is used for logging and debugging purposes.
  # @param job_group [String] Job group of the job. For an explanation see the Documentation of the {JobManager} class.
  # @param dependent_jobs [Array<Array<Job>>] The jobs that this MetaJob consists of. For an explanation of its concept and usage see the documentation of this class {MetaJob}.
  # @param result_transformer [Proc] Function that will be applied to the result.
  def initialize(description, job_group, dependent_jobs, result_transformer = nil)
    super description, job_group, :meta, result_transformer
    @dependent_jobs = dependent_jobs
  end

  # @private
  def run_meta(job_result, job_manager)
    results = []
    @dependent_jobs.length.times { results << [] }
    threads = []


    @dependent_jobs.each_with_index do |sequential_jobs, index|
      threads << Thread.new(index) do |idx|
        sequential_jobs.each do |job|
          result = job_manager.submit(job)
          results[idx] << result
          result.wait_for_completion
          break if result.failed?
        end
      end
    end

    Thread.new do
      threads.each { |thread| thread.join }
      job_result.complete! results
    end

    job_result
  end
end

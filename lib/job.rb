require_relative "job_result"

# This abstract class captures the common parts of {RemoteJob}, {LocalJob} and {MetaJob}.
# Don't use class directly, since its only purpose is to be a base class for the other job classes.
class Job
  attr_accessor :host_group, :job_group, :description, :meta_information, :result_transformer

  # @deprecated Don't use class directly, since its only purpose is to be a base class for the other job classes.
  def initialize(description, job_group, host_group, result_transformer)
    @description, @job_group, @host_group = description, job_group, host_group
    @meta_information, @result_transformer = {}, result_transformer
  end

  def to_s()
    '"%s" in group %s running on host group %s with %s' %
      [description, job_group, host_group, meta_information.to_s]
  end

  def run_on_host(host, job_result)
    raise NotImplementedError, "this job can't be run on a remote host"
  end

  def run_local(job_result)
    raise NotImplementedError, "this job can't be run locally"
  end

  def run_meta(job_result, job_manager)
    raise NotImplementedError, "this job is not a metajob"
  end
end

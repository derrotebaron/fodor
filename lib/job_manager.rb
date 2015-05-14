require_relative "job"
require_relative "logged_class"

# The class is responsible for running and distibuting job and for providing
# callbacks to monitor progress.
#
# To run a job, just {#submit} the corresponding job object. The result is
# contained in the corresponding {JobResult} object, that is returned by the
# {#submit} method.
#
# To keep track of different phases of an algorithm all jobs are grouped in job
# groups. These are simply referenced by their name, which is just a {String}.
# You can register callbacks for the completion of the jobs of a job group. The
# callbacks are registered via the {#register_callback} method. There is
# currently only one type of event to have a callback for: the completion of a
# job group.
class JobManager
  include LoggedClass

  # Returns a JobManager.
  # @deprecated For most applications, the usage of the global $JOBMANAGER is sufficient.
  # @param host_group_set [HostGroupSet] The HostGroupSet containing the {HostGroup}s, the manager will use.
  def initialize(host_group_set)
    @host_group_set, @job_groups = host_group_set, {}
    @mutex, @condition = Mutex.new, ConditionVariable.new
    @callbacks = { :group_complete => [] }
  end

  # TODO unique names for job groups.

  # Registers a callback for a event.
  #
  # Currently only the :group_complete type is implemented. To specify the group
  # to monitor, one may use the selector parameter. A selector is a RegEx object
  # which will be used to filter the groups that this callback will be triggered
  # on.
  #
  # The callback is just a {Proc} that will be called with the group name and the type as arguments.
  # @param type [Symbol] Type of the callback to be registered. Currently only :group_complete is availiable.
  # @param callback [Proc] The actual callback that will be called, when the event triggers the callback.
  # @param selector [Regexp] Limits the callbacks to groups that match this {Regexp}
  def register_callback(type, callback, selector=nil)
    debug "registering callback for #{type}"
    if type != :group_complete then
      raise ArgumentError,
        "Currently only :group_complete is availiable for callbacks"
    end
    @callbacks[type] << { :selector => selector, :callback => callback }
  end

  # Creates a job group.
  # For the  concept of job groups see the class documentation.
  # @param group_name [String] The name of the job group to be created.
  def init_group(group_name)
    @job_groups[group_name] = { :jobs => [], :finished => false }
  end

  # Executes a job asynchronously.
  # All parameters of the job are part of the job object.
  # @param job [Job] The job to be executed.
  # @return [JobResult] The result of the job. This is kind of a future object
  # and will be returned instatnly. See the documentation of the {JobResult}
  # class.
  def submit(job)
    debug "job submitted: #{job.to_s}"
    host_group = get_host_group(job.host_group)
    job_group = get_job_group(job.job_group)

    job_result = JobResult.new job.result_transformer

    Thread.new {
      case host_group
      when :local, :meta
        host = host_group
      when HostGroup
        host = host_group.allocate
      end

      job_struct = { :host => host, :job_result => job_result,
                     :job => job, :done => false }
      job_group[:jobs] << job_struct

      run_job job, host, job_result

      # wait for jobs to wakeup waiting threads and free the host
      job_result.wait_for_completion

      host_group.free(host) unless host == :local || host == :meta

      @mutex.synchronize {
        job_struct[:done] = true
      }
      @condition.broadcast
    }

    job_result
  end

  # Blocks until all jobs for a certain group are completed.
  #
  # If the job group was already completed at the time of invocation of
  # this method, it returns instantly.
  # @param group_name [String] Name of the job group to be waited for.
  def wait_for_group(group_name)
    group = get_job_group(group_name)

    @mutex.synchronize {
      loop {
        return if group[:finished] && group[:jobs].all? do |job|
          job[:done]
        end
        @condition.wait(@mutex)
      }
    }
  end

  # Blocks until all jobs for all currently known groups are completed.
  # If all job groups were already completed at the time of invocation of this
  # method, it returns instantly.
  def wait_for_all_groups()
    job_groups.each do |group|
      wait_for_group group
    end
  end

  # Gets the names of all job groups.
  # @return [Array<String>] An array of names of all job groups, in no paticular order.
  def job_groups()
    @job_queues.keys.dup
  end

  # Declares a job group complete.
  # The usage of this method has three effects:
  # 1. The resources used to track the groups are freed, if this is not used the
  # programm might leak memory.
  # 2. The threads currently blocked in a {#wait_for_group} method for this
  # group (and also the {#wait_for_all_groups} method) will be unblocked.
  # 3. If all jobs in this group are completed :group_complete callbacks for
  # this group will be issued.
  # @param group [String] Name of the job group to be marked complete.
  def finish_group(group)
    job_group = get_job_group(group)

    @mutex.synchronize {
      job_group[:finished] = true
    }
    @condition.broadcast

    Thread.new {
      wait_for_group(group)
      debug "finished job group #{group}"
      callback :group_complete, group
    }
  end

  private
  def get_job_group(group_name)
    group = @job_groups[group_name]
    raise ArgumentError,
      "Job group \"#{group_name}\" dosen't exist" if group.nil?
    group
  end

  def get_host_group(group_name)
    case group_name
    when :local, :meta
      group = group_name
    when String
      group = @host_group_set[group_name]
    end
    raise ArgumentError,
      "Host group \"#{group_name}\" dosen't exist" if group.nil?
    group
  end

  def run_job(job, host, job_result)
    info "running job #{job.to_s} on host #{host}"
    case host
    when Host
      job.run_on_host host, job_result
    when :local
      job.run_local job_result
    when :meta
      job.run_meta job_result, self
    end
  end

  def callback(type, identifier)
    @callbacks[type].each do |callback_hash|
      if callback_hash[:selector].nil? ||
          callback_hash[:selector] =~ identifier then
        callback_hash[:callback][type, identifier]
      end
    end
  end
end

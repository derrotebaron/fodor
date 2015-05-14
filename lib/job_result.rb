require 'thread'

# This class is basically an implementation of a future. It is intended to be
# used for the result of jobs.
#
# The api for the "provider" of the result consists of {#complete!} and
# {#fail!}. They are to be called with the result or the {Exception}
# respectivly.
#
# From the perspective of the "recipient" there are {#completed?} and
# {#failed?}, which indicate that a result is available by returning {true} (and
# false if not) and for {#failed?}, that the job ended with a failure
# additionally. For the retrival of the result there are two methods. The
# {#result} method returns the result if it is already availaible or raises an
# {ThreadError} otherwise. The {#wait_for_completion} method always returns the
# result, if it's not available, then it blocks if until the completion of the
# job.
#
# After the result becomes availiable it will be transformed by a function ifr
# such a function is given in the {#initialize constructor}. If there is no such
# function an optional block to the {#complete!} method will transform the
# result.
#
# Otherwise the results will be unaltered. The unaltered version of the result
# is always the second return value for all methods that return the result.
class JobResult
  def initialize(result_transformer = nil)
    @completed = false
    @failed = false
    @mutex = Mutex.new
    @condition = ConditionVariable.new
    @result_transformer = result_transformer
  end

  # Returns the result if already availiable or blocks until the result is made
  # availiable through {#complete!} or {#fail!} and then returns it.
  # @return [Object] the transformed result.
  # @return [Object] the raw result.
  def wait_for_completion()
    @mutex.synchronize {
      return @result, @raw_result if completed?
      @condition.wait(@mutex)
    }
    return @result, @raw_result
  end

  # Returns {true} if the result is availiable.
  # @return [Bool]
  def completed?()
    @completed
  end

  # Returns {true} if the result is availiable and the operation failed.
  # @return [Bool]
  def failed?()
    @completed and @failed
  end

  # Returns the result if already availiable or raises an {ThreadError}
  # otherwise.
  # @raise [ThreadError] if the result is not yet availiable.
  # @return [Object] the transformed result.
  # @return [Object] the raw result.
  def result()
    raise ThreadError, "Not yet completed" if !completed?
    return @result, @raw_result
  end

  # Complete the operation successfully. If no result transformer was given to
  # the {#initialize constructor} transforms the result with the optional block.
  # @yield the result.
  # @yieldreturn the transformed result.
  # @param result_object [Object] Object representing the result of the job.
  def complete!(result_object)
    @mutex.synchronize {
      @raw_result = result_object
      unless @result_transformer.nil?
        @result = @result_transformer[@raw_result]
      else
        @result = block_given? ? yield : @raw_result
      end
      @completed = true
      @failed = false
      @condition.broadcast
    }
  end

  # Complete the operation unsuccessfully.
  # @param error [Exception] Exception representing the reason of the failure.
  def fail!(error)
    @mutex.synchronize {
      @raw_result = error
      @result = error
      @completed = true
      @failed = true
      @condition.broadcast
    }
  end

  # @private
  def load(completed, failed, result, raw_result)
    @completed, @failed = completed, failed
    @result, @raw_result = result, raw_result
    self
  end

  # @private
  def _dump(depth)
    Marshal.dump [@completed, @failed, @result, @raw_result]
  end

  # @private
  def JobResult._load(str)
    JobResult.new.load(*(Marshal.restore str))
  end
end

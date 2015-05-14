require_relative "evaluator"

# This is a simple evaluator for debugging.
# It generates an array of the values of flags and adds the indices of all flags
# that are boolean and true and puts them in the formula exp(sqrt(x)).
class DummyEvaluator < Evaluator
  # @private
  def initialize()
    super "", # algo_name
      "", "", # folder_{compile,eval}
      "", "", # build_cmdline_{compile,eval}
      {}, "", "", # versions, standard_flags, storage
      "", "" # host_group_{compile,eval}
  end
  
  # @private
  def [](flags_array)
    if $DUMMY_COUNTER == nil then
      $DUMMY_COUNTER = 0
    end
    $DUMMY_COUNTER += 1
    group = "dummygroup-#{$DUMMY_COUNTER}"
    $JOBMANAGER.init_group group
    job = LocalJob.new "dummy job", group, lambda {}
    $JOBMANAGER.submit job
    $JOBMANAGER.finish_group group

    flags_array.map do |flags|
      flags.to_a.values.each_with_index.map do |value, index|
        value ? Math.exp(Math.sqrt(index)) : 0
      end.reduce(:+)
    end
  end
end

require_relative "job_factory"

# Instances of this class are used build a programm and to evalutate the
# performance of it.
#
# It is designed to issue two successive {RemoteJob}s via a {MetaJob}; one being
# the compilation job and the other to be the evaluation job. It internally also
# caches the results of the jobs. This cache can be saved to a file via the
# {#save_cache} method and be loaded again with the {#load_cache} method.
#
# For a example of its usage please refer to the source code of the
# {EvaluatorFactory} module.
#
# The version attribute that has to be passed to the constructor is used to
# distinguish results gathered with different versions of the compiler or the
# programm under test. Technically any marshallable {Object} can be used for
# that matter, but it is best practice to use a {Hash} mapping from a {String}
# naming the used tool/project under test to {String}s representing the versions
# used. Additionally the host_group_eval will also be used to distinguish
# different tests, since different hardware means different results.
#
# From the viewpoint of an Optimizer usage looks like this: If the algorithm has
# different phases that use an {Evaluator}, it changes the phase attribute to
# match the phase it is currently in. For every iteration the optimizer calls
# the {#step} method to increase an internal counter in the Evaluator. This all
# is used to give the jobs meaningful group names. This helps with debugging and
# lead to more useful logging output. If the {Optimizer} wants to evaluate a
# certain genotype it can do this by calling the {#[]} method of the evaluator
# with an array of genotypes it wants to evaluate; It will return an {Array} of
# {JobResults}.
#
# Each Evaluator is also associated with a string called standard_flags. It will
# be given to the functions that generate the command lines for the compilation
# and the evaluation. Its purpose is to factor out flags that will be constant
# within a optimization run but not constant on all runs. For example one might
# compile with -march=native always switched on on a set of tests, but chooses
# to drop that flag on others; In this instance it is benificial to have this
# factored out of the commandline generation functions.
#
# The jobs have the capability to transform the result automatically into a
# object that the fitness function can deal with. These transformers have to be
# stated in the {#initialize constructor}.
class Evaluator
  # @!attribute [r] phase
  # The phase the algorithm is currently in.
  # This is used for the name of the jobs. Intially it is set to "".
  # @return [String]
  attr_accessor :phase

  # Creates a new {Evaluator}
  # @param algo_name [String] Name of the algorithm. This is used for the generation of the name of the jobs.
  # @param folder_compile [String] Initial working directory of the compile commandline.
  # @param folder_eval [String] Initial working directory of the evaluation commandline.
  # @param build_cmdline_compile [Proc] Function to build build the command line for the compilation job. Takes the flags as first argument and standard_flags as second argument.
  # @param build_cmdline_eval [Proc] Function to build build the command line for the evaluation job. Takes the flags as first argument and standard_flags as second argument.
  # @param versions [Object] For this parameter see the explaination in the {Evaluator class description}.
  # @param standard_flags [String] For this parameter see the explaination in the {Evaluator class description}.
  # @param storage [String] SCP-Target string that represents a transport storage between compile and eval host.
  # @param host_group_compile [String] The host group for the compilation jobs.
  # @param host_group_eval [String] The host group for the evaluation jobs.
  # @param compile_result_transformator [Proc] Function to be performed on the result of the compilation. See the explaination in the {Evaluator class description} and the documentation of the {Job} class.
  # @param eval_result_transformator [Proc] Function to be performed on the result of the evaluation. See the explaination in the {Evaluator class description} and the documentation of the {Job} class.
  # @param meta_result_transformator [Proc] Function to be performed on the result of the MetaJob. See the explaination in the {Evaluator class description} and the documentation of {Job} class.
  def initialize(algo_name, folder_compile, folder_eval,
                 build_cmdline_compile, build_cmdline_eval,
                 versions, standard_flags, storage,
                 host_group_compile, host_group_eval,
                 compile_result_transformator = nil,
                 eval_result_transformator = nil,
                 meta_result_transformator = nil)
    @steps, @phase, @algo = 0, "", algo_name
    @cmdline_compile, @cmdline_eval = build_cmdline_compile, build_cmdline_eval
    @folder_compile, @folder_eval = folder_compile, folder_eval
    @storage = storage
    @host_group_compile, @host_group_eval = host_group_compile, host_group_eval
    @versions, @standard_flags = versions.dup, standard_flags.dup
    @cache = {}
    @compile_result_transformator = compile_result_transformator
    @eval_result_transformator = eval_result_transformator
    @meta_result_transformator = meta_result_transformator
    # TODO Maybe add different standard_flags for compile and eval.
#
  end

  # Saves the cache to a file.
  # @param filename [String] Name of the file to write to.
  def save_cache(filename)
    open(filename, "w") { |file| file.write (Marshaler.dump @cache) }
  end

  # Load the cache from a file.
  # @param filename [String] Name of the file to read from.
  def load_cache(filename)
    open(filename, "r") { |file| @cache = Marshaler.dump file.read }
  end

  # Increments the internal step counter used for the naming the jobs.
  def step()
    @steps += 1
  end

  # Evaluates genotypes.
  # Generates jobs according to the parameters used in the
  # {#initialize constructor}.
  # @param flags_array [Array<FlagSet>] Array of {FlagSet}s to be evaluated.
  # @return [Array<JobResult>]
  def [](flags_array)
    job_group_meta, job_group_compile, job_group_eval =
      "meta_#{@algo}_#{@phase}_#{@steps}",
      "compile_#{@algo}_#{@phase}_#{@steps}",
      "eval_#{@algo}_#{@phase}_#{@steps}"
    job_groups = [job_group_meta, job_group_compile, job_group_eval]

    job_groups.each { |group| $JOBMANAGER.init_group(group) }

    cached, uncached = *(flags_array.partition do |flags|
      @cache.has_key? build_key(flags)
    end)

    unless uncached.empty?
      cmdlines_compile = (([@cmdline_compile] * uncached.length).zip(uncached))
      cmdlines_compile.map! do |(func, flags)|
        func[flags.to_s, @standard_flags, @storage]
      end
      
      cmdlines_eval = (([@cmdline_eval] * uncached.length).zip(uncached))
      cmdlines_eval.map! do |(func, flags)|
        func[flags.to_s, @standard_flags, @storage]
      end

      job = JobFactory.generate_remote_compile_and_eval_job(
        job_group_meta, job_group_compile, job_group_eval,
        @host_group_compile, @host_group_eval,
        @folder_compile, @folder_eval,
        cmdlines_compile, cmdlines_eval,
        @compile_result_transformator,
        @eval_result_transformator,
        @meta_result_transformator)

      result = $JOBMANAGER.submit(job)

      result.wait_for_completion

      result_map = (uncached.map { |flags| build_key flags })
      result_map.zip(result.result[0]) do |key, val|
        @cache[key] = val
      end
    end

    job_groups.each do |group|
      $JOBMANAGER.finish_group(group)
    end

    flags_array.map do |flags|
      @cache[build_key(flags)]
    end
  end

  private
  def build_key(flags)
      [flags.to_s, @host_group_eval, @versions]
  end
end

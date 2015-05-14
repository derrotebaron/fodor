require_relative "optimizer"

# This class is an adapter for generation based optimiztion algorithms.
# The user has to specify 3 functions to implement different algorithms:
# 1. The termination criterion, this function recives the number of steps and
# the results array. The results array is an array of arrays which contains the
# results of all past steps. The format is like this:
#   [
#     # Generation 1
#     [ 
#       # Generation 1 Candidate 1
#       [
#         # Generation 1 Candidate 1 Genotype
#         flagstate_candidate1,
#         # Generation 1 Candidate 1 Result
#         job_result1
#       ],
#       # Generation 1 Candidate 2
#       ...
#     ],
#     # Generation 2
#     [
#       ...
#     ]
#     ...
#   ]
# The termination criterion decides if the algorithm shoud stop by returning
# true.
#
# 2. The init function and the mutate function. Both recive the same arguments:
# the current genotypes (the init gets only an empty array), the results as
# described above (init gets an empty array again), a random generator, the
# mutation state. The mutation state is an object that gets passed to the init
# and mutate function and can be used to store state that is used across
# generations.
#
# The return values of the init and mutate function are the genotypes of the
# next generation and the modified mutation_state (this may be a new object, if
# necessary).
#
# Refer to the code of the {OptimizerFactory} module for examples.
class MutationSearch < Optimizer
  # Returns a new generation based Optimizer.
  # @param name [String] Name of the Algorithm.
  # @param seed [Fixnum] The seed for the random generator.
  # @param evaluator [Evaluator] The Evaluator to use.
  # @param init [Proc] The init function.
  # @param mutate [Proc] The mutate function.
  # @param termination_criterion [Proc] The termination criterion.
  # @param flag_set [FlagSet] The flag set to use.
  # @param load_state_filename [String] The name of a file to load the state from.
  def initialize(name, seed, evaluator, init, mutate,
                 termination_criterion, load_state_filename = nil)
    super name, seed, evaluator, load_state_filename
    @init, @mutate, @termination_criterion = init, mutate, termination_criterion
    @genotypes = []
  end

  # @private
  def step()
    # At first initialize the flags
    if @steps.zero? then
      @genotypes, @mutation_state = @init[@genotypes, @results,
                                          @random, @mutation_state]
    end

    # evaluate genotypes
    @results << (@evaluator[@genotypes].zip (@genotypes.map do |genotype|
      genotype.dup
    end))

    # increment step-counter
    @steps += 1
    @evaluator.step

    raise OptimizerCompleteSignal if @termination_criterion[@steps, @results]

    @genotypes, @mutation_state = @mutate[@genotypes, @results,
                                          @random, @mutation_state]
  end

  # @private
  def save_state(filename)
    File.open(filename, "w") do |file|
      file.write (Marshal.dump [:mutation_search, @steps, @results,
                                @genotypes, @mutation_state, @random])
    end
  end

  # @private
  def load_state(filename)
    File.open(filename, "r") do |file|
      _, @steps, @results, @genotypes,
        @mutation_state, @random = Marshal.restore file.read
    end
  end
end

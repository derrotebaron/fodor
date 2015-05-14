require_relative "optimizer_utils"
require_relative "mutation_search"
require_relative "genetic_optimizer"

# This module provides functions to generate {Optimizer}s and termination
# criterions.
#
# For an overview and description of the availiable algorithms see the
# {file:docs/algorithms.md algorithms documentation}
module OptimizerFactory
  include LoggedClass

  # Generates a new random search optimizer
  # @param evaluator [Evaluator] The evaluator to use.
  # @param parallel_evaluations [Fixnum] The number of candidates to evaluate in parallel.
  # @param termination_criterion [Proc] The termination criterion to use.
  # @param seed [Fixnum] The seed for the random generator.
  # @param flag_set [FlagSet] The flag set to optimize.
  # @return [MutationSearch]
  def OptimizerFactory.generate_random_search(evaluator, parallel_evaluations,
                                              termination_criterion,
                                              seed, flag_set)
    mutate = OptimizerUtils.get_init_mutate
    init = OptimizerUtils.get_init mutate, parallel_evaluations, flag_set

    MutationSearch.new "Random Search", seed, evaluator, init, mutate,
      termination_criterion
  end

  # Generates a new random walk optimizer
  # @param evaluator [Evaluator] The evaluator to use.
  # @param parallel_evaluations [Fixnum] The number of candidates around the best candidate of the last round to consider.
  # @param termination_criterion [Proc] The termination criterion to use.
  # @param seed [Fixnum] The seed for the random generator.
  # @param flag_set [FlagSet] The flag set to optimize.
  # @return [MutationSearch]
  def OptimizerFactory.generate_local_search(evaluator, parallel_evaluations,
                                             termination_criterion,
                                             seed, flag_set, distance)
    init = OptimizerUtils.get_init OptimizerUtils.get_init_mutate,
      parallel_evaluations, flag_set

    mutate = lambda do |genotypes, results, random, mutation_state|
      # Determine current element
      best = results.last.min_by(&OptimizerUtils.method(:fitness))


      puts "LocalSearch: best #{best.last.show_binstring} " +
        "#{OptimizerUtils.fitness(best)}"

      # Generate all other elements
      genotypes = parallel_evaluations.times.map do
        genotype = best.last.dup
        (0...flag_set.size).to_a.shuffle(random: random).take(distance).map do |idx|
          genotype = OptimizerUtils.flip_component idx, genotype
        end
        genotype
      end

      return genotypes, mutation_state
    end

    MutationSearch.new "Local Search", seed, evaluator, init, mutate,
      termination_criterion
  end

  # Generates a new random walk optimizer
  # @param evaluator [Evaluator] The evaluator to use.
  # @param parallel_evaluations [Fixnum] The number of candidates around the best candidate of the last round to consider.
  # @param termination_criterion [Proc] The termination criterion to use.
  # @param seed [Fixnum] The seed for the random generator.
  # @param flag_set [FlagSet] The flag set to optimize.
  # @return [MutationSearch]
  def OptimizerFactory.generate_hillclimber(evaluator, parallel_evaluations,
                                            termination_criterion,
                                            seed, flag_set)
    raise ArgumentError if parallel_evaluations % 2 != 0

    init_mutate = lambda do |genotypes, results, random, mutation_state|
      genotypes.map! do |genotype|
        genotype.alter_each do |flag|
          flag[:flag].pick(random)
        end
      end
      genotypes = genotypes.each_with_index.map do |genotype, idx|
        idx.even? ? genotype :
          OptimizerUtils.flip_component(0, genotypes[idx - 1])
      end
      return genotypes, 1
    end

    mutate = lambda do |genotypes, results, random, mutation_state|
      mutation_state = 0 if mutation_state >= genotypes[0].size
      (0...(genotypes.size)).step(2) do |idx|
        this_idx, other_idx = idx, idx + 1

        last_elem_this = results.last[this_idx]
        last_elem_other = results.last[other_idx]

        last_elems = [last_elem_this, last_elem_other]
        last_elems = last_elems.map(&OptimizerUtils.method(:fitness)).
          zip(last_elems)

        best_last = last_elems.min_by(&:first).last.last
        genotypes[this_idx] = best_last.dup
        genotypes[other_idx] = OptimizerUtils.flip_component(mutation_state,
                                                             best_last).dup
        puts "Hillclimber #{last_elem_this.last.show_binstring} => " +
          "#{OptimizerUtils.fitness(last_elem_this)}\n" +
          "#{last_elem_other.last.show_binstring} => " +
          "#{OptimizerUtils.fitness(last_elem_other)}\n======="
      end
      return genotypes, mutation_state + 1
    end

    init = OptimizerUtils.get_init init_mutate, parallel_evaluations, flag_set

    MutationSearch.new "Hillclimber", seed, evaluator, init, mutate,
      termination_criterion
  end


  # Generates a new genetic optimizer.
  # @param evaluator [Evaluator] The evaluator to use.
  # @param selection_method [String] The selection method. This is either "truncate" for a truncating selection or "proportionate" for a proportionate selection.
  # @param termination_criterion [Proc] The termination criterion to use.
  # @param seed [Fixnum] The seed for the random generator.
  # @param flag_set [FlagSet] The flag set to optimize.
  # For the other parameters see the documentation of the {GeneticOptimizer} class.
  # @return [GeneticOptimizer]
  def OptimizerFactory.generate_genetic_optimizer(evaluator, population_size,
                                                  selection_method, crossovers,
                                                  crossover_probability,
                                                  mutations,
                                                  mutation_probability,
                                                  termination_criterion,
                                                  seed, flag_set)
    select = case selection_method
    when "truncate"
      OptimizerUtils.get_truncation_select population_size
    when "proportionate"
      OptimizerUtils.get_proportionate_select population_size
    end

    GeneticOptimizer.new "Genetic Algorithm", seed, evaluator, population_size,
      select,
      crossovers, crossover_probability,
      mutations, mutation_probability,
      termination_criterion, flag_set
  end

  # Create a termination criterion that only considers a maximum number of steps.
  # @param max_steps [Fixnum] The maximum number of steps after which the algorithm has to terminate.
  # @return [Proc]
  def OptimizerFactory.generate_steps_criterion(max_steps)
    lambda do |steps, results|
      steps >= max_steps
    end
  end

  # Create a termination criterion that will never terminate the optimizer.
  # @return [Proc]
  def OptimizerFactory.generate_no_stop_criterion()
    lambda do |steps, results|
      false
    end
  end
end

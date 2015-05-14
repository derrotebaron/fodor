require_relative "flag_state"

# This module provides utility functions for creating Optimizers.
module OptimizerUtils
  # Changes a single component of a {FlagState}
  # @param component [Fixnum] The index of the component to change.
  # @param genotype [FlagState] The {FlagState} to alter.
  # @return [FlagState] The altered {FlagState}.
  def OptimizerUtils.flip_component(component, genotype)
    domain = genotype[component][:flag].domain
    current_value = genotype[component][:value]
    case domain
    when Array
      value = current_value
      while value == current_value
        value = domain.sample(random)
      end
    when :boolean, :boolean_no
      value = !current_value
    when Range
      value = current_value
      while value == current_value
        value = random.rand(domain)
      end
    end
    genotype = genotype.dup
    genotype[component] = value
    genotype
  end

  # Get the fitness value of an entry of the results array.
  # @param genotype [Array] An entry of the results array.
  def OptimizerUtils.fitness(genotype)
    result = genotype[0]

    case result
    when Numeric
      result
    when Array
      eval_value = result[1]
      if eval_value.nil?
        Float::INFINITY
      else
        eval_value[0]
      end
    end
  end

  # Returns a mutation function suitable for the {OptimizerUtils.get_init}
  # function.
  # It simply picks random values for the flags.
  # @return [Proc]
  def OptimizerUtils.get_init_mutate()
    lambda do |genotypes, results, random, mutation_state|
      genotypes.map! do |genotype|
        genotype.alter_each do
          |flag| flag[:flag].pick(random)
        end
      end
      return genotypes, mutation_state
    end
  end

  # Returns a intitialization function.
  #
  # This initialization function creates a number of "empty" {FlagState}s and
  # mutates them with a given function. This mutation function should expect the
  # same parameters as the mutation function for a {MutationSearch}. If you are
  # unsure about what to use here, simply create a mutation function with
  # {OptimizerUtils.get_init_mutate}.
  # @param mutate [Proc] The mutation function to initalize the states.
  # @param parallel_evaluations [Fixnum] The number of states to create.
  # @param flag_set [FlagSet] The FlagSet to use to create the states.
  # @return [Proc]
  def OptimizerUtils.get_init(mutate, parallel_evaluations, flag_set)
    lambda do |genotypes, results, random, mutation_state|
      genotypes = ([nil] * parallel_evaluations).map do
        flag_state = FlagState.new
        flag_state.add_all flag_set
        flag_state
      end
      genotypes, mutation_state = *mutate[genotypes, results,
                                          random, mutation_state]
      return genotypes, mutation_state
    end
  end

  # Returns a truncating selection function.
  #
  # This selection function simply takes the best candidates and doesn't care
  # about the rest.
  # @param population_size [Fixnum] The number of elements that should be left after selection.
  # @return [Proc]
  def OptimizerUtils.get_truncation_select(population_size)
    lambda do |results, random|
      (results.last.sort do |left, right|
        fitness(left) <=> fitness(right)
      end.take population_size).map(&:last)
    end
  end

  # Returns a proportionate selection function.
  #
  # This selection function selects candidates with a probability proportional
  # to their fitness.
  # @param population_size [Fixnum] The number of elements that should be left after selection.
  # @return [Proc]
  def OptimizerUtils.get_proportionate_select(population_size)
    lambda do |results, random|
      fitness_values = results.last.map(&OptimizerUtils.method(:fitness)).map do |f|
        f = 1. / f;
      end
      genotypes = results.last.map(&:last)

      new_population = []

      population_size.times do
        fitness_sum = fitness_values.reduce(&:+)
        cumulative_fitness = 0
        proportions = []
        fitness_values.each do |fitness|
          proportions << cumulative_fitness / fitness_sum
          cumulative_fitness += fitness
        end
        proportions << 1


        random_number = random.rand
        idx = proportions.index(proportions.bsearch do |x|
          x > random_number
        end) - 1
        new_population << genotypes[idx]
        genotypes.delete_at(idx)
        fitness_values.delete_at(idx)
      end

      new_population
    end
  end
end

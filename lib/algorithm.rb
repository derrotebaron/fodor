require_relative "optimizer_factory"

# This Module provides factory functions for instanciating {Optimizer}s for the
# {OptimizeTask} class.
# If you want to be able to use your {Optimizer} you must modify the
# {Algorithm.for_name} method.
# @note This approach is quite ugly and might be refactored in future versions.
module Algorithm
  # Returns instance of a {Optimizer}.
  # @param algo_name [String] Name of the {Optimizer} to be created.
  # @param algo_values [String] Key value pairs of attributes to be set for the optimization algorithm. Given in the format "key1=value1,key2=value2".
  # @param termination_name [String] Name of an termination criterion to be used with the algorithm.
  # @param termination_value [String] Optional value for the termination criterion.
  # @param flag_set [FlagSet] {FlagSet} to be used in the optimization run
  # @param evaluator [Evaluator] {Evaluator} to be used in the optimization run.
  # @raise [IndexError] if no Optimizer with given name can found.
  # @return [Optimizer]
  def Algorithm.for_name(algo_name, algo_values, termination_name,
                         termination_value, flag_set, evaluator)
    termination_criterion = Algorithm.for_termination_name(termination_name,
                                                           termination_value)
    case algo_name
    when "Random Search"
      values = decode_values algo_values
      OptimizerFactory.
        generate_random_search(evaluator, values["parallel"].to_i,
                               termination_criterion,
                               values["seed"].to_i, flag_set)
    when "Hillclimber"
      values = decode_values algo_values
      OptimizerFactory.
        generate_hillclimber(evaluator, values["parallel"].to_i,
                             termination_criterion,
                             values["seed"].to_i, flag_set)
    when "Genetic Algorithm"
      values = decode_values algo_values
      OptimizerFactory.
        generate_genetic_optimizer(evaluator, values["population_size"].to_i,
                                   values["selection_method"],
                                   values["crossovers"].to_i,
                                   values["crossover_probability"].to_f,
                                   values["mutations"].to_i,
                                   values["mutation_probability"].to_f,
                                   termination_criterion,
                                   values["seed"].to_i, flag_set)
    when "Local Search"
      values = decode_values algo_values
      OptimizerFactory.
        generate_local_search(evaluator, values["parallel"].to_i,
                              termination_criterion,
                              values["seed"].to_i, flag_set,
                              values["distance"].to_i)
    else
      raise IndexError, "No Algorithm with name #{algo_name} found"
    end
  end

  # Returns instance of a termination criterion.
  # @param termination_name [String] Name of the termination criterion.
  # @param termination_value Optional value for the criterion.
  # @return [Lambda]
  def Algorithm.for_termination_name(termination_name, termination_value)
    case termination_name
    when "Steps"
      OptimizerFactory.generate_steps_criterion(termination_value.to_i)
    end
  end

  # Returns a Hash of key-value pairs from a {String} in the format
  # "key1=value1,key2=value2".
  # @param values [String] String containing key-value pairs
  # @return [Hash]
  def Algorithm.decode_values(values)
    Hash[(values.split ",").map { |value| value.split "=" }]
  end
end

module Result
  # Transforms the result into a more useable format.
  #
  # The result to be transformed will be read from the global variable $RESULT.
  #
  # If the csv paramter is set the output is a string containing the result as
  # comma seperated values.
  #
  # The return value of this method depends on the type parameter:
  #
  # * :best :: Returns only the best candidate. If the csv parameter is false the result is structured like { :value => best_value, :candidate => best_candidate }
  # * :min :: Returns an Array containing one Array per Generation with only the minimal value in it. Like [[ min1 ], [ min2 ]]
  # * :max :: Returns an Array containing one Array per Generation with only the maximal value in it. Like [[ max1 ], [ max2 ]]
  # * :average :: Returns an Array containing one Array per Generation with only the avgerage value in it. Like [[ avg1 ], [ avg2 ]]
  # * :median :: Returns an Array containing one Array per Generation with only the median value in it. Like [[ med1 ], [ med2 ]]
  # * :min_max_average_median :: Returns an Array containing one Array per Generation with the minimum, maximum, average and median value in it. Like [[ min1, max1, avg1, med1 ], [ min2, max2, avg2, med2 ]]
  # * :all ::  Returns an Array of Arrays with all values of candidates of a generation. Like [[ val1, val2 ], [ val3, val4 ]]
  # @param type [:min,:max,:average,:median,:min_max_average_median,:all] The type of output requested.
  # @param csv [Boolean] If the result should be a CSV.
  # @returns [Array<Array<Numeric>,Numeric>, Hash, String]
  def Result.get_data(type, csv=false)
    result = beautify_data $RESULT


    if type == :beautify then
      return result
    end

    if type == :best then
      best_value = Float::INFINITY
      best_candidate = nil
      result[:results].each do |generation|
        generation_values = generation.map do |candidate|
          candidate[:result]
        end
        generation_candidates = generation.map do |candidate|
          candidate[:flag_state]
        end
        generation_values.each_with_index do |value, index|
          if value < best_value then
            best_value = value
            best_candidate = generation_candidates[index]
          end
        end
      end
      if csv then
        header = %w{value flags}
        return [header [best_value, best_candidate]]
      else
        return { :value => best_value,
                 :candidate => best_candidate }
      end
    end


    aggreated_results = result[:results].map do |generation|
      generation = generation.map do |candidate|
        candidate[:result]
      end

      min, max = generation.minmax
      average = generation.reduce(&:+) / generation.size
      median = generation.size % 2 == 1 ? generation.sort[generation.size / 2] :
        (generation.sort[generation.size / 2 - 1] +
         generation.sort[generation.size / 2]) / 2

      case type
      when :min_max_average_median
        [min, max, average, median]
      when :min
        [min]
      when :max
        [max]
      when :average
        [average]
      when :median
        [median]
      when :all
        generation
      end
    end

    if csv then
      case type
      when :min_max_average_median
        header = %w{min max average median}
      when :min
        header = %w{min}
      when :max
        header = %w{max}
      when :average
        header = %w{average}
      when :median
        header = %w{median}
      when :all
        header = []
      end

      header = header.join ?\,

      header + ?\n + (aggreated_results.map do |x|
        x.join ?\,
      end.join ?\n)
    else
      aggreated_results
    end
  end

  private
  def Result.beautify_candidate(candidate)
    if candidate[0].is_a? Array then
	  if !candidate[0][1].nil? then
		  result = candidate[0][1][0]
	  else
		  result = 0
	  end
    else
      result = candidate[0]
    end
    { :flag_state => candidate[1],
      :result => result.is_a?(Numeric) ? result : 0 }
  end

  def Result.beautify_generations(generations)
    generations.map do |generation|
      generation.map(&Result.method(:beautify_candidate))
    end
  end

  def Result.beautify_data(data)
    type_tag = data[0]

    case type_tag
    when :mutation_search, :genetic
      { :type => type_tag,
        :steps => data[1],
        :results => beautify_generations(data[2]) }
    end
  end

end

require "rexml/document"

require_relative "logged_class"
require_relative "flag_set"
require_relative "algorithm"
require_relative "evaluator_factory"
require_relative "evaluator_template"

# This class represents the settings and environment of a single optimization
# run.
#
# All variables of an optimization run can be loaded from an file using this
# class.
#
# For a description of the format of this file see the
# {file:docs/formats.md format documentation}
class OptimizeTask
  include LoggedClass

  # @private
  attr_reader :name, :flag_set

  def initialize()
    @flag_set = FlagSet.new
    @excluded_groups = []
  end

  # Reads an optimization task from a file.
  # For the file format see the {file:docs/formats.md format documentation}.
  # @param filename [String] The name of the file to be read from.
  # @see {file:docs/formats.md Format documentation}.
  def read_from_file(filename)
    debug "reading task from file #{filename}"
    doc = REXML::Document.new open(filename)
    doc.elements.each("optimize-task") do |elem|
      @name = elem.attributes["name"]
      @standard_flags = elem.elements["standard-flags"].text
      @standard_flags = "" if @standard_flags.nil?
      @host_group_compile = elem.elements["host-group-compile"].text
      @host_group_eval = elem.elements["host-group-eval"].text
      @folder_compile = elem.elements["folder-compile"].text
      @folder_eval = elem.elements["folder-eval"].text
      @storage = elem.elements["storage"].text

      read_versions_map elem.elements["versions"]

      elem.elements.each("exclude-flag-group") do |group|
        @excluded_groups << group.text
      end

      elem.elements.each("flag-set") do |set|
        add_flag_set($FLAGSETS[set.text])
      end

      algorithm = elem.elements["algorithm"].text
      algorithm_values = elem.elements["algorithm-values"].text
      termination_criterion_type =
        elem.elements["termination-criterion"].attributes["type"]
      termination_criterion_value =
        elem.elements["termination-criterion"].text
      evaluator = elem.elements["evaluator"].text

      read_evaluator evaluator, algorithm

      read_algorithm algorithm, algorithm_values,
        termination_criterion_type, termination_criterion_value
    end
  end

  # Executes the loaded optimization run
  # @param filename [String] The filename of the file that the result should be written to.
  def run(*args)
    @algorithm.run *args
  end

  def load_state(file)
    @algorithm.load_state(file)
  end

  private
  def read_versions_map(elem)
    @versions = {}
    elem.elements.each do |version|
      @versions[version.attributes["of"]] = version.text
    end
  end

  def read_algorithm(algo, values,
                     termination_criterion_type, termination_criterion_value)
    @algorithm = Algorithm.for_name algo, values,
      termination_criterion_type, termination_criterion_value,
      @flag_set, @evaluator
  end

  def read_evaluator(evaluator, algo_name)
    case evaluator
    # when "libgeodecomp"
    #   @evaluator = EvaluatorFactory.generate_libgedecomp_evaluator algo_name, @folder_compile, @folder_eval, @host_group_compile, @host_group_eval, @storage, @versions, @standard_flags
    when "dummy"
      @evaluator = EvaluatorFactory.generate_dummy_evaluator
    when /template:(.+$)/
      et = EvaluatorTemplate.new
      et.read_from_file $1
      @evaluator = et.get_evaluator algo_name, @folder_compile, @folder_eval,
        @host_group_compile, @host_group_eval,
        @storage, @versions, @standard_flags
    end
  end

  def add_flag_set(flag_set)
    @flag_set.merge(flag_set)
    @excluded_groups.each { |group| @flag_set.remove_group(group) }
  end
end

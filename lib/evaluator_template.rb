require_relative "logged_class"
require_relative "evaluator"
require_relative "evaluator_factory"

class EvaluatorTemplate
  include LoggedClass

  # Reads an EvaluatorTemplate from a file. After reading the template from a
  # file you can create instances using {#get_evaluator}.
  # For the file format see the {file:docs/adoption.md adoption documentation}.
  # @param filename [String] The name of the file to be read from.
  # @see {file:docs/adoption.md Adoption documentation}.
  def read_from_file(filename)
    debug "reading Evaluator Template from file #{filename}"
    doc = REXML::Document.new open(filename)

    doc.elements.each("evaluator") do |elem|
      @compile_line, @eval_line = [%w{compile upload},
                                   %w{download run}].map do |names|
        generate_line_lambda_from_tree(elem, *names)
      end

      eval_output_parser = elem.elements["eval-output-parser"] || nil
      compile_output_parser = elem.elements["compile-output-parser"] || nil
      @eval_output_parser = eval_output_parser.nil? ? nil :
        generate_output_parser(eval_output_parser.text)
      @compile_output_parser = compile_output_parser.nil? ? nil :
        generate_output_parser(compile_output_parser.text)
    end
  end

  # Creates an {Evaluator} based on this template.
  # @param algo_name [String] Name of the algorithm. This is used for the generation of the name of the jobs.
  # @param folder_compile [String] Initial working directory of the compile commandline.
  # @param folder_eval [String] Initial working directory of the evaluation commandline.
  # @param versions [Object] For this parameter see the explaination in the {Evaluator class description}.
  # @param standard_flags [String] For this parameter see the explaination in the {Evaluator class description}.
  # @param storage [String] SCP-Target string that represents a transport storage between compile and eval host.
  # @param host_group_compile [String] The host group for the compilation jobs.
  # @param host_group_eval [String] The host group for the evaluation jobs.
  def get_evaluator(algo_name, folder_compile, folder_eval,
                    host_group_compile, host_group_eval,
                    storage, versions, standard_flags)
    result_transformator = lambda do |meta_result|
      meta_result.map! do |result_array|
        result_array.map!(&:wait_for_completion)
      end
    end

    Evaluator.new algo_name, folder_compile, folder_eval,
      @compile_line, @eval_line,
      versions, standard_flags, storage,
      host_group_compile, host_group_eval,
      @compile_output_parser, @eval_output_parser, result_transformator
  end

  private
  def generate_line_lambda_from_tree(tree, *cmdlines)
    generate_line_lambda(cmdlines.map do |line_name|
      read_cmdline(tree.elements[line_name + "-cmdline"])
    end)
  end

  def read_cmdline(elem)
    cmdline = elem.elements["shell"].text.chomp
    vars = elem.elements["vars"].text
    vars = vars.nil? ? [] : vars.split

    var_map = { "hash"           => "EvaluatorFactory.hash_flags(flags, " +
                                    "standard_flags.to_s)",
                "flags"          => "flags",
                "standard-flags" => "standard_flags",
                "storage"        => "storage",
                "storage-path"   => "storage.split(?:)[1]" }

    vars.map! { |var| var_map[var] }

    var_line = "[ " + vars.join(", ") + " ]"

    cmdline = cmdline.sub(/\\/, "\\\\").sub(/'/, "\\'")

    { :line => cmdline, :vars => var_line }
  end

  def generate_line_lambda(cmdlines)
    line_start = "lambda { |flags, standard_flags, storage|"
    line_end = "}"
    code_line = cmdlines.map do |cmdline|
      "(\'#{cmdline[:line]}\' % #{cmdline[:vars]})"
    end.join ?+
    code = line_start + code_line + line_end
    eval code
  end

  def generate_output_parser(code)
    eval code
  end
end

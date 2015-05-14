require_relative "evaluator"
require_relative "dummy_evaluator"
require "digest"

# This module is used to generate evaluator instances.
module EvaluatorFactory
  # Generates a evaluator for the libgeodecomp test.
  # @param algo_name [String] The name of the algorithm to test.
  # @param folder_compile [String] The name of the folder to use for the compilation.
  # @param folder_eval [String] The name of the folder to use for the evaluation.
  # @param host_group_compile [String] The name of the host group to use for the compilation.
  # @param host_group_eval [String] The name of the host group to use for the evaluation.
  # @param storage [String] Names scp-able target path to transfer the compiled programm
  # @param versions [Object] The versions object, for more on this parameter see the expaination in the {Evaluator} class documentation.
  # @param standard_flags [String] The standard arguments for generation of the compilation and evaluation commandline. For more on this parameter see the expaination in the {Evaluator} class documentation.
  def EvaluatorFactory.generate_libgedecomp_evaluator(algo_name,
                                                      folder_compile,
                                                      folder_eval,
                                                      host_group_compile,
                                                      host_group_eval,
                                                      storage, versions,
                                                      standard_flags)
    cmake_cmdline = 'mkdir -p %s ; cd %s ' +
      '&& cp -r /proj/ciptmp/ne32jilo/libgeodecomp/libgeodecomp-0.3.1/. ' +
      '&& cd libgeodecomp-0.3.1 && cd src && ./compile.sh "%s %s" && ' +
      'rm **/*.{cpp,h,cmake,txt,pc}'
    upload_cmdline = "rsync -a .. %s/%s"

    download_cmdline = "cp -r %s/%s/* ."
    run_cmdline = "cd src/; " +
      "LD_LIBRARY_PATH=. testbed/performancetests/performancetests 1234 0"

    compile_line = lambda do |flags, standard_flags|
        folder_name = hash_flags(flags, standard_flags.to_s)
        cmake_cmdline % [folder_name, folder_name, flags.to_s, standard_flags] +
          "&&" + upload_cmdline % [storage, folder_name]
      end

    eval_output_parser = lambda do |string|
      Hash[string.split.map { |x| x.split ";" }.drop(1).map do |fields|
        %w{rev date host device order family species dimensions perf unit}.
          map(&to_sym).zip(fields)
      end].select do |x|
        %w{family species dimensions}.
          zip (["RegionCount", "gold", "(128, 128, 128)"]).map do |y|
          x.first[y] == x.last
        end
      end.first[:perf]
    end

    result_transformator = lambda do |meta_result|
      meta_result.map! do |result_array|
        result_array.map!(&:complete!)
      end
    end

    eval_line = lambda do |flags, standard_flags|
      download_cmdline % [(storage.split ?:)[1],
                          hash_flags(flags, standard_flags)] +
      ?; + run_cmdline
    end

    Evaluator.new algo_name, folder_compile, folder_eval,
      compile_line, eval_line, versions, standard_flags,
      storage, host_group_compile, host_group_eval,
      nil, eval_output_parser, result_transformator
  end


  # Generates a dummy evaluator.
  # @return [DummyEvaluator]
  def EvaluatorFactory.generate_dummy_evaluator()
    DummyEvaluator.new
  end

  private
  def EvaluatorFactory.hash_flags(flags, standard_flags)
    Digest::MD5.hexdigest(flags.to_s + standard_flags.to_s)
  end
end

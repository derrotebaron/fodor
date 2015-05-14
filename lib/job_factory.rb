require_relative "meta_job"
require_relative "local_job"
require_relative "remote_job"

# This Module has convenient functions to instantiate {Job} objects.
module JobFactory
  # @private
  @@mutex = Mutex.new
  # @private
  @@seqnum = 0

  # Generates a {LocalJob} running a command.
  # @param command [String] The command to run.
  # @param job_group [String] The job group of the job.
  # @return [LocalJob]
  def JobFactory.generate_local_command_job(command, job_group)
    LocalJob.new("locally running #{command}", job_group, lambda do
      system command
    end)
  end

  # Generates a {RemoteJob} running a command.
  # @param command [String] The command to run.
  # @param job_group [String] The job group of the job.
  # @param host_group [String] The host group of the job.
  # @return [RemoteJob]
  def JobFactory.generate_remote_command_job(command, job_group, host_group,
                                             result_transformer)
    RemoteJob.new("remotely running #{command}", job_group, host_group,
                  command, result_transformer)
  end

  # Generates a {RemoteJob} that will be run in a randomly named folder within a
  # certain folder.
  #
  # The random folder name is guranteed to be unique for the runtime of the
  # programm, but not across restarts.
  # @param job_group [String] The job group of the job.
  # @param host_group [String] The host group of the job.
  # @param folder [String] The folder on the remote host to contain the randomly named folder that is the working directory of the command.
  # @param cmdline [String] The command to run.
  # @return [RemoteJob]
  def JobFactory.generate_remote_job_in_dir(job_group, host_group, folder,
                                            cmdline, result_transformer,
                                            random_dir = true)
    if random_dir then
      seqnum = 0
      # generate a new name for the output_dir
      @@mutex.synchronize {
        seqnum = @@seqnum
        @@seqnum += 1
      }
      dirname = folder + "/jobdir_" + seqnum.to_s + "_" + Time.new.to_i.to_s
    else
      dirname = folder
    end

    # build command
    command = "mkdir -p %s ; cd %s ; %s" % [dirname, dirname, cmdline]

    generate_remote_command_job command,
      job_group, host_group, result_transformer
  end

  # Generates a meta job containing 2 remote job in series.
  # @param job_group_meta [String] For the {MetaJob}: The job group of the job.
  # @param job_group_compile [String] For the first {RemoteJob}: The job group of the job.
  # @param job_group_eval [String] For the second {RemoteJob}: The job group of the job.
  # @param host_group_compile  [String] For the first {RemoteJob}:  The host group of the job.
  # @param host_group_eval [String] For the second {RemoteJob}: The host group of the job.
  # @param folder_compile  [String] For the first {RemoteJob}: The folder on the remote host to contain the randomly named folder that is the working directory of the command.
  # @param folder_eval [String] For the second {RemoteJob}: The folder on the remote host to contain the randomly named folder that is the working directory of the command.
  # @param cmdline_compile  [String] For the first {RemoteJob}: The command to run.
  # @param cmdline_eval [String] For the second {RemoteJob}: The command to run.
  # @param result_transformer_compile [String] For the first {RemoteJob}: The result transformer to use.
  # @param result_transformer_eval [String] For the second {RemoteJob}: The result transformer to use.
  # @return [RemoteJob]
  def JobFactory.generate_remote_compile_and_eval_job(job_group_meta,
                                                      job_group_compile,
                                                      job_group_eval,
                                                      host_group_compile,
                                                      host_group_eval,
                                                      folder_compile,
                                                      folder_eval,
                                                      cmdlines_compile,
                                                      cmdlines_eval,
                                                      result_transformer_compile,
                                                      result_transformer_eval,
                                                      result_transformer_result)
    compile_jobs = cmdlines_compile.map do |cmdline|
      generate_remote_job_in_dir job_group_compile, host_group_compile,
        folder_compile, cmdline, result_transformer_compile
    end
    eval_jobs = cmdlines_eval.map do |cmdline|
      generate_remote_job_in_dir job_group_eval, host_group_eval,
        folder_eval, cmdline, result_transformer_eval
    end

    MetaJob.new "remote compilation and evaluation job", job_group_meta,
      (compile_jobs.zip eval_jobs), result_transformer_result
  end
end

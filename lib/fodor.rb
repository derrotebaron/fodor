#!/usr/bin/env ruby

require "pry"
require "optparse"

require "log4r/configurator"
include Log4r

require_relative "optimize_task"
require_relative "task_runner"
require_relative "settings"
require_relative "result"

single, output, repl, result, csv, best, continue = nil, nil, false, nil, nil, nil, nil

OptionParser.new do |opts|
  opts.banner = <<-EOT
FODOR (c) 2014 Johannes Knoedtel
Licenced under the Boost Software License Version 1. See the LICENSE file for the full text of the license.
Usage: fodor [--single] <input.xml> [--output <result-file>] [--continue <continuation-file>]
   or: fodor --result <result.fodor>
   or: fodor --csv=<type> <result.fodor>
   or: fodor --get-best <result.fodor>
  EOT

  opts.on("-s", "--single OPTIMIZE_TASK", "Run a single OptimizeTask") do |file|
    single = file
  end

  opts.on("-o", "--output OPTIMIZE_TASK", "Output of the single OptimizeTask") do |file|
    output = file
  end

  opts.on("-r", "--repl", "Start a Pry repl in an addtional thread") do |file|
    repl = true
  end

  opts.on("-R", "--result RESULT", "Start a Pry repl and load the given result file") do |file|
    result = file
  end

  opts.on("-c", "--csv TYPE", "Convert a given result file into csv") do |file|
    csv = file
  end

  opts.on("-b", "--get-best RESULT", "Get best Flags for a given result file") do |file|
    best = file
  end

  opts.on("-C", "--continue STATE", "Continue an interrupted single run") do |file|
    continue = file
  end
end.parse!

Configurator.load_xml_file "log4r_config.xml"

Settings.load_settings(result.nil? && csv.nil? && best.nil?)

if !continue.nil? and single.nil? then
  abort "Continue only makes sense in combinaiton with single"
end

if !best.nil? then
  if !ARGV.empty? || !output.nil? || !single.nil? || !result.nil? || !csv.nil?  then
    abort "Other options are useless with best candidate extraction"
  end
end

if !csv.nil? then
  if !output.nil? || !single.nil? || repl then
    abort "Other options are useless with CSV output"
  end

  if ARGV.empty? then
    abort "No result file given"
  end
  if ARGV.size > 1 then
    abort "More than one result file was given."
  end
  result = ARGV[0]

  case csv
  when "min_max_average_median"
    csv = :min_max_average_median
  when "min"
    csv = :min
  when "max"
    csv = :max
  when "average"
    csv = :average
  when "median"
    csv = :median
  when "all"
    csv = :all
  else
    abort "Unknown CSV type #{csv}"
  end
end



if best.nil? && csv.nil? && !result.nil? && (!output.nil? || !single.nil? || repl || !ARGV.empty?) then
  abort "When loading, other options are useless."
end

if best.nil? && csv.nil? && result.nil? && (single.nil? && !output.nil? || !single.nil? && output.nil?) then
  abort "Output is needed with single run but otherwise useless. Aborting."
end

if best.nil? && csv.nil? && result.nil? && (!ARGV.empty? && !single.nil? || single.nil? && ARGV.length > 1) then
  abort "Unknown additional parameter(s) found. Aborting."
end

if best.nil? && csv.nil? && result.nil? && (single.nil? && ARGV.length < 1) then
  abort "No executable tasks found on commandline. Aborting."
end

if result.nil? || !csv.nil? || !best.nil? then
  if csv.nil? && best.nil? then
    thread = Thread.new do
      if single.nil? then
        TaskRunner.read_from_file ARGV[0]
        TaskRunner.run
      else
        ot = OptimizeTask.new
        ot.read_from_file single
        if !continue.nil? then
          ot.load_state continue
        end
        ot.run output
      end
    end

    if repl then
      binding.pry
    end

    Signal.trap("INT") do
      sig = StopSignal.new output
      thread.raise sig
      thread.join
    end

    thread.join
  else
    if !csv.nil? then
      $RESULT = Marshal.restore (File.read result)
      puts Result.get_data(csv, true)
    else
      $RESULT = Marshal.restore (File.read best)
      best_result = Result.get_data(:best)
      puts best_result[:value]
      puts best_result[:candidate]
    end
  end
else
  $RESULT = Marshal.restore (File.read result)
  res = $RESULT = Result.get_data(:beautify)

  binding.pry
end

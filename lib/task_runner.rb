require_relative "optimize_task"

# This module is used to execute multiple optimization runs.
# The user specifies the tasks in a file that will be read with
# {TaskRunner.read_from_file}. The format of these files is documented in the
# {file:docs/formats.md formats documentation}.
module TaskRunner
  # Runs to loaded tasks.
  def self.run()
    self.run_tasks(@runs)
  end

  # Reads the optimization runs from a file and adds them to the set.
  # For the file format see the {file:docs/formats.md format documentation}.
  # @param filename [String] The name of the file to be read from.
  # @see {file:docs/formats.md Format documentation}.
  def self.read_from_file(filename)
    doc = REXML::Document.new open(filename)
    doc.elements.each("runs") do |elem|
      @runs = read_elem elem
    end
  end

  # @!attribute [r] run_threads
  # An {Array} containing the {Thread}s running the optimizations.
  attr_reader :run_threads

  private
  def self.read_elem(elem)
    case elem.name
    when "serial", "runs"
      { :type   => :composite,
        :mode   => :serial,
        :tasks  => elem.elements.map(&self.method(:read_elem)) }
    when "parallel"
      { :type   => :composite,
        :mode   => :parallel,
        :tasks  => elem.elements.map(&self.method(:read_elem)) }
    when "run"
      { :type   => :task,
        :file   => elem.text,
        :result => elem.attributes["output"] }
    end
  end

  def self.run_task(run)
    case run[:type]
    when :composite
      self.run_tasks(run)
    when :task
      ot = OptimizeTask.new
      ot.read_from_file(run[:file])
      ot.run(run[:result])
    end
  end

  def self.run_tasks(runs)
    case runs[:mode]
    when :parallel
      runs[:tasks].map do |task|
        Thread.new do
          self.run_task(task)
        end.join
      end.map(&:join)
    when :serial
      runs[:tasks].each do |task|
        self.run_task(task)
      end
    end
  end
end

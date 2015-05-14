require_relative "optimizer_signals"

# This class encapsulates an optimization algorithm.
#
# An Optimizer must override the {#step}, {#load_state} and {#save_state}
# methods. You should also make instances of this class acessible through the
# {Algorithm} module.
class Optimizer
  include LoggedClass

  attr_reader :results

  # @param name [String] The name of the Optimizer.
  # @param seed [Fixnum] The seed for the {Random}-Generator used by the algorithm.
  # @param load_state_filename [String] The name of a file contain the State of the algorithm that should be loaded before {#run}ning the Optimizer.
  def initialize(name, seed, evaluator, load_state_filename = nil)
    @name, @evaluator = name, evaluator
    load_state load_state_filename unless load_state_filename.nil?
    @results = []
    @random = Random.new seed
    @steps = 0
  end

  # Runs the Optimizer and stores the state in a file.
  #
  # Writing of the state can be implicitly triggered by a subclass by raising a
  # {OptimizerCompleteSignal} from within the {#step} method or explicitly by
  # sending a {StopSignal} to the {Thread} running the {Optimizer}.
  #
  # @param save_state_filename [String] The name of the file the state should be written to.
  def run(save_state_filename)
    current_iteration = nil
    begin
      loop do
        current_iteration = Thread.new(self) { |optimizer| optimizer.step  }
        current_iteration.join
      end
    rescue StopSignal => stop_signal
      if stop_signal.save then
        begin
          current_iteration.join
        rescue OptimizerCompleteSignal
        end
        save_state stop_signal.save_state_filename
      end
    rescue OptimizerCompleteSignal
      save_state save_state_filename
    end

    @results
  end

  # Performs one iteration the optimization algorithm.
  #
  # This method should only be called from within the {#run} method and must be
  # overwritten by any "non-abstract" subclass.
  #
  # If the optimization run is deemed complete by the algorithm one must raise a
  # {OptimizerCompleteSignal} from within this method.
  def step()
    raise NotImplementedError
  end

  # Loads a state from a file and sets the state of this object to it
  #
  # This method should only be called from within the {#run} method and must be
  # overwritten by any "non-abstract" subclass.
  # @param load_state_filename [String] The name of the file the state should ber read from
  def load_state(load_state_filename)
    raise NotImplementedError
  end

  # Saves the state of the Optimizer to a file.
  #
  # This method should only be called from within the {#run} method and must be
  # overwritten by any "non-abstract" subclass.
  # @param save_state_filename [String] The name of the file the state should ber read from
  def save_state(save_state_filename)
    raise NotImplementedError
  end
end

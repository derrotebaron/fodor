# When this Signal is raised in the thread of a Optimizer, the Optimizer will
# complete its current step and then stop.
#
# If a filename is given to the {#initialize constructor} the results will be
# written to this file.
class StopSignal < RuntimeError
  # @private
  attr_reader :save, :save_state_filename

  # @param save_state_filename [String] If this parameter is set, then the state of the algorithm will be saved to a file of this name.
  def initialize(save_state_filename = nil)
    @save = !save_state_filename.nil?
    @save_state_filename = save_state_filename
  end
end

# This Signal is raised by the Optimizer subclass in the step function to
# indicate that the termnation criterion evaluates to true and the iteration
# should be stopped now.
class OptimizerCompleteSignal < RuntimeError
end

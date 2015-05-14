require "log4r"
include Log4r

# To enable convienient logging inside of a class include this module.
#
# You can then use {#debug}, {#info}, {#warn}, {#error} and {#fatal} for
# debugging.
#
# This module builds on log4r. Each class gets a logger and needs to be included
# in the configuration. To generate config lines for all loaded classes, that
# use this module call the {LoggedClass.generate_outputter_config} function.
module LoggedClass
  # @private
  LoggedClasses = []

  # @private
  def self.included(klass)
    LoggedClasses << klass.name
  end

  # Generate an outputter config for Log4r for all loaded classes that are
  # logged.
  # @param outputters [Array<String>] The names of all outputters to be included.
  # @param level [String] The log level.
  # @param trace [Boolean] If traces should be included in the logs.
  def self.generate_outputter_config(outputters, level, trace)
    p outputters
    outputters = outputters.dup.map! do |outputter|
      %q{	<outputter>%s</outputter>} % [outputter]
    end.join ?\n
    LoggedClasses.map do |klass|
      begin_tag =
        %q{<logger name="%s" level="%s" additive="false" trace="%s">} % [klass,
                                                                         level,
                                                                         trace]
      end_tag = "</logger>"
      begin_tag + ?\n + outputters + ?\n + end_tag
    end
  end

  # Log a message on the debug level.
  def debug(*args)
    Logger[self.class.name].debug(*args)
  end

  # Log a message on the info level.
  def info(*args)
    Logger[self.class.name].info(*args)
  end

  # Log a message on the warn level.
  def warn(*args)
    Logger[self.class.name].warn(*args)
  end

  # Log a message on the error level.
  def error(*args)
    Logger[self.class.name].error(*args)
  end

  # Log a message on the fatal level.
  def fatal(*args)
    Logger[self.class.name].fatal(*args)
  end
end

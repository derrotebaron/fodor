# This class represents the states of {Flag}s contained in a {FlagSet}.
# For most operations either the name of a flag or its index is used. The index starts with 0 and is incremented with every single flag being inserted into the state. If a whole {FlagSet} is added then this class behaves exactly like if all flags were added in the order of the each function of the {FlagSet}.
class FlagState
  include Enumerable

  def initialize()
    @order = []
    @flags = {}
    @values = {}
  end

  # Adds a {Flag} or all {Flag}s contained in a {FlagSet} to the state.
  # @param flag [Flag,FlagSet] A {Flag} to be added to the state or a {FlagSet} of {Flag}s to be added to the state.
  # @raise [ArgumentError] if the argument is neither a {Flag} nor a {FlagSet}.
  def <<(flag)
    case flag
    when FlagSet
      flag.each do |flag|
        self << flag
      end
    when Flag
      @order << flag.name
      @flags[flag.name] = flag
      @values[flag.name] = nil
    else
      raise ArgumentError
    end
  end

  # Returns the Number of {Flags} represented in this set.
  def size()
    @order.size
  end

  # Adds all {Flag}s contained in a {FlagSet} to the state.
  # @param flag_set [FlagSet] A {FlagSet} of {Flag}s to be added to the state.
  def add_all(flag_set)
    flag_set.each { |flag| self << flag }
  end


  # Queries the state of a specific {Flag} and its state.
  # @param name [Fixnum,String] If the argument is a {Fixnum} then this method returns the flag at the nth place and its value. This means the first added {Flag} has index 0 the next one has index 1 and so on. If the argument is a {String} then this method returns the flag of this name and its value.
  # @return [Hash{:flag,:value=>Flag,Fixnum,String,Boolean]  A {Hash} with the {Flag} as the value to the :flag key and the state of this flag as the value to the :value key.
  def [](name)
    name = @order[name] if Integer === name
    { :flag => @flags[name],
      :value => @values[name] }
  end

  # Changes the state of a specific {Flag}
  # @param name [Fixnum,String] If the argument is a {Fixnum} then this method changes the value the flag at the nth place. This means the first added {Flag} has index 0 the next one has index 1 and so on. If the argument is a {String} then this method changes the value the flag of this name.
  # @param value [Fixnum,String,Boolean] The new value to be assigned to the state.
  def []=(name, value)
    name = @order[name] if Integer === name

    case @flags[name].domain
    when :boolean, :boolean_no
      if value != true && value != false then
        raise ArgumentError, "Value #{value} not in domain #{@flags[name].domain} " +
          "of flag #{name}"
      end
    when Array, Range
      if !(@flags[name].domain.include? value) then
        raise ArgumentError, "Value #{value} not in domain #{@flags[name].domain} " +
          "of flag #{name}"
      end
    end

    @values[name] = value
  end

  # Returns an Iterator over all flags.
  # @yield The given block will get all flags in the same fashion like the {#[]} method.
  def each()
    @order.each() do |name|
      yield self[name]
    end
    self
  end

  # Alters each value using an Iterator.
  #
  # The return value of the block will become the new state of the Flag being
  # yielded.
  # @yield The given block will get all flags in the same fashion like the {#[]} method.
  def alter_each()
    @order.each() { |name| @values[name] = yield self[name] }
    self
  end

  # Returns an {Array} of all values of the state.
  # @return [Array<String,Boolean,Fixnum>]
  def to_a()
    array = []
    @values.each() do |name, value|
      array << self[name]
    end
  end

  # Represent the state as a whitespace separated {String} of the values represented via the representation functions of the respective {Flag}s. The order of the flags is the same as they were added to this object.
  # @return [String]
  def to_s()
    @order.map() do |name|
      flag = @flags[name]
      value = @values[name]
      flag.representation[value]
    end.join " "
  end

  def dup()
    result = FlagState.new
    @flags.each_value() do |flag|
      result << flag
    end
    @values.each() do |name, value|
      result[name] = value
    end
    result
  end

  # This method represents all boolean values of the state with "0"s and "1"s.
  # The compact representation is useful for debugging.
  def show_binstring()
    @values.values.map do |v|
      v ? "1" : "0"
    end.join
  end

  # @private
  def _dump(depth)
    Marshal.dump [@order, @values]
  end

  # @private
  def load(order, values)
    order.each do |flag_name|
      found_flag = nil
      $FLAGSETS.each_value do |set|
        maybe_flag = set[flag_name]
        unless maybe_flag.nil?
          found_flag = maybe_flag
          break
        end
      end
      self << found_flag unless found_flag.nil?
    end

    @values = values
    self
  end

  # @private
  def FlagState._load(str)
    FlagState.new.load(*(Marshal.restore str))
  end
end

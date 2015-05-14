# This class holds infomation about a Flag. It dosen't represent the state of a
# flag for this look at the {FlagState} class.
# Flags have a name, a domain and a string represention function and
# additionally be part of a flag group.
#
# The domain can be a boolean, a range or a array of possible values. A boolean
# domain is represented as :boolean for Flags that can be present or not
# depending on their state or as :boolean_no when handled like +-ffoo+ and
# +-fno-foo+ (Note that the actual string representation is dependent on the
# representation function). If the state of a Flag is one of a few possible
# values then the domain is a {Array} of {String}s. If the set of possible
# values can be be expressed by a {Range} object, such an object can also be
# used as the domain.
#
# The concept of flag groups was introduced to add the possiblilty to deactivate
# flags that trigger bugs, break the programm in some way or aren't availible
# in some version of the used compiler.
class Flag
  attr_reader :name, :domain, :representation

  # @param name [String] The name of the Flag.
  # @param domain [:boolean,:boolean_no,Array<String>,Range] The
  def initialize(name, domain, representation, groups=[])
    @name = name
    @domain = domain
    @representation = representation
    @groups = groups
  end

  # Checks if the flag is in a certain group.
  # @param group [String] Name of the group in which the membership of this flag should be checked.
  def in_group?(group)
    @groups.include? group
  end

  # Show the string representation of this flag with a certain state of the flag.
  # @param args [String] The state of the flag.
  def [](*args)
    @representation[*args]
  end

  # Return a random value in the domain of the flag using a certain {Random}
  # generator.
  #
  # If the {Random} generator is equally distributed then each value has the
  # same chance to be picked
  # @param random [Random] The random generator to be used.
  # @return [String,Boolean,Fixnum]
  def pick(random)
    case @domain
    when Array
      @domain[random.rand 0...@domain.length]
    when :boolean, :boolean_no
      random.rand(0..1) == 1
    when Range
      random.rand(@domain)
    end
  end
end

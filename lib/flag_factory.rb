require_relative "flag"

# This module generates Flags with a specific domain.
# For an explaination of the domain of a {Flag} see the documentation of the
# {Flag} class.
module FlagFactory
  # Generates a normal GCC flag.
  # Examples: -fomit-frame-pointer/-fno-omit-frame-pointer, -ffp-contract=fast
  # @param name [String] The name of the flag.
  # @param domain [:boolean,:boolean_no,Array<String>,Range] The domain of the flag. For a further explaintion how this is used, see the documentation of the {Flag} class.
  # @param prefix [String] The prefix of the flag. For instance the prefix for machine dependent options is "-m". This defaults to "-f".
  # @param delimiter [String] If the domain is non-boolean this delimiter is used by the string representation function to delimit flag name and flag value.
  # @param groups [Array<String>] Array of Strings that denote the groups, that this flag is a member in. For more information on this concept see the documentation of the {Flag} class
  def FlagFactory.generate_gcc_flag(name, domain, prefix="-f", delimiter="=",
                                    groups=[])
    case domain
    when Range, Array
      # -mmemcpy-strategy=loop
      representation = lambda do |value|
        "%s%s%s%s" % [prefix, name, delimiter, value]
      end
    when :boolean
      # -fomit-framepointer
      representation = lambda do |value|
        value ? "%s%s" % [prefix, name] : nil
      end
    when :boolean_no
      # -mno-mmx
      representation = lambda do |value|
        prefix + (value ? "" : "no-") + name
      end
    end
    flag = Flag.new(name, domain, representation, groups)
  end

  # Generates a define flag.
  # Example: -DDEBUG=3
  # @param name [String] The name of the flag.
  # @param domain [:boolean,:boolean_no,Array<String>,Range] The domain of the flag. For a further explaintion how this is used, see the documentation of the {Flag} class.
  # @param groups [Array<String>] Array of Strings that denote the groups, that this flag is a member in. For more information on this concept see the documentation of the {Flag} class
  def FlagFactory.generate_gcc_define_flag(name, domain, groups=[])
    generate_gcc_flag(name, domain, "-D", groups)
  end

  # Generates a define flag.
  # Example: -march=native
  # @param name [String] The name of the flag.
  # @param domain [:boolean,:boolean_no,Array<String>,Range] The domain of the flag. For a further explaintion how this is used, see the documentation of the {Flag} class.
  # @param groups [Array<String>] Array of Strings that denote the groups, that this flag is a member in. For more information on this concept see the documentation of the {Flag} class
  def FlagFactory.generate_gcc_machine_flag(name, domain, groups=[])
    generate_gcc_flag(name, domain, "-m", groups)
  end

  # Generates a define flag.
  # Example: --param predictable-branch-outcome=10
  # @param name [String] The name of the flag.
  # @param domain [:boolean,:boolean_no,Array<String>,Range] The domain of the flag. For a further explaintion how this is used, see the documentation of the {Flag} class.
  # @param groups [Array<String>] Array of Strings that denote the groups, that this flag is a member in. For more information on this concept see the documentation of the {Flag} class
  def FlagFactory.generate_gcc_param_flag(name, domain, groups=[])
    raise ArgumentError,
      "--param arguments can only have ranges" unless domain.is_a Range
    Flag.new(name, domain,
             lambda do |value|
               "--param %s=%s" % [name, value]
             end, groups)
  end
end

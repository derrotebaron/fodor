# Adoption

If you want to use FODOR to optimize the flags of your own programm you will need a custom {Evaluator}.
There are currently three ways to create such an Evaluator: Creating a factory method in {EvaluatorFactory} and makeing it accessible via the {OptimizeTask#read_evaluator} method. As a variation of that you can simply subclass {Evaluator}. Or better: using an {EvaluatorTemplate}.

## Evaluator Template

If your evaluation step is simple and matches the following template you can create an evaluator by simply writing an xml file:

1. Remotely compile the programm.
2. Upload it to a storage host.
3. Download it on the evalution host.
4. Evaluate it.
5. Use an ruby function to parse and interprete the results of the evaluation.

If you need to derive from this formula please skip this section.

### Format

A evaluator is specified in a evaluator tag

```xml
<evaluator>
	...
</evaluator>
```

# Commandlines

The commandlines for the steps are given in compile-cmdline, upload-cmdline, download-cmdline and run-cmdline tags. They are given in a specific format that allows variable substitution. The line its self is given in a shell tag with a format string. For all places the shall be substituted write %s. Since this is a normal format string a single % is given via %%. Please refrain from using other format specifiers such as %d as all parameters are currently strings. The string is currently not checked. The values for the substitution are given in a vars tag as a space separated list.

```xml
	<compile-cmdline>
		<shell><![CDATA[
			mkdir -p %s ; cd %s && cp -r /proj/ciptmp/ne32jilo/libgeodecomp/libgeodecomp-0.3.1/ . && cd libgeodecomp-0.3.1 && cd src && ./compile.sh "%s %s" && rm **/*.{cpp,h,cmake,txt,pc}
		]]></shell>
		<vars>hash hash flags standard-flags</vars>
	</compile-cmdline>
	<upload-cmdline>
		<shell><![CDATA[
			rsync -a .. %s/%s
		]]></shell>
		<vars>storage hash</vars>
	</upload-cmdline>
	<download-cmdline>
		<shell><![CDATA[
			cp -r %s/%s/* .
		]]></shell>
		<vars>storage-path hash-flags</vars>
	</download-cmdline>
	<run-cmdline>
		<shell><![CDATA[
			cd src/; LD_LIBRARY_PATH=. testbed/performancetests/performancetests 1234 0
		]]></shell>
		<vars></vars>
	</run-cmdline>
```

The following variable substitutions are currently possible

- hash :: This is a (non-cryptographic) hash of the flags and the standard_flags. You can expect this to be unique and reproducible for all runs.
- flags :: The string representation of the FlagState.
- standard-flags :: The standard flags of the current optimizer task.
- storage :: The SCP-able path of the storage given for the current optimizer task.
- storage-path :: The local path portion of storage.

# Parsers

For the evaluation of the output of the compilation and evaluation jobs one needs to provide a parser. These parsers are simply standard ruby lambdas. They need to accept just one string argument representing the output of the command.

```xml
	<eval-output-parser><![CDATA[
      lambda do |string|
        Hash[string.split.map { |x| x.split ";" }.drop(1).map do |fields|
          %w{rev date host device order family species dimensions perf unit}.map(&to_sym).zip (fields)
        end].select do |x|
          %w{family species dimensions}.zip (["RegionCount", "gold", "(128, 128, 128)"]).map do |y|
            x.first[y] == x.last
          end
        end.first[:perf]
      end
	]]></eval-output-parser>
```

The parsers are given in the compile-output-parser tag and the eval-output-parser tag.

## Subclassing Evaluator

It is also possible to subclass the {Evaluator} class. You need to expose the new class in the {OptimizeTask#read_evaluator} method.

Implement your evaluation logic in the [] method. This method takes an array of {FlagSet}s evaluates them and returns an array of {JobResult}s. Caching results is a useful feature, so consider implementing it.

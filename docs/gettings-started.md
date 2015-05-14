# Getting Started

tl;dr For a short usage guide see the {file:docs/quickstart.md Quick Start Guide}.

## What's FODOR? (And what is it not?)

FODOR stands for "Flag Optimization using Discrete Optimization Algorithms in Ruby".

It was initially developed for the {https://www.libgeodecomp.org LibGeoDecomp} project to find out if the performance of the library can be improved by using "better" compiler flags. Most academic research implies that automated fiddeling with the flags can yield performance gains. The goal of FODOR is to make use of these performance gains by applying them on real world applications.

While FODOR is not a monolithic set of shell scripts but a moderately modular framework, most of its components were designed for the optimization of compiler flags and can't really be applied to generic optimization tasks without some changes to the core parts of the source code. This is certainly doable, but I don't intend to change this in the near future, but I am happy to accept any patches that do that, assuming the code dosen't break anything and doesn't deteriorate the overall code quality.

## Recomended Experimentation Setup

You should have a least a few different hosts that are accessible via SSH or Slurm. If you do perfomance measurements by timing a program, do note that you should be the sole user of a system. Otherwise this negatively influences the test results, because you can't monopolize the hardware. If you use hardware counters or other metrics this might be unproblematic.

In general, the shorter the evaluation runtime the more candidates you can evaluate. If you can shorten the runtime while keeping the accuracy of your measurement, please do so.

## Usage

In order to correctly use this programm, it is helpful to understand its inner workings.

1. The step function of the optimzier is called.
2. In the step function new candidates are generated and evaluated.
3. The evaluation is done via an instance of the Evaluator class.
4. The evaluator looks into its cache and if it can't provide an result it generates jobs that are executed
5. Evaluations consist of compilation and evalution parts.
6. These individual parts are executed on hosts withis specific host groups.

You can see that there are a lot of parameters. For the configuration of the programm see the {file:docs/formats.md format documentation}. If you need a simple and quick guide see the {file:docs/quickstart.md Quick Start Guide}.

For multiple runs defined in a xml-file just call the programm with the name of that file:

```
$ fodor runs.xml
```

If you want to run a single run simply call the programm with the `--single` and the optimizer file as the argument. The output file is given via the `--output` flag. This paramter is madatory:

```
$ fodor --single hillclimber.xml --output out.fodor
```



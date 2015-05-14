FODOR 1 "MAY 2015" Linux "User Manuals"
=======================================

NAME
----

FODOR - Flag Optimization using Discreet Optimization in Ruby

SYNOPSIS
--------

`fodor` [`--single`] *input.xml* [`--output`*result-file*] [`--continue` *continuation-file*]

`fodor` `--result` *result.fodor*

`fodor` `--csv=`*type* *result.fodor*

`fodor` `--get-best` *result.fodor*

DESCRIPTION
-----------

FODOR is an parameter optimization framework mainly targeted at optimizing compiler flags.

Detailed documentation is shipped with this programm. See /usr/share/doc/fodor/\_index.html

OPTIONS
-------

Without any options the tasks in the input file are executed.

`-r`, `--repl`
  Start a Pry repl in an addtional thread. This is useful for debugging.

`-s`, `--single` *input-file*
  Run a single task given in the input file. This implies the `--output` flag.

`-o`, `--output` *result-file*
  Store the results of a single task in the given file.

`-C`, `--continue` *continuation-file*
  Continue an aborted run.

`-c`, `--csv=`*type*
  Get results as a CSV. Type can be `min_max_average_median`, `min`, `max`, `average`, `median`, `all`. The first shows various statistics about the generations. A single type of statistic can be obtained with the next four options. `all` gives all performance values.

`-b`, `--get-best` *result* 
  Show the performance value and the matching genotype for the best value in the result file.

`-R`, `--result` *result-file*
  Open a Pry repl and load the result into the global $RESULT variable.

AUTHOR
------

Johannes Knödtel <johannes.knoedtel@fau.de>

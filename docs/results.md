# Results

The results are stored in files which are just marshalled Ruby objects. There are two ways to read the files: using commandline flags to export the data to CSV or using a Ruby REPL.

## Using the commandline

With the `--csv=<mode>` commandline flag a result file can be transformed into CSV data. There are different modes to this function:

- `min_max_average_median` :: Each row contains the minimum, maximum, average and median value of a generation
- `min` :: Each row contains the minimum of a generation.
- `max` :: Each row contains the maximum of a generation.
- `average` :: Each row contains the average of a generation.
- `median` :: Each row contains the median of a generation.
- `all` :: Each row contains all values of a generation.

The output is written to standard out. Use shell redirection to save it to a file.

To get the flags of the best result use the `--get-best` commandline option.

## Using Ruby

If `--result` is given as a commandline option a pry REPL will be opened and the data is stored in the local variable `res` and the global variable `$RESULT`

The data structure is the following:

```ruby
{ :steps => number_of_steps
  :results =>
    [ # Generation 1
      [
        { # Generation 1 Candidate 1
          :flag_state => flag_state_generation_1_candidate_1,
          :result     => value_generation_1_candidate_1
        }
      # ...
      ]
    # ...
    ]
}
```

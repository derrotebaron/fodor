# File Formats

All files a user has to to write in order to use FODOR are XML-based. XML Schema files can be found in the schema folder. Not a lot of data validation and consistency checks are in place at this point, so be careful while writing the files.
The results and the evaluator cache are in the Ruby Mashaling format. For more information for handling the results see the {file:docs/results.md results documentation}

All used paths are relative to the working directory. ~ and ~exampleuser are expanded to the users home directory and exampleusers home directory respectively.

## General Settings

All settings are given in the root tag named `settings`.

### SSH Agent Settings

If you want use a SSH Agent, use a `ssh-agent` tag. The keys to load are to be stated as `add-key` tags inside of the `ssh-agent` tag, containing the paths of the keys to be loaded. With the `askpass` attribute in the ssh-agent tag the programm for the password entry can be chosen.

```xml
<ssh-agent askpass="/usr/lib/ssh/x11-ssh-askpass">
  <add-key>~/.ssh/id_rsa</add-key>
</ssh-agent>
```

### Load Host Sets

Host Sets can be loaded with the `hostset-file` tag.

```xml
<hostset-file>hostset.xml</hostset-file>
```

### Load Host Group Sets

Host Group Sets can be loaded with the `hostgroupset-file` tag.

```xml
<hostgroupset-file>hostgroupset.xml</hostgroupset-file>
```

### Callbacks

Jobs can trigger callbacks. A callback has a certain type and a selector. The selector is a regular expression that tries to match the job group name. Currently only the completion of a group can trigger a callback. All callbacks are represented as `callback` tags in a `callbacks` tag. The attributes of it are type, callback-type and selector. For type only `group_complete` is valid. The selector is a perl compatible regex.

The `callback-type` determines what will be done when the callback will be called. If this has parameters they can be given via `argument` tags. The name of the parameter is contained in the `name` attribute. The value is given as the content of the tag.

```xml
  <callbacks>
    <callback type="group_complete"  callback-type="mail" selector=".*">
      <argument name="to">user@example.com</argument>
      <argument name="batch_size">1</argument>
    </callback>
  </callbacks>
```

#### Mail Callback

Currently only the mail callback is availiable. It sends a mail once a certain number fo job groups are finished. This number is given via the `batch_size` parameter. The recipient is given via the `to` parameter.

The mail will be sent via the mail library. You can configure it in the `pre-exec`. Have a look in the offical documentation at: {https://github.com/mikel/mail/wiki}

### Load Flag Set

Flag Sets can be loaded with the `flagset-file` tag.

```xml
<flagset-file>flags.xml</flagset-file>
```

### Slurm Poll Delay

Controls the time between two status updates on the Surm control host.

```xml
<slurm-poll-delay>2</slurm-poll-delay>
```

### Pre Exec

If you need to run some code before the main programm will be run, you can do it via the `pre-exec` tag. This tag contains Ruby code that will be executed beforehand.


## Optimization Run

All optimization runs are defined in single files. A optimization run will also be called a task.

```xml
<optimize-task name="Local Search with Distance = 5">
	...
</optimize-task>
```

The task is described with a `optimize-task` tag. The name must be given in the `name` attribute. This will help with the analysis of the result data and can be used to automatically generate graphs with useful labelling.

### Algorithm

```xml
  <algorithm>Local Search</algorithm>
```

The algorithm has to be given in an `algorithm` tag. All possible algorithms have to be accessable through the {Algorithm} module; for a list of all availiable algorithms see the {file:docs/algorithms.md algorithms documentation}.

```xml
  <algorithm-values>parallel=5,distance=5,seed=20</algorithm-values>
```

Parameters to the algorithms are given in an `algorithm-values` tag in the following format: `parameter1=value1,parameter2=value2`.

```xml
  <termination-criterion type="Steps">200</termination-criterion>
```

The termination criterion is selcted with an `termination-criterion` tag. The type of the criterion is given through the `type` attribute. If the criterion has a variable parameter this is given as the contents of the tag.

### Flag Sets

```xml
  <flag-set>GCC Standard Optimizations</flag-set>
```

To include a flag set to this run include a `flag-set` tag with the name of the flag set as the content.


```xml
  <exclude-flag-group>unsafe</exclude-flag-group>
  <exclude-flag-group>graphite</exclude-flag-group>
  <exclude-flag-group>bug</exclude-flag-group>
```

Flag groups can be removed from the set of tested flags with the `exclude-flag-group` tags have the name of the group to be excluded as the content of the tag.

```xml
  <standard-flags>-march=native</standard-flags>
```

For flags that should be given to given to the compiler independently of the flag set you can use the `standard-flags` tag. Simply put the part of the commandline that is fixed in the content of this tag.

### Host Groups

```xml
  <host-group-compile>cip-00</host-group-compile>
  <host-group-eval>whistler</host-group-eval>
```

The host groups for the compilation and the evaluation are given as contents of the `host-group-compile` and `host-group-eval` tags.

### Folders

```xml
  <folder-compile>/var/tmp/ne32jilo/</folder-compile>
  <folder-eval>/tmp/ne32jilo/</folder-eval>
```

The folders on the remote machindes that should be used for this run are to be given as content of the `folder-compile` tag and the `folder-eval` tag for the compilation and evaluation respectively.

```xml
  <storage>ne32jilo@faui36b.informatik.uni-erlangen.de:/scratch/ne32jilo/</storage>
```

A scp target should be given as the storage where the programm will be stored for the transfer from compilation machine to evaluation machine. This string should be put in the `storage` tag.

### Evaluator

```xml
  <evaluator>libgeodecomp</evaluator>
```

The evaluator for the library under test must be state in the `evaluator` tag. See the {file:docs/adoption.md Adoption documentation} for libraries other then libgeodecomp.

### Versions

```xml
  <versions>
	<version of="gcc">4.9</version>
	<version of="libgeodecomp">3.1.0</version>
  </versions>
```

Most evaluators can load a cache file containing performance data for already executed flag states. Because this is dependent on the tested versions of compilers and optimization target. Each cache entry is tagged with the respective versions. This version description has to be given in the `versions` tag. For each variable version a `version` tag with the associated programm as the `name` attribute and the version as the content should be included in the `versions` tag.

## Automated Runs

```xml
<runs>
	<parallel>
		<run output="out/baz1">dummy-runs/hillclimber_1.xml</run>
		<serial>
			<run output="out/foo1">dummy-runs/genetic_crossover_0.1.xml</run>
			<run output="out/bar1">dummy-runs/genetic_crossover_0.7.xml</run>
		</serial>
		<run output="out/baz2">dummy-runs/hillclimber_5.xml</run>
	</parallel>
</runs>
```

All runs are given with in the root tag named `runs`. The runs at the toplevel are execute serially. Runs can be grouped in `serial` and `parallel` tags and are then executed in serial or parallel respecively. These groups can be nested.

The contens of a `run` tag is the filename of a run definition in the format described above. The result will be written to the file specified in the `output` attribute.

## Host Set

```xml
<hosts>
  <host aliases="faui36b 36b" user="ne32jilo" hostname="faui36b.informatik.uni-erlangen.de" />
  <host user="ne32jilo" hostname="faui36c" slurm-host="36b" partition="usaji" />
</hosts>
```

Hosts are to be declared with a `host` tag. The attributes of a host are `user`, `hostname` and `port` are set with the xml attributes of the same name. If you need aliases for a host simply add a space separated list as the `aliases` attribute.

All of the `host` tags are collected in the root tag `hosts`.

### Slurm Hosts

SSH hosts and Slurm hosts are discriminated by the presence of the `slurm-host` attribute. This attribute denominates the Slurm control server. It must name a SSH host that already appeard previously in the list of hosts. If the host belongs to a certain partition this can be configured via the `partition` attribute.

## Host Groups

```xml
<host-groups>
  <host-group name="cip-00" description="irgendsoeinrechner">
    <host>00b</host>
    <host>00c</host>
    <host>00d</host>
    <host>00e</host>
  </host-group>
  <host-group name="blubb" description="irgendsoeinrechner">
    <host>faui36c</host>
    <host>faui36g</host>
    <host>faui36i</host>
    <host>faui36j</host>
    <host>nomad</host>
  </host-group>
</host-groups>
```

All host groups are give in `host-group` tags. The `name` attribute and the `description` attribute set the name and describe the group. The description is not mandatory but recommended for debugging and documentation. It usually contains a description of the hardware. The content of a `host-group` tag are `host` tags that contain the names of previously in the host set defined hosts. Aliases are allowed here. All `host-group` tags are collected in the root element named `host-groups`.


## Flag Set

```xml
<flags name="GCC PowerPC Optimizations">
  <flag type="gcc-machine" name="pointers-to-nested-functions" domain-type="boolean_no" />
  <flag type="gcc-machine" name="block-move-inline-limit" domain-type="Range" >
    <range from="32" to="INTMAX" />
  </flag>
  <flag type="gcc-machine" name="cmodel" domain-type="list" >
    <list-element value="small"/>
    <list-element value="medium"/>
    <list-element value="large"/>
  </flag>
</flags>
```

All flags are defined with `flag` tags. A flag needs to have a `name` attribute that is the name of the flag as it is used on the commandline, a `type` attribute and a `domain-type`.

The type of a flag has a strong influence on how it will be represented in the commandline for the compilation. Currently there are four different types:

- `gcc` :: For regular gcc flags with the "-f" prefix like -fomit-frame-pointer
- `gcc-machine` :: For flags with the "-m" prefix like -mcmodel=small
- `gcc-param` :: For parameter flags like --param min-crossjump-insns=10
- `gcc-define` :: For defines like -DDEBUG

The prefix for the types can can be overridden using the `prefix` attribute.

Because of the need to denote various possible values for the flags, the domain-type was introduced. It defines what values are possible of a flag. Currently the following domain types are possible:

- `boolean`, `boolean_no` :: This is a boolean flag. The `boolean` variant simply is not present on the commandline if it is false, while the `boolean_no` version is used for flags like -fno-omit-frame-pointer
- `Range` :: This denotes all possible values of a integer range. The bounds of this range are given as a `range` tag as the contents of the `flag` tag. This `range` tag denotes the bound via the `from` and `to` attributes containing integers for the lower and upper limit. There is also a special value for the limits named `INTMAX` that corresponds to 2 ^ 31 - 1.
- `list` :: For flags having a string paramter there is the `list` type. All possible values are to be given inside the `flag` tag as `list-element` tags with the string parameters as the `value` attribute. 

All flags in a set are collected in the root element names `flags`. This tag requires a `name` attribute containing a name that can be referenced in the defintion of a optimization run.

## Logging Configuration

Logging in FODOR is based on Log4R. You need put a configuration called `log4r_config.xml` in your current working directory. Logging is individually handeled for each class. Be sure to have a logger tag for each class. It is best to copy the following example config and modify it to your own needs:


```xml
<log4r_config>
  <pre_config>
    <custom_levels>DEBUG, INFO, WARN, ERROR, FATAL</custom_levels>
    <global level="ALL"/>
  </pre_config>

  <outputter name="console" type="StdoutOutputter" level="DEBUG" >
    <formatter type="Log4r::PatternFormatter">
      <pattern>=>[%5l %d] %C: %M [%t]</pattern>
    </formatter>
  </outputter>

  <outputter name="file_outputter" type="FileOutputter">
    <filename>log/fodor.log</filename>
    <formatter type="Log4r::PatternFormatter">
      <pattern>=>[%5l %d] %C: %M [%t]</pattern>
    </formatter>
  </outputter>

  <!-- Loggers -->
  <logger name="JobManager" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
  <logger name="FlagSet" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
  <logger name="HostSet" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
  <logger name="HostGroup" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
  <logger name="HostGroupSet" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
  <logger name="OptimizeTask" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
  <logger name="Host" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
  <logger name="SlurmHost" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
  <logger name="EvaluatorTemplate" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
  <logger name="GeneticOptimizer" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
  <logger name="OptimizerUtil" level="ALL" additive="false" trace="true">
    <outputter>console</outputter>
    <outputter>file_outputter</outputter>
  </logger>
</log4r_config>
```

## Evaluator Defintion

If you want to define a new Evaluator see the {file:docs/adoption.md adoption documentation}.

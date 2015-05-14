# Quick Start Guide

If you simply want to optimize the compilation result of a project do the following steps:

## Write an Evaluator Template

Write down how you compile your project and measure its runtime. These two steps are seperated and can be executed on different hosts. This allows for the compilation to happen on any host, while the critical evaluation step can be on a set of identical hosts. We will call the resulting file `myProject.xml`. All command lines are format strings in the `shell` tag with their variables in the `vars` tag. We have four commandlines:

- `compile-cmdline` :: compiles the project
- `upload-cmdline` :: uploads the compiled project to the storage
- `download-cmdline` :: downloads the compiled project from the storage
- `run-cmdline` :: evaluates the performance 

The parsing of the output of the evaluation is done in the `eval-output-parser` tag. Its contents is ruby code. It consists of a lambda that takes one argument which is the output of the eval step and converts it into an {Numeric}. FODOR tries to minimize this value. It has to be a positive number (not 0!).

```xml
<evaluator>
	<compile-cmdline>
		<shell><![CDATA[
			mkdir -p %s ; cd %s && cp -r /home/example-user/project/ . && cd project && cd src && CFLAGS="%s %s" make
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
		<vars>storage-path hash</vars>
	</download-cmdline>
	<run-cmdline>
		<shell><![CDATA[
			cd src/ && time ./project-performance-test
		]]></shell>
		<vars></vars>
	</run-cmdline>
	<eval-output-parser><![CDATA[
      lambda do |string|
	    string.match(/(\d+.\d+)s user/)[1].to_f
      end
	]]></eval-output-parser>
</evaluator>
```

## Define hosts and host groups

We will define our hosts in a file called `hostset.xml`. SSH hosts and slurm hosts are discriminated by the `slum-host` attribute.

```xml
<hosts>
  <host user="user" hostname="slurmserver.example.com" />
  <host user="user" hostname="example1.example.com" slurm-host="slurmserver.example.com" partition="partition1" />
  <host user="user" hostname="example2.example.com" slurm-host="slurmserver.example.com" partition="partition1" />
  <host user="user" hostname="example3.example.com" slurm-host="slurmserver.example.com" partition="partition1" />
  <host user="user" hostname="example4.example.com" slurm-host="slurmserver.example.com" partition="partition1" />
  <host user="user" hostname="example5.example.com" />
  <host user="user" hostname="example6.example.com" />
  <host user="user" hostname="example7.example.com" />
  <host user="user" hostname="example8.example.com" />
</hosts>
```

We will group our hosts in a file called `hostgroupset.xml`:

```xml
<host-groups>
  <host-group name="groupCompile" description="Hosts for Compilation">
	<host>example5.example.com</host>
	<host>example6.example.com</host>
	<host>example7.example.com</host>
	<host>example8.example.com</host>
  </host-group>
  <host-group name="groupEval" description="Hosts for evaluation">
    <host>example1.example.com</host>
    <host>example2.example.com</host>
    <host>example3.example.com</host>
    <host>example4.example.com</host>
  </host-group>
</host-groups>
```

## Define flags

The flags we want to optimize will go into a file called `flags.xml`:

```xml
<flags name="My Flags">
	<flag type="gcc" name="defer-pop" domain-type="boolean_no" />
	<flag type="gcc" name="optimize-sibling-calls" domain-type="boolean_no" />
	<flag type="gcc" name="indirect-inlining" domain-type="boolean_no" />
	<flag type="gcc" name="inline-functions" domain-type="boolean_no" />
	<flag type="gcc" name="inline-small-functions" domain-type="boolean_no" />
	<flag type="gcc" name="inline-functions-called-once" domain-type="boolean_no" />
	<flag type="gcc" name="merge-constants" domain-type="boolean_no" />
	<flag type="gcc" name="merge-all-constants" domain-type="boolean_no" />
	<flag type="gcc" name="cse-skip-blocks" domain-type="boolean_no" />
	<flag type="gcc" name="cse-follow-jumps" domain-type="boolean_no" />
</flags>
```

## Write settings

We need to put our general settings in a file called `settings.xml`:

```xml
<settings>
  <slurm-poll-delay>2</slurm-poll-delay>
  <ssh-agent askpass="/usr/lib/ssh/x11-ssh-askpass">
    <add-key>~/.ssh/id_rsa</add-key>
  </ssh-agent>
  <hostset-file>hostset.xml</hostset-file>
  <hostgroupset-file>hostgroupset.xml</hostgroupset-file>
  <flagset-file>flags.xml</flagset-file>
</settings>
```

## Define a task

Now we define a task in a file called `mytask.xml`:

```xml
<optimize-task name="My Project Optimiziation">
  <algorithm>Hillclimber</algorithm>
  <algorithm-values>parallel=1,seed=1337</algorithm-values>
  <termination-criterion type="Steps">5</termination-criterion>
  <flag-set>My Flags</flag-set>
  <standard-flags>-D_FORTIFY_SOURCE=1</standard-flags>
  <host-group-compile>groupCompile</host-group-compile>
  <host-group-eval>groupEval</host-group-eval>
  <folder-compile>/tmp/project/</folder-compile>
  <folder-eval>/tmp/project/</folder-eval>
  <storage>user@storage.example.com:/tmp/projectStorage</storage>
  <evaluator>template:myProject.xml</evaluator>
  <versions></versions>
</optimize-task>
```

## Run the task

Now we just run the task:

```
$ fodor --single mytask.xml --ouput mytask.fodor
```

## Process the results

You can get the best flags with the `--get-best`:

```
$ fodor --get-best mytask.fodor
```

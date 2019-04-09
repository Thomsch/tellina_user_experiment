# Tellina User Study Design Doc

## Introduction

Tellina is a natural language -> command translation tool.  Tellina accepts a
natural language description of file system operations, and displays a ranked
list of bash one-liner suggestions made by the model. The user can scroll down
the web page to explore more suggestions.

In an experiment, people were given
descriptions of file system operations, and asked to write bash commands to
perform the operations.  The experimental group had access to Tellina, web
search, and man pages; the control group had access only to web search and
man pages. Measurements were done on whether subjects successfully complete the
tasks, and the amount of time that it takes to complete the tasks.
A post-task questionnaire obtained qualitative feedback.

We need to redo the experiment, for a few reasons.
1. Tellina has changed since the user study was performed.  Tellina has better
   accuracy and handles more commands.  It would not be compelling to report an
   experiment on an implementation that has since been superseded.
2. The user study was relatively small (around 30 subjects), so the experimental
   results were not always statistically significant.  With a larger pool of
   subjects, the results will be more compelling.

This design document describes a new infrastructure for the user design, as the
previous one was buggy.

## Overview

The experiment infrastructure consists of several components:
- Server side: The server's main purpose is to collect and store data from all
  experiments. This includes information about users, issued commands, time
  spent on tasks, browsing history, etc.
  - The server will receive POST requests from clients and append them to a
      single log file.
- Client side: the client side consists of the following components
  - Initial configuration script that sources infrastructure scripts to setup
    the modified bash interface for the user to interact with, which is
    described below.
  - A slightly modified bash interface for the user to interact with.
    Modifications include (see [Client Side](#client-side) for more details):
    - Logs the command entered by the user before executing that command.
    - After user command execution, verifies that the command entered by the
      user produces the correct output (both in the state of the file system and
      in standard output).
      - Displays a diff if the actual and expected outputs do not match (one for
        the file system state, one for the standard out).
    - Helpful user functions: `reset`, `abandon`, etc. to allow the user to work
      with the tasks more smoothly.
    - Infrastructure functions: functions set up to administer and manage the
      experiment as well as communicate with the server.
      - Example functions include: moving on to the next task, determining task
        order, logging, extracting the directory for the user to perform tasks
        on, etc.
  - The directory with which the user will perform tasks on.
    - A "pure" version of this directory will be kept in a tarball, which will
      be extracted at the beginning of a new task, or when the user issues a
      reset command.
- Analysis of experimental data: parse, organize, and sort the data that was
  recorded to the log file. It will be able to do the following to a user log
  files:
  - We will want to do a real statistical analysis with a hypothesis test and
    computed p-values, not just summary statistics.
- Tasks:
  - We will have `N` tasks for each user.
  - The tasks will be labeled sequentially.
  - Each task will have a corresponding expected output file for both file
    system output and standard output.

## Implementation
### Server side
The server side will be hosted on the [UW CSE's
Homes](https://www.cs.washington.edu/lab/web). This allows the server to be
reliable as the host is maintained by the CSE department.

The server will only handle `POST` requests, which will parse the form its
given into the CSV format of the log.

The server implementation will be similar to:
```PHP
<?php
if (isset($_POST) && ($_POST)) {
    $filename="log.csv";
    $line .= implode(",", $_POST);
    $line .= "\n";
    file_put_contents($filename, $line, FILE_APPEND);
}
?>
```
The log file (`log.csv`) will have the following columns:
- user_id: the username and machine name associated with the information on the
  current row
- time_stamp: the current time that the command was entered on the client side.
  - ISO-8601 formatted, with UTC as the timezone designator.
- task_no: the current task number.
- treatment: T/NT for Tellina/No Tellina.
- command: the command that the user entered.
- time (seconds): time in seconds the user took to formulate the command.
- status: `1` if the user succeeded, `2` if the user ran out of time, `0` if the
  user abandoned the task, and `3` if the task is incomplete but the user still
  has time.

Example content of what `log.csv` could look like:

|time_stamp|task_no|treatment|command|time|status|
|-|-|-|-|-|-|
|2019-04-05T18:12:00Z|1|T|find . -name "*.txt" -delete|33|3|
|2019-04-05T18:12:04Z|1|T|reset|37|3|
|2019-04-05T18:12:07Z|1|T|find . -name "*.txt"|40|1|
|...|...|...|...|...|...|
|2019-04-05T18:42:10Z|22|NT|find . -name "*.test"|10|3|
|...|...|...|...|...|...|
|2019-04-05T18:48:02Z|22|NT|...|300|2|

### Client side
The client side will use common bash commands along with the help of several
python scripts to run the experiments. It is expected that the client side can
run on the CSE Linux VM without issue, and could potentially work on Attu as
well.

The client requires the user to have a graphical interface for the experiment.
This is because the client uses [Meld](http://meldmerge.org/) to display the
diffs.

#### Distribution
The client side will be distributed to users through a ZIP archive. The contents
of the archive is described bellow.

#### Directory Structure
The directory structure for the client side after extracting the ZIP archive to
`dir` will look similar to:
```
dir/
|__.infrastructure
|  |__setup.sh       - Bash script that sources funciton definition files, sets
|  |                   variables for the experiment (paths to scripts, to files,
|  |                   etc.), enables bash-preeexec.
|  |__*.sh           - Bash files with definitions for functions useful
|  |                   for the experiment (infrastructure functions, user
|  |                   functions, etc.)
|  |__*.py           - Python scripts that helps with output verifictation, task
|  |                   order determination, and printing task descriptions.
|  |__files.tar      - The original version of the directory the user will be
|  |                   working on.
|  |__tasks/
|  |  |__task1/
|  |  |  |__task1.json      - JSON file with description of task
|  |  |  |__task1.fs.out    - Expected state of file system
|  |  |  |__task1.std.out   - Expected stdout of user command
|  |  |__task2/
|  |  |  |__...
|  |  |__...
|  |__...
|__configure        - Bash script that the user can run to start the experiment.
|                     Sources ./.infrastructure/setup.sh.
|__(file_system)/   - The directory that the user will be performing tasks on.
|  |                  Extracted from files.tar on setup. Removed and
|  |                  re-extracted on user reset
|  |__...
|__README.txt       - Description of experiment (what's going to happen, time
                      limit, resources, etc.)
```

#### Setting Up
To set up the client side for experimentation, the user will be instructed to
source the `configure` bash script.

The script will source `.infrastructure/setup.sh`, which will do the following:
- Set up "variable files" that will keep track of the current task, task order,
  treatment, and the most recent command.
  - Example: `.treatment` where the content is either `T` or `NT`.
  - This will allow the client side to be resumed if a failure happens.
  - The files will be in the `.infrastructure` directory.
- Install [Bash-Preexec](https://github.com/rcaloras/bash-preexec).
  - The installation is quite simple: download the `bash_preeexec.sh` and source
    it.
- Create the user ID by gathering user information:
  - Machine name: determined by the `hostname` bash command
  - Username: the user will be asked to enter their UW NetID
  - User ID will then be `username@machine_name`.
- Determine the task set ordering:
  - We will have 4 task orderings, with `s1, s2` as task set 1 and 2, and `T,
    NT` for Tellina and No Tellina

    ||1st|2nd|
    |-|-|-|
    |0|`s1 T`|`s2 NT`|
    |1|`s2 T`|`s1 NT`|
    |2|`s1 NT`|`s2 T`|
    |3|`s2 NT`|`s1 T`|
    - The user ID will be 
  1. `f` can hash the user ID then do `hash % 4`.
- Set up the experiment prompts to follow that order.
- Set up user specific functions: `reset`, `task`, `abandon`, etc.

For Bash-Preexec, the following configurations will be implemented:
- `preexec`: ran right after the user enters a command and right before the
  command is executed
  - Send command to the server
- `precmd`:
  - Check for specific commands:
    - `task`: prints the current task's description
    - `abandon`: reset the timer and go on to next task
    - `reset`: reset the file system and increment `resets` count in log file
    - `helpme`: lists the commands available to the user
  - Check if the previous command's output is correct. If it is then move on to
    the next task, if not then display a diff of the file system and let the
    user continue.
  - Keep track of the time limit for the user (using the `$SECONDS` environment
    variable) and determine if the user ran out of time.
    - The check will happen after the command is executed.
    - **Note**: ideally, we would want a timer to interrupt the task and move on
      to the next one. This method has several caveats:
      - A bit more complicated to implement.
      - What happens if the user is in the middle of typing a command?
      - What happens if the interrupt happens during one of the phases of
        `preexec` or `precmd`?
      - What happens if the interface crashes but the timer is still running?
  - Check if all the tasks are complete.
    - Remind them to do the survey.
    - Uninstall Bash-preexec: Remove the `bash_preexec.sh` file.
  - Send user's data to the server:
    - Task number
    - Treatment.
    - Command(s) used.
    - Time taken.
    - Status.
    - Resets.

#### Communication With Server
Communication with the server will be done through simple bash functions that
act as wrappers around `curl` to send HTTP requests.

- `write_log()`:
  - Parameters:`time_stamp`, `task_no`, `treatment`, `command`, `time`,
    `status`.
  - Sends a `POST` request to the server with the specified parameters.

#### Task Interface
- Directory for experiment files:
  - The files used for the experiment will be distributed in a TAR file. The
    initial configuration of the interface and subsequent resets will extract
    the TAR into a specified directory.
  - The user will be performing tasks on files within this directory.
  - Output verification:
    - Verification will be done using a python script called
      `verify_output.py`:
      - Parameters: `<task_no> [command...]`
      - Return: `1` if the actual output matches expected, `0` if it did not.
      - The script will get the current state of the file system, normalize it,
        and compare it with the corresponding task's expected output.
      - The script will also check the `stdout` of the user command on the
        corresponding expected output as well.
      - If the actual output does not match with the expected output, `meld` is
        spawned to display the diffs between the actual and expected.
    - If the verification passes, the interface will reset the mock file system,
      send a `1` to the log file, and move on to the next task.
    - If the verification fails, the interface will tell the user, remain on the
      current task, and send a `3` to the log file.
- Tutorial
  - 2 simple tasks will be displayed to the user in the beginning of the
    experiment to introduce them to Tellina and how the system works.
- Time limit:
  - Each task will have up to **5** minutes to be completed.
  - Currently, the time limit will be checked once the user has entered a
    command.
  - This will reset the time counter, the directory for experiment files, send a
    `2` status to the server, and move on to the next task.
- After the each half of the experiment, confirm if the user has been following
  the treatment for that half (used Tellina when allowed, did not use when not
  allowed)
  - The user's answer will be recorded just like a command sent to the log file.

## Risks and Concerns
- User file system safety.
  - **The client task interface does not guarantee that the user's file system
      will be safe from misused commands. The only directory that can be rolled
      back using the interface will be the mock file system directory as well as
      the interface directory itself.**
    - For example, the interface does not prevent or protect the user from
      running `rm -rf $HOME`.
  - Need to display this in the README.txt when the client is distributed.

## Acknowledgements
- Some of the code used for the infrastructure was imported and modified from
  the following git repos:
  - TellinaTool/bash_task_interface.git
  - TellinaTool/user_study_chrome_extension.git
  - TellinaTool/resource-website.git


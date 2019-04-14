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

### Experiment Infrastructure

The experiment infrastructure consists of several components:
- Server side: The server's main purpose is to collect and store data from all
  experiments. This includes information about users, issued commands, time
  spent on tasks, browsing history, etc.
  - The server will only handle POST requests from clients, convert the request
    into CSV format and append them to a single log file.
- Client side: this contains
  - Information about the experiment, requirements for the client side
    infrastructure (which terminal they should use, what system they should be on,
    etc.), and instruction on how to set up the client side infrastructure and
    begin the experiment.
  - Initial configuration script that sources infrastructure code to setup the
    experiment and begin it.
    - This will also change the user's current directory to be where they will
      be performing tasks.
  - Infrastructure code: this code will add the following functionality to the
    Bash shell it was sourced in:
    - Logs any command entered before executing that command.
    - After command execution, verifies that the command produces the correct
      output (both in the state of the file system and in standard output).
      - Displays a diff if the actual and expected outputs do not match (one for
        the file system state, one for the standard out).
    - Adds meta-commands and meta-functions:
      - Helpful user commands: `reset`, `abandon`, etc. to allow the user to
        work with the tasks more smoothly.
      - Infrastructure bash functions that manage the experiment as well as
        communicate with the server.
        - Example functions include: move to next task, determine task order, send
          log, extract the directory for the user to perform tasks on, etc.
      - (see [Client Side](#client-side) for more details).
  - The directory in which the user will perform tasks in.
- Analysis of experimental data: determine relative performance of subjects
  using Tellina versus those who are not, via statistical analysis.
- Tasks:
  - We will have `N` tasks for each user.
  - The tasks will be labeled sequentially.
  - Each task will have a corresponding expected output file for both file
    system output and standard output.

### User Experience

Users are given the client side of the experiment infrastructure. Once they are
ready to begin, they will source the initial configuration script in a Bash
shell to begin the experiment.

Throughout the experiment, the users will be interacting with the shell where
they started the experiment in, Meld, and a web browser of their choice.
  - They will use a Bash shell to perform tasks and man page lookups.
  - Meld is displayed to the user when actual output does not match expected
    output for commands they entered.
  - They will use the web browser to find resources and interact with Tellina
    (when applicable).

### User Interface

The Bash shell for the experiment will have all built-in commands, prompts, and
pipes unchanged. The experiment infrastructure, once set up, will add the
following differences to the shell's interface (assume print means "print to
`stdout`" unless specified otherwise):
- The user will be able to run the following **user meta-commands**:
  - `task`: prints the current task's description and number
  - `abandon`: abandons the current task and go to the next task.
  - `reset`: reset the file system
    - This command will return the user to the directory where they called it.
  - `helpme`: lists the commands available to the user
- Prints a welcome message, that the experiment has started, and the list of
  meta-commands that user can run once the experiment setup is complete.
- For every new task, prints the task description and the current task number.
- On task success, prints a success message and move to the next task.
- On task time out, prints a time out message and move to the next task.
- On file system change when a task that does not expect a change, prints a
  warning.
- When the experiment ends, prints a reminder for the user to fill out a
  survey.

**Note:** the two initial tasks that the user will be doing will be tutorial
tasks. The tutorial will print instructions on what to do for each step to the
shell as well.

Meld and the web browser are unmodified.

## Implementation
### Server side
The server side should be hosted on the [UW CSE's
Homes](https://www.cs.washington.edu/lab/web).
This allows the server to be reliable as the host is maintained by the CSE
department.

The server will only handle `POST` requests.  It will log each `POST`
request to a CSV file.

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
The log file (`log.csv`) that is appended to by the server will have the
following columns:
- user_id: the username and machine name associated with the information on the
  current row
- time_stamp: the current time that the command was entered on the client side.
  - ISO-8601 formatted, with UTC as the timezone designator.
- task_no: the current task number.
- treatment: Tellina/NoTellina.
- task_order: the task order that was assigned to this user.
- command: the command that the user entered.
- time_elapsed (seconds): time in seconds the user took to formulate the command.
- status: `pass` if the user succeeded, `timeout` if the user ran out of time,
  `abandon` if the user abandoned the task, and `incomplete` if the task is incomplete but the
  user still has time.

Example content of what `log.csv` could look like:

|user_id|task_order|time_stamp|task_no|treatment|command|time_elapsed|status|
|-|-|-|-|-|-|-|-|
|abc@machineA|0|2019-04-05T18:12:00Z|1|Tellina|find . -name "*.txt" -delete|33|incomplete|
|ddd@machineD|2|2019-04-05T18:12:03Z|1|NoTellina|find . -name "*.txt"|40|pass|
|abc@machineA|0|2019-04-05T18:12:04Z|1|Tellina|reset|37|incomplete|
|abc@machineA|0|2019-04-05T18:12:07Z|1|Tellina|find . -name "*.txt"|40|pass|
|...|...|...|...|...|...|...|...|
|abc@machineB|1|2019-04-05T18:42:10Z|21|Tellina|find . -name "*.test"|10|pass|
|...|...|...|...|...|...|...|...|
|bcd@machineB|1|2019-04-08T18:48:02Z|22|Tellina|...|300|timeout|

The start time of a task is the `time stamp` of the row where the `command`
column is "start".

The total time for a task is the `time_elapsed` of the row where the `status` is
either `pass`, `abandon`, or `timeout`.

### Client side
It is expected that the client side can run on the CSE Linux VM without issue,
and could potentially work on Attu as well.

The client requires the user to have a graphical interface for the experiment.
This is because the client uses [Meld](http://meldmerge.org/) to display the
diffs between actual and expected output.


#### Distribution
The client side will be distributed to users through a ZIP archive. The contents
of the archive is described bellow.

#### Directory Structure
The directory structure for the client side after extracting the ZIP archive to
`dir` will look similar to:
```
dir/
|__.infrastructure
|  |__setup.sh        - Bash script that sources function definition files, sets
|  |                    variables for the experiment (paths to scripts, to files,
|  |                    etc.), enables bash-preeexec.
|  |__bash-preexec.sh - Bash script that defines Bash-preexec functions.
|  |__*.sh            - Bash files with definitions for functions useful
|  |                    for the experiment (infrastructure functions, user
|  |                    functions, etc.)
|  |__*.py            - Python scripts that helps with output verification, task
|  |                    order determination, and printing task descriptions.
|  |__files.tar       - The original version of the directory the user will be
|  |                    performing tasks on.
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
|__file_system/     - The directory that the user will be performing tasks on.
|  |                  Extracted from files.tar on setup. Removed and
|  |                  re-extracted on user reset. The user will automatically be
|  |                  changed into this directory when the experiment starts and
|  |                  on resets.
|  |__...
|__README.txt       - Description of experiment (what's going to happen, time
                      limit, resources, etc.)
```

#### Setting Up
To set up the client side for experimentation, the user will be instructed to
run the following command:
```sh
source ./configure
```

The script will source `.infrastructure/setup.sh`, which will do the following:
- Set up variable files that will keep track of the current task, task order,
  treatment, and the most recent command.
  - This will allow the client side to be resumed if a failure happens.
  - The files will be in the `.infrastructure` directory.
  - Files:
    - `.treatment`: the treatment for the current task
    - `.command`: the most recently entered command
    - `.status`: the status of the current task
    - `.task_order`: the task ordering for this user `[0-3]`
    - `.task_no`: the number of the current task `[1-n]`
- Sources `infrastructure.sh`, which defines the following functions:
  - `next_task`: does a few things one of those is call `write_log`.
  - `make_fs`:
  - `write_log`:
  - `determine_task_order`:
- Install [Bash-Preexec](https://github.com/rcaloras/bash-preexec) by sourcing
  `bash-preexec.sh`.
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
    - The task ordering will then be determined by this bash command:
    ```sh
    echo $((0x$(md5sum <<<"user_id" | cut -c1) % 4))
    ```
    - This function makes sure that the same `user_id` will have the same task
      ordering.
- Set up the experiment prompts to follow the determined task order.
- Change the user into the `file_system/` directory.

#### Bash-Preexec
Bash-preexec allows running code before and after the execution of a command
that was ran interactively in the terminal.

The following configurations will be implemented:
- `preexec`: ran right after the user enters a command and right before the
  command is executed
  - Writes the command to `.command`.
- `precmd`: ran right after the user command is executed and right before the
  prompt is displayed
  - Handle user meta-command:
    - No output verification
    - If `abandon`:
      - write "abandon" to `.status` and call
        `next_task`.
    - Otherwise
      - `reset`:
        - Stores the current directory
        - Calls `make_fs`
        - Changes back into stored directory
      - `helpme`: prints the list of user meta-commands.
      - `task`: calls `get_task_description.py` with the current `.task_no` to
        print the task's description.
      - Write "incomplete" to `.status` and call `write_log`.
  - Check if the command in `.command` is correct. If it is then write "success"
    to `.status` and call `next_task`, if not then display a diff of the file
    system, write "incomplete" to `.status`, and call `next_task`.
  - Keep track of the time limit for the user (using the `$SECONDS` environment
    variable) and determine if the user ran out of time.
    - The check will happen after the command is executed.
    - If the user ran out of time, write "timeout" to `.status` and call
      `next_task`.
    - **Note**: ideally, we would want a timer to interrupt the task and move on
      to the next one. This method has several caveats:
      - A bit more complicated to implement.
      - What happens if the user is in the middle of typing a command?
      - What happens if the interrupt happens during one of the phases of
        `preexec` or `precmd`?
      - What happens if the interface crashes but the timer is still running?
  - Check if all the tasks are complete, if it is then clean up.

#### Output verification:
- Verification will be done using a python script called
  `verify_output.py`:
  - **Parameters**: `<task_no> [command...]`
    - Each parameter after `<task_no>` is interpreted as part of the command
      the user entered.
  - The script checks the task number to see whether it is a "file system"
    task, which modifies the file system, or a "select" task, which does not
    modify the file system and only outputs to `stdout`:
    - If it is a "file system" task, the script will:
      - Get the current state of the file system and compares it to the
        expected file system for the current task.
    - Else if it is a "select" task, the script will:
      - Get the current state of the file system and compares it to the
        original state to make sure that it was not changed.
      - If the file system was not modified:
        - Re-execute the user command and capture the `stdout`.
        - Check that the `stdout` of the user command on the corresponding
          expected output.
      - If the file system was modified then the task failed.
  - If the actual output does not match with the expected output,
    [Meld](http://meldmerge.org/) is killed and re-spawned to display the
    diffs between the actual and expected outputs.
  - **Return**: `0` if the actual output matches expected, `1` if it did not.

#### Directory for experiment files:
- The files used for the experiment will be distributed in a TAR file. The
  initial configuration of the interface and subsequent resets will extract
  the TAR into a specified directory.
- The user will be performing tasks on files within this directory.

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


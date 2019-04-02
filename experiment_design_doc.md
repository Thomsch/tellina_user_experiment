# Tellina User Study Design Doc

## Introduction

Tellina is a natural language -> command translation tool.  Tellina accepts a
natural language description of file system operations, and displays a ranked
list of bash one-liner suggestions made by the model. The user can scroll down
the web page to explore more suggestions.

To answer questions regarding the usefulness of the tool, people were given
descriptions of file system operations, and asked to write bash commands to
perform the operations.  The experimental group had access to Tellina, web
search, and man pages; the control group had access only to web search and
man pages. Measurements were done on whether subjects successfully complete the
tasks, and the amount of time that it takes to complete the tasks.  We will also
obtain qualitative feedback from a post-task questionnaire.

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
- Client side: the client side consists of the following components
  - A slightly modified bash interface for the user to interact with.
    Modifications include (see [Client Side](#client-side) for more details):
    - Bash-preexec: runs extra code before the entered command is executed and
      before the prompt is displayed after execution.
    - Helpful user functions: `reset`, `abandon`, etc. to allow the user to work
      with the tasks more smoothly.
    - Infrastructure functions: functions set up to administer and manage the
      experiment as well as communicate with the server.
  - Python scripts that verify the output of a command and displays a diff.
  - Initial configuration script to set up the user and make sure that the
    server is responding.
  - The directory with which the user will perform tasks on.
  - "Pure" version of the mock file system.
- Post-processor: the post-processor's main purpose is to parse, organize, and
  sort the data that was recorded for the experiments (the log files created by
  the server). It will be able to do the following to a user log files:
  - Group tasks by name and treatment:
    - Because each task can have multiple lines in the log file (due to multiple
      commands being logged).
  - Get (average) number of reset(s) for a specified task and treatment.
  - Get (average) time(s) for a specific task and treatment.
  - Get (average) success rates for a specific task and treatment.
- Tasks:
  - We will have `N` tasks for each user:
  - The tasks will be labeled sequentially.
  - Each task will have a corresponding expected output file for both file
    system output and standard output.

## Implementation
### Server side
#### Experiment data directory
This directory will hold all data collected from each experiment that was run.
It will have a rough structure of:
```
/
|__user1
|  |__log.csv
|  |__tellina_used.csv
|__user2k
|  |__log.csv
|  |__tellina_used.csv
|__user3
|__...

```

`log.csv` will have the following columns:
- time_stamp: the current time that the command was entered.
- task_no: the set_task number.
- treatment: T/NT for Tellina/No Tellina.
- command: the command that the user entered.
- time (seconds): time in seconds the user took to formulate the command.
- status: `1` if the user succeeded, `2` if the user ran out of time, `0` if the
  user abandoned the task, and `3` if the task is incomplete but the user still
  has time.

Example content of what `log.csv` could look like:

|time_stamp|task_no|treatment|command|time|status|
|-|-|-|-|-|-|
|18:12:00|1|T|find . -name "*.txt" -delete|33|3|
|18:12:04|1|T|reset|37|3|
|18:12:07|1|T|find . -name "*.txt"|40|1|
|...|...|...|...|...|...|
|18:42:10|22|NT|find . -name "*.test"|10|3|
|...|...|...|...|...|...|
|18:48:02|22|NT|...|300|2|

`tellina_used.csv` is simple:
- half: the 1st or 2nd half of the experiment
- used: Y/N for Yes/No

Example:

|half|used|
|-|-|
|1st|No|
|2nd|Yes|

#### Server application
There will be a simple Flask application managing the data directory.
The will be hosted on a CSE department managed machine using the CSE Homes WSGI
server.

The app will handle the following requests from the client:
- `create_user()`:
  - Route: `/create_user`, methods: `POST`
  - Expected request:
    ```
    POST /create_user
    Host: host
    Content-Type: application/x-www-form-urlencoded
    Content-Length: ...

    user_id=user_id
    ```
  - Creates a new user directory `user_id` and the CSV file associated to the
    user.
  - Respond with the `user_id` and the success code.
- `write_log(user_id, file)`:
  - Route: `/<user_id>/<file>`, methods: `POST`
  - Expected request:
    ```
    POST /<user_id>
    Host: host
    Content-Type: application/x-www-form-urlencoded
    Content-Length: ...

    key1=value1&key2=value2&...
    ```
  - The keys that are accepted are: `time_stamp`, `task_no`, `treatment`,
    `command`, `time`, `status`, `half`, `used`.
  - `<file>` can be either `log.csv` or `tellina_used.csv`.
  - The method will convert the `POST` request to the CSV file format and append
    to the corresponding user log file.
    - The method will not do any checking for right column types to match with
      the file given.

### Client side
The client side will use common bash commands along with the help of several
python scripts to run the experiments. It is expected that the client side can
run on the CSE Linux VM without issue, and could potentially work on Attu as
well.

#### Distribution
The client side will be distributed to users through a ZIP archive. The contents
of the archive is described bellow.

#### Directory Structure
The directory structure for the client side after extracting the ZIP archive to
`dir` will look similar to:
```
dir/
|__.infrastructure
|  |__*.sh           - Several Bash files with definitions for functions useful
|  |                   for the experiment (infrastructure set-up, user
|  |                   functions, etc.)
|  |__files.tar      - The original version of the mock file system
|  |__tasks/
|  |  |__task1/
|  |  |  |__task1.json      - JSON file with description of task
|  |  |  |__task1.fs.out    - Expected state of file system
|  |  |  |__task1.std.out   - Expected stdout of user command
|  |  |__task2/
|  |  |  |__...
|  |  |__...
|  |__...
|__configure        - Bash script that the user can run to start the experiment
|__README.txt       - Description of experiment (what's going to happen, time
                      limit, resources, etc.)
```

#### Setting Up
To set up the client side for experimentation, the `configure` bash script will be
run by the user.

The script will do the following:
- Set up "variable files" that will keep track of the current task, task order,
  and treatment.
  - Example: `.treatment` where the content is either `T` or `NT`.
  - This will allow the client side to be resumed if a failure happens.
  - The files will be in the `.infrastructure` directory.
- Install [Bash-Preexec](https://github.com/rcaloras/bash-preexec).
  - The installation is quite simple: download the `bash_preeexec.sh` and source
    it.
- Collect user information:
  - Machine name: determined by the `hostname` bash command
  - Username: the user will be asked to enter their UW NetID
- Set up user specific functions: `reset`, `task`, `abandon`, etc.
- Set up the task set ordering:
  - The task set ordering for a user will be determined using a function
    `f`. Several ideas for `f`:
    1. `f` can hash the user name then do `hash % 4`.
    2. `f` can randomly choose the treatment from `Uniform{0, 3}`.
    3. ?
  - Set up the experiment prompts to follow that order.

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

The functions are:
- `create_user()`:
  - Sends `POST` request to the server to create the user directory.

- `write_log()`:
  - Parameters:`time_stamp`, `task_no`, `treatment`, `command`, `time`,
    `status`.
  - Sends a `POST` request to the server with the specified parameters.

#### Task Interface
- Mock File System
  - The files used for the file system will be distributed in a TAR file. The
    initial configuration of the interface and subsequent resets will extract
    the TAR into a specified directory.
  - Output verification:
    - Verification will be done using a python script called
      `verify_output.py`:
      - Parameters: `<task_no> <time_elapsed> [command...]`
      - Return: `1` if the task passed, `0` if it did not.
      - The script will get the current state of the file system, normalize it,
        and compare it with the corresponding task's expected output.
      - The script will also check the `stdout` of the user command on the
        corresponding expected output as well.
    - If the verification passes, the interface will reset the mock file system,
      send a `1` to the log file, and move on to the next task.
- Tutorial
  - 2 simple tasks will be displayed to the user in the beginning of the
    experiment to introduce them to Tellina and how the system works.
- Time limit:
  - Each task will have up to **5** minutes to be completed.
  - Currently, the time limit will be checked once the user has entered a
    command.
  - This will reset the time counter, the mock file system, send a `2` status to
    the server, and move on to the next task.
- After the each half of the experiment, asks the user if the have been using
  Tellina to help them
  - A request will be sent to the server to record this.

## Risks and Concerns
- Flask vs. something simpler
  - I will take a look at Jason's code as soon as I can get access to it and
    make the necessary changes to the [server application](#server-application)
    section.
- User file system safety.
  - **The client task interface does not guarantee that the user's file system
      will be safe from misused commands. The only directory that can be rolled
      back using the interface will be the mock file system directory as well as
      the interface directory itself.**
    - For example, the interface does not prevent or protect the user from
      running `rm -rf $HOME`.

## Acknowledgements
- Some of the code used for the infrastructure was imported and modified from
  the following git repos:
  - TellinaTool/bash_task_interface.git
  - TellinaTool/user_study_chrome_extension.git
  - TellinaTool/resource-website.git


# Tellina User Study Design Doc

## Introduction

Tellina is a natural language -> command translation tool, which accepts a
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

The experiment infrastructure will be consisted of several components:
- Server side: The server's main purpose is to collect and store data from all
  experiments. This includes information about users, issued commands, time
  spent on tasks, browsing history, etc.
- Client side: the client side consists of the following components
  - A slightly modified bash interface for the user to interact with.
  - Scripts that verify the output of a command and displays a diff.
  - Initial configuration script to set up the user and make sure that the
    server is responding.
  - Scripts that will send data to the server.
  - The directory with which the user will perform tasks on.
- Task sets
  - We will have `N` tasks for each user:
  - The first `N/2` tasks will be logged as `1_n` where `n` is the task number
    in the set.
  - The second `N/2` tasks will be logged as `2_n` where `n` is the task number
    in the set.
  - The client will decide how the tasks will be ordered.

## Implementation
### Server side
### Experiment data directory
This directory will hold all data collected from each experiment that was run.
It will have a rough structure of:
```
/
|__user1
|  |__log.csv
|  |__browser_hist.txt
|__user2k
|  |__log.csv
|  |__browser_hist.txt
|__user3
|__...

```

`log.csv` will have the following columns:
- task_no: the set_task number.
- treatment: T/NT for Tellina/No Tellina
- command: the command or a list of commands (separated with `;`) issued by
  the user.
- time (seconds): time in seconds the user took on a task
- status: `1` if the user succeeded, `2` if the user ran out of time, `0` if the
  user abandoned the task.

`browser_hist.txt` will be a plain text file with links of all websites accessed
by the user during the experiment.

### Server application
There will be a simple Flask application managing the data directory.

The app will handle the following requests from the client:
- `create_user()`:
  - Route: `/methods/create_user`, methods: `POST`
  - Expected request:
    ```
    POST /methods/create_user
    Host: host
    Content-Type: application/x-www-form-urlencoded
    Content-Length: ...

    user_id=user_id
    ```
  - Creates a new user directory `user_id` and the CSV file associated to the
    user.
  - Respond with the `user_id` and the success code.
- `get_user_route(user_id)`
  - Route: `/methods/get_user_route`, methods: `GET`
  - Expected request:
    ```
    GET /methods/get_user_route?user_id=user_id
    ```
  - Returns the route for `user_id`.
  - If route not found then return a 404.
- `task_order()`
  - Route: `/methods/task_order`, methods: `POST`
  - Identify which task set ordering needs to be attributed to a user based on
    current distribution of task set ordering.
  - We will have 4 task orderings, with `s1, s2` as task set 1 and 2, and `T,
    NT` for Tellina and No Tellina
    ||1st|2nd|
    |-|-|-|
    |1|`s1 T`|`s2 NT`|
    |2|`s2 T`|`s1 NT`|
    |3|`s1 NT`|`s2 T`|
    |4|`s2 NT`|`s1 T`|
  - The method will choose the task ordering with the lowest number of samples,
    and at random if there are ties.
- `write_log(user_id)`:
  - Route: `/user/<user_id>/log`, methods: `POST`
  - Expected request:
    ```
    POST /user/<user_id>
    Host: host
    Content-Type: application/x-www-form-urlencoded
    Content-Length: ...

    key1=value1&key2=value2&...
    ```
  - The keys that are accepted are: `task_no`, `treatment`, `command`, `time`,
    `status`.
  - The method will update each field accordingly in the user's CSV file.
- `write_browser_hist(user_id)`:
  - Route: `/user/<user_id>/browser`, methods: `POST`
  - Expected request:
    ```
    POST /user/<user_id>
    Host: host
    Content-Type: multipart/form-data
    Content-Length: ...

    data
    ```
  - This method takes in a file with the user's browsing history

### Client side
#### Setting Up
#### Communication With Server
#### Tracking Browsing History
#### Tracking Bash History
#### Task Interface
- Mock File System
  - Reset
  - Output verification
- Tutorial
- Time limit
- Abandon
- Command limits

## Risks and Concerns
- Scalability.
- User file system safety.
- Enforcement of logging tool (specifically browser history logging).

## Acknowledgements
- Some of the code used for the infrastructure was imported and modified from
  the following git repos:
  - TellinaTool/bash_task_interface.git
  - TellinaTool/user_study_chrome_extension.git
  - TellinaTool/resource-website.git


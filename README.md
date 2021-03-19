[![Build Status](https://travis-ci.com/TellinaTool/tellina_user_experiment.svg?branch=master)](https://travis-ci.com/TellinaTool/tellina_user_experiment)
# Tellina User Experiment
Tellina is a natural language -> command translation tool. Tellina accepts a natural language description of file system operations and displays a ranked list of bash one-liner suggestions made by the model. The user can scroll down the web page to explore more suggestions. http://tellina.rocks/

This repository contains the infrastructure for formally conducting user experiments for Tellina.

- [**server_side**](https://github.com/TellinaTool/tellina_user_experiment/tree/master/client_side): contains the files to be distributed to the users of the experiment.
- [**client_side**](https://github.com/TellinaTool/tellina_user_experiment/tree/master/server_side): contains the code used for the server side of the experiment, this includes both the post handler and the post-processor.
- [**data_set**](https://github.com/TellinaTool/tellina_user_experiment/tree/master/dataset): contains the scripts used to produce the data set for the user experiment (referenced as _taskset_).
- [**infrastructure.md**](https://github.com/TellinaTool/tellina_user_experiment/blob/master/infrastructure.md): describes the technical infrastructure and implementation of the user experiment.


## Creating a new host

1. Clone the repository locally
2. Update the Makefile in the local repo with the intended `HOST` and `HOST_DIR`.
3. Update `SERVER_HOST` in `client_side/.infrastructure/setup.sh` with the new host.
4. Update `client_side/README.txt` with the new host.
3. Create `HOST_DIR` on `HOST`, and clone the repository into `HOST_DIR`.

    a. Rename `HOST_DIR/repo-name` to `DIST_NAME` (the directory name for the repository on `HOST` should match `DIST_NAME` in the local repo)
4. (Optional) Create a `HOST_DIR/staging` and repeat step 3 there if you would like to have a testing website.
5. Run  `make all publish-distribution`
6. Update the permission of `$HOST/$HOST_DIR/server_side/log.csv` with `chmod 666 log.csv`

Once a new host has been created, the link in `telina_user_experiment/client_side/README.md` can be updated to wherever the new site is.

## Distributing the experiment

To distribute the files, run `make` or `make all`. This will run all tests and create the `.zip` file for distribution at the root of this folder.
  - The `DIST_NAME` variable in the [Makefile](Makefile) specifies the name of the `.zip` file that will be created.
  - The structure of the experiment archive is specified in [the experiment design doc](experiment_design_doc.md#directory-structure).

### Requirements
- [Bats](https://github.com/bats-core/bats-core)
- [zip](https://linux.die.net/man/1/zip) (if it's not already installed on your system)

## Previously
In a past experiment, people were given descriptions of file system operations, and asked to write bash commands to perform the operations.  The experimental group had access to Tellina, web search, and man pages; the control group had access only to web search and man pages. Measurements were done on whether subjects successfully complete the tasks, and the amount of time that it takes to complete the tasks. A post-task questionnaire obtained qualitative feedback.

We need to redo the experiment, for a few reasons.
1. Tellina has changed since the user study was performed.  Tellina has better
   accuracy and handles more commands.  It would not be compelling to report an
   experiment on an implementation that has since been superseded.
2. The user study was relatively small (around 30 subjects), so the experimental
   results were not always statistically significant.  With a larger pool of
   subjects, the results will be more compelling.
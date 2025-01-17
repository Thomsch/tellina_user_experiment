#!/bin/bash
# This script takes 1 argument which is the absolute path to the user experiment
# directory.

# Automatically export any assigned variables
set -a

# Use this variable when preventing the user from seeing stderr/stdout.
# For example, pushd path/to/dir &>> $INF_LOG_FILE
# instead of pushd path/to/dir &> /dev/null.
INF_LOG_FILE=/tmp/tellina_infrastructure.log

# Checks if the user has a usable graphical display. X forwarding counts.
if ! xhost &>> ${INF_LOG_FILE}; then
  echo "No display detected. Please run the experiment in"
  echo "an environment with a graphical display."
  return 1
fi
if ! which meld &>> ${INF_LOG_FILE}; then
  echo "The program Meld is not installed. Please install it with"
  echo "sudo yum -qy install meld"
  return 1
fi

################################################################################
#                              CONSTANT DEFINITIONS                            #
################################################################################

### Experiment configuration

TASK_TIME_LIMIT=360 # In seconds
TASK_SET_TIME_LIMIT=$(( 25 * 60 )) # In seconds

# Establish the server information
SERVER_HOST="https://homes.cs.washington.edu"
# Establish survey URL
EXPERIMENT_HOME_URL="${SERVER_HOST}/~tschweiz/research/en2bash-study"

POST_HANDLER="${EXPERIMENT_HOME_URL}/backend/post_handler/post_handler.php"

TELLINA_WEBSITE="http://kirin.cs.washington.edu:8888/"
INSTRUCTION_WEBSITE="https://bit.ly/en2bash-instructions" #https://homes.cs.washington.edu/~tschweiz/research/en2bash-study/instructions.html

### Infrastructure

# The absolute path to the user experiment directory
EXP_DIR="$1"
# The absolute path to the experiment's infrastructure directory
INFRA_DIR="${EXP_DIR}/$(dirname ${BASH_SOURCE[0]})"

# Enables infrastructure functions.
source "${INFRA_DIR}"/infrastructure.sh

### Directories

TASKS_DIR="${INFRA_DIR}/tasks"

# The directory the user will perform tasks on
FS_DIR="${EXP_DIR}/file_system"

# The directory used by the infrastructure to reset FS_DIR.
FS_SYNC_DIR="${INFRA_DIR}/file_system"

# Contains output of user commands.
USER_OUT="${INFRA_DIR}/user_out"
mkdir -p "${USER_OUT}"

# Contains actual and expected output files for comparison.
TMP_DIFF="${INFRA_DIR}/tmp_diff"
mkdir -p "${TMP_DIFF}"

# Magic string to trigger the 'expected command'
MAGIC_STRING_EXPECTED_COMMAND="MAGIC_STRING_EXPECTED_COMMAND"

### Task-related variables

# The TASK_ORDER is two two-character codes.  In each two-character code, the
# letter T/N is for Tellina/NoTellina, and the number indicates the task_set
# used.
TASK_ORDERS_CODES=("T1N2" "T2N1" "N1T2" "N2T1")

# Training information
# Make sure that GENERAL_START_CODE + GENERAL_TRAINING_SIZE is always smaller than TELLINA_START_CODE
# otherwise you will reuse training tasks in both.
# Example: 'v' + 3 => 'x' (there is 3 letters v, w, x) and TELLINA_START_CODE = 'y' is fine! 'x' < 'y'
GENERAL_TRAINING_SIZE=3
GENERAL_START_CODE="v"
TELLINA_TRAINING_SIZE=2
TELLINA_START_CODE="y"
TRAINING_SIZE=$((GENERAL_TRAINING_SIZE + TELLINA_TRAINING_SIZE))

# Note: The infrastructure currently does not support odd TASK_SIZE due to
# integer division creating difficulties for splitting up the task sets.
TASKS_SIZE=$(ls -1 "${TASKS_DIR}" | wc -l)
TASKS_SIZE=$(( TASKS_SIZE - TRAINING_SIZE )) # reserve the two final tasks for training.

# If a task_num file already exists, it means we are trying to resume the
# experiment.
if [[ -f "${INFRA_DIR}/.task_num" ]]; then
  task_num=$(cat "${INFRA_DIR}/.task_num")

  # The initial task_num will be incremented by one in start_experiment, if the
  # experiment is being recovered from the middle, the initial task_num needs to
  # be one lower to allow the user to start at the task where they previously
  # stopped.
  task_num=$((task_num - 1))
  is_recovery=1
else
  task_num=0
  is_recovery=0
fi

### User meta-commands
SLINE="================================================================================"
HLINE="--------------------------------------------------------------------------------"

# Each user meta-command will create a file called .noverify in the
# infrastructure directory.

# skip writes "skip" to `.noverify`.
# This is because aliases can't set variables and skip needs to set $status
# to "skip". precmd_func checks the contents.
alias skip='echo "skip" > ${INFRA_DIR}/.noverify; touch "${INFRA_DIR}/.noprint"'
alias helpme='show_help; touch ${INFRA_DIR}/.noverify'
alias expected='show_expected; touch ${INFRA_DIR}/.noverify'

show_help() {
  echo "--- Help -----------------------------------------------------------------------";
  echo "Available commands:";
  echo "expected    shows a diff between the initial file system and the expected";
  echo "            filesystem.";
  echo "skip        gives up on the current task and starts the next task.";
  echo "helpme      prints this help message.";
  echo ""
}

trap "" SIGINT # Prevents interruption by ctrl-c or cmd-c for the experiment.

### Greet the participant
echo "${SLINE}"
if (( is_recovery == 1 )); then
  echo "Welcome back!"
  echo "The experiment will resume where you left."

  UW_NETID="$(cat "${INFRA_DIR}/.netid")"
  TASK_ORDER="$(cat "${INFRA_DIR}/.task_order")"
else
  echo "Welcome to the user study! Thank you for choosing to participate!"
  echo ""
  echo "This terminal will be the main interface for the experiment."
  echo ""

  # Read non-empty UW NETID.
  while read -p "Please enter your UW NetID: " UW_NETID; do
    if [ ! -z $UW_NETID ]; then
        break
    fi
  done

  # Determine the task order based on a truncated md5sum hash of the username.
  # The has will return a number from 0 to 3.
  TASK_ORDER=${TASK_ORDERS_CODES[$((0x$(md5sum <<<${UW_NETID} | cut -c1) % 4))]}
  #TASK_ORDER=${TASK_ORDERS_CODES[$((RANDOM % 4))]}

  echo "${UW_NETID}" > "${INFRA_DIR}/.netid"
  echo "${TASK_ORDER}" > "${INFRA_DIR}/.task_order"
fi

echo ""

################################################################################
#                                  BASH PREEXEC                                #
################################################################################

# Saves the old value of PROMPT_COMMAND, since Bash Preexec overwrites it.
PROMPT_COMMAND_ORIG=${PROMPT_COMMAND}

# Install Bash preexec.
source "${INFRA_DIR}"/bash-preexec.sh

# Executed before the user-entered command is executed.
# Saves the command that was just entered by the user (and is about to be
# executed) into the .command file.
#
# If the user enters an empty command, then the .command file does not change.
# preexec_func gets the most recent command from $PROMPT_COMMAND, which does
# not change when the most recently entered command is blank.
preexec_func() {
  command_dir=$PWD
  echo "$1" > "${INFRA_DIR}/.command"

  # Save elapsed time for the current taskset in case we need to recover.
  if [ ! -z ${taskset_timestamp_start+x} ]; then
    taskset_timestamp_end=$(date +%s)
    task_set_time_elapsed=$(( taskset_timestamp_end - taskset_timestamp_start))
    echo "${task_set_time_elapsed}" > "${INFRA_DIR}/.taskset_elapsed"
  fi

}

# Shows expected result for the current task.
show_expected() {
  echo "Showing expected one-liner result..."

  pkill meld 2>> ${INF_LOG_FILE}

  "${INFRA_DIR}"/verify_task.py ${task_code} "${command_dir}" "${MAGIC_STRING_EXPECTED_COMMAND}"

  (meld "${TMP_DIFF}/actual" "${TMP_DIFF}/expected" &)
}

# Executed after the user-entered command is executed.
#
# This function sets $status to one of "timeout", "success",
# "incomplete", or "skip".
# This is based on:
#  * whether the user has run out of time, and
#  * verifying the output of the user command unless it was a meta-command.
#
# If the status is not "incomplete", move on to the next task.
#
# This function always writes to the log.
precmd_func() {
  time_elapsed=${SECONDS}
  taskset_timestamp_end=$(date +%s)

  local user_command="$(cat "${INFRA_DIR}/.command")"

  # Ignore exploratory commands from verification
  if [[ ! $user_command =~ \| ]]; then
      if [[ $user_command =~ ^man[[:space:]]* ]] || [[ $user_command =~ ^ls[[:space:]]* ]]; then
        touch "${INFRA_DIR}/.noverify"
      fi
  fi

  task_set_time_elapsed=$(( taskset_timestamp_end - taskset_timestamp_start))

  # Checks if the participant hasn't ran out of time for the current taskset
  if [ ! -z ${taskset_timestamp_start+x} ] && (( task_set_time_elapsed >= TASK_SET_TIME_LIMIT )) ; then
    verify_task "${command_dir}" "disable-meld";
    echo ""
    echo "The time allocated for half ${experiment_half} of the experiment is over."
    echo "Please follow the new instructions below."
    echo ""

    status="set-timeout"
    unset taskset_timestamp_start

    # Move task to the start of next half or end.
    if (( task_num <= TASKS_SIZE / 2 )) ; then
      task_num=$(( TASKS_SIZE / 2 ))
    else
      task_num=${TASKS_SIZE}
    fi

  # Checks if the user has run out of time.
  elif (( time_elapsed >= TASK_TIME_LIMIT )) && [[ "${INF_TRAINING:-false}" == "false" && "${TEL_TRAINING:-false}" == "false" ]] ; then
    verify_task "${command_dir}" "disable-meld";

    echo "You have run out of time for task ${task_num}."

    status="timeout"
    # If they have, $time_elapsed is truncated to the time limit.
    time_elapsed=${TIME_LIMIT}
  elif [[ -f "${INFRA_DIR}/.noverify" ]]; then
    # Output verification should not be run.
    # This can happen if the user entered a user meta-command or at the
    # beginning of the experiment.

    # If the .noverify file has "skip" in it, then the user used the
    # "skip" meta-command.
    if [[ "$(cat "${INFRA_DIR}/.noverify")" == "skip" ]]; then
      status="skip"
    fi

    rm "${INFRA_DIR}/.noverify"
  else
    # 1. Kills any old instances of Meld that hasn't already been closed.
    # 2. Verify the command inside of .command.
    # 3. Open Meld if the exit code is non-zero.
    pkill meld 2>> ${INF_LOG_FILE}
    if ! verify_task "${command_dir}"; then
      # Starting a background task in a subshell silences the job ID and PID
      # output.
      (meld "${TMP_DIFF}/actual" "${TMP_DIFF}/expected" &)
    fi
  fi

  # Disables skip while in training.
  if [[ "${INF_TRAINING:-false}" == "true" ]] || \
     [[ "${TEL_TRAINING:-false}" == "true" ]]; then
    if [[ "${status}" != "success" ]]; then
      if [[ "${status}" == "skip" ]]; then
        echo "Skipping is disabled during training."
      fi
      status="incomplete"
    fi
  fi

  write_log
  cd ${FS_DIR} # Resets the working directory in case it has been changed.

  if [[ "${status}" == "skip" ]] || \
     [[ "${status}" == "timeout" ]] || \
     [[ "${status}" == "set-timeout" ]] || \
     [[ "${status}" == "success" ]]; then
    next_task
  elif [[ -f "${INFRA_DIR}/.noprint" ]]; then
    rm "${INFRA_DIR}/.noprint"
  else
    print_task
  fi
}

start_experiment
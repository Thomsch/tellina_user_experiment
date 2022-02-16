#!/bin/bash

##############################################################################
# This file contains utility functions for use by the interface:
# - Creating the file system for the user.
# - Timing each task.
# - Determine task and treatment ordering for the current experiment.
# - Determine the next task to move onto and whether the experiment is over.
# - Verify the output of a task.
##############################################################################

# Enables Bash preexec functions, prints out the first treatment and task, and
# starts the first task.
#
# This function is only called at the very beginning of the experiment.
start_experiment() {
  # Enable task logging
  preexec_functions+=(preexec_func)
  precmd_functions+=(precmd_func)

  echo "=== Description ================================================================"
  echo "In this study, you will be presented with 12 short tasks in Bash."
  echo "For example: Show the number of lines in file foo.txt."
  echo ""
  echo "We ask you to try to solve each task with a Bash one-liner."
  echo "For example: cat foo.txt | wc -l"
  echo ""
  echo "The experiment is divided in two parts of 6 tasks each. Each part will have"
  echo "instructions describing the tools you can use."
  echo ""

    # Show these instructions if this is not a recovery.
    if (( is_recovery != 1 )); then
      echo "Before starting the first task, you will get familiar with the"
      echo "experiment's terminal and commands through a brief training."
      echo ""
      read -n 1 -s -r -p "Press any key to start the training..."
      echo ""
    fi
    echo ""

  begin_treatment 1
  next_task

  # Because precmd is enabled by this function, precmd will be invoked before
  # the next command line prompt.
  # ".noverify" is touched so that precmd does not attempt to verify
  # ".noprint" is touched so that precmd does not attempt to verify
  # user output on the "start_task" command that was written to `.command`.
  touch "${INFRA_DIR}/.noverify"
  touch "${INFRA_DIR}/.noprint"
}

# Prints guide for the general training.
general_training() {
  echo ""
  echo "=== Training ==================================================================="
  echo "For each task in this experiment, please write a Bash one-liner in this terminal"
  echo "that satisfies the task's prompt."
  echo ""
  echo "-> If your one-liner solves the task, you will be directed to the next task."
  echo "-> If your one-liner is incorrect, a GUI window will pop up to show you the"
  echo "  difference between your output and the expected output."
  echo ""
  echo "- You can retry as many times as you like, within a 6-minute deadline."
  echo "- Please note that the working directory is reset between attempts. This means"
  echo "  you cannot solve a task using multiple commands at the command line; you must"
  echo "  use a bash one-liner to combine all the operations you wish to perform."
  echo ""
  echo "- You can use the 'expected' command to show the expected results for this task."
  echo ""
  echo "- You can use 'ls' and 'man' to explore the experiment's file system or "
  echo "  look up information about a command directly in the terminal without having"
  echo "  the Meld window appearing."
  echo ""
  echo "- If your command hangs, please use Ctrl+D terminate it."
  echo ""
  echo "- Please stay in the current directory. That is, do not use commands such"
  echo "  as 'cd' or 'pushd' to change the working directory."
  echo ""
  read -n 1 -s -r -p "Press any key to continue..."
  echo ""
  echo ""
  echo "At any time, you can type 'helpme' to print the available commands to help you."
  echo "Let's give it a try:"

  while read -p "Please type 'helpme' (without the apostrophes):" type_helpme; do
    if [[ $type_helpme == "helpme" ]]; then
        echo ""
        show_help;
        break;
    fi
  done

  echo "Please take an instant to read the description of the available commands."
  echo ""
  read -n 1 -s -r -p "When you're ready to continue, press any key..."
  echo ""
  echo ""
  echo "Let's practice! Try to solve the ${GENERAL_TRAINING_SIZE} training tasks below."
  echo "- See what happens when you enter an incorrect command (e.g., 'mkdir test')"
  echo "  -> You should see the diff window pop-up showing actual / expected output."
  echo ""
  echo "- See what happens when you enter the right command (you can use any"
  echo "  resource you want)."
  echo "  -> You will proceed to the first part of the experiment!"
  echo ""
}

# Introduces the user to Tellina and suggests a couple of known query-command
# pairs.
tellina_training() {
  echo ""
  echo "=== Tellina training ==========================================================="
  echo "In this experiment, we are asking you to try out Tellina, a novel tool that"
  echo "helps developers write Bash one-liners."
  echo ""
  echo "Tellina takes in the description of what you want to in English and"
  echo "returns corresponding Bash one-liners."
  echo ""
  echo "For example, given the sentence: "
  echo "   'Remove all pdf files in my current directory'"
  echo ""
  echo "Tellina will return "
  echo "   'find . -name '*.pdf' -exec rm {} \;'"
  echo "which does indeed delete all pdf files in the current directory."
  echo ""
  read -n 1 -s -r -p "Press any key to continue..."
  echo ""
  echo ""
  echo "We would like for you to consider using Tellina for CERTAIN tasks"
  echo "in this experiment (for some tasks, we will ask you to NOT use Tellina."
  echo ""
  echo "Please visit ${TELLINA_WEBSITE}"
  echo "to access Tellina."
  echo ""
  echo "- Get acquainted with the website's interface."
  echo "  -> There are three main sections: 'The top search bar', 'Sample Questions',"
  echo "     and 'Tips'. "
  echo ""
  read -n 1 -s -r -p "Press any key to continue..."
  echo ""
  echo ""
  echo "- Take a closer look at the top search bar"
  echo "  -> The search bar allows you to write a query in English. "
  echo "  -> The button on the right submits the query to Tellina."
  echo "  -> The button on the left searches the query on Google."
  echo ""
  echo "- 'Sample Questions' contains pairs of query and bash one-liner examples."
  echo ""
  echo "- MAKE SURE to read the 'Tips' section; it describes how to best use Tellina"
  echo "  and what to account for."
  echo ""
  echo "- Tellina works best on simple sentences. For this reason we suggest avoiding"
  echo "  copy-pasting the task prompts directly into the search bar."
  echo "  Try instead to rephrase what you want to do in smaller sentences"
  echo "  for each part of the task you want to achieve."
  echo ""
  read -n 1 -s -r -p "Press any key to continue..."
  echo ""
  echo ""
  echo "- Try to submit one of the queries in the Sample Questions."
  echo "  -> Notice how Tellina gives you a list of Bash one-liners it thinks are the"
  echo "     most relevant."
  echo "  -> Notice how the Bash one-liners might require some slight tweaking compared"
  echo "     to the reference Bash one-liner for the query you choose from the samples."
  echo ""
  echo "- Please note that Tellina is not always completely right. You might need to"
  echo "  tweak its answers to fit your use-case."
  echo ""
  echo "- Feel free to try out a few more queries!"
  echo ""
  echo "- Time for practice! Try to solve the ${TELLINA_TRAINING_SIZE} training tasks below with"
  echo "  the help of Tellina."
  echo ""
}

# Prints the list of resources that the user is allowed to use based on the
# current treatment.
print_treatment() {
  echo "=== Part ${experiment_half}/2 ==================================================================="
  echo ""
  echo "Instructions for this half of the experiment (read carefully):"
  echo "- You CAN use any online resources and man pages."
  if [[ "$treatment" == "T" ]]; then
    echo "- You CAN use Tellina (${TELLINA_WEBSITE})"
  else
    if (( task_num >= TASKS_SIZE / 2 + 1 )); then
      echo "- You MUST NOT use Tellina."
    fi
  fi

  echo ""
  echo "Remember:"
  echo "- You can run \"helpme\" to see the list of commands available."
  echo "- Please stay in the current directory."
  echo "- You have a 6-minute limit per task. Take your time!"
  echo ""
  read -n 1 -s -r -p "Press any key to start this part..."
  echo ""
  echo ""
}

# Updates the states and training status when switching treatment.
#
# Parameters:
# $1: the half of the experiment to begin treatment for, can be 1 or 2.
begin_treatment() {
  # Sets the current treatment and task set based on the task ordering for the
  # experiment.
  experiment_half=$1

  # Override experiment half if we're in experiment recovery.
  if (( is_recovery == 1 )) && (( task_num >= TASKS_SIZE / 2 )); then
    experiment_half=2
  fi

  if (( ${experiment_half} == 1 )); then
    treatment="${TASK_ORDER:0:1}"
    task_set=${TASK_ORDER:1:1}
  else # (experiment_half == 2)
    treatment="${TASK_ORDER:2:1}"
    task_set=${TASK_ORDER:3:1}
  fi

  # If it's the first task, we enable the general training, except if we are recovering the experiment.
  if (( task_num == 0 )) && (( is_recovery != 1 )); then
      INF_TRAINING=true
      general_training_num=0
  fi

  # If the treatment is T, enables Tellina training, except if we are recovering the experiment.
  if [[ "$treatment" == "T" ]] && (( is_recovery != 1 )); then
      TEL_TRAINING=true
      tellina_training_num=0
  fi
}
# Controls when treatment is changed, end of experiment, and training. 
# Increments the current task number and either starts a new task
# If the user is in training, the current task number does not increment.
next_task() {

  # If done with all the tasks, end the experiment
  if (( task_num == TASKS_SIZE )); then
    end_experiment
    return 0
  fi

  # Verify if a training has been completed.
  check_and_update_training_status

  # Check if we need to switch the task set and the treatment
  if (( task_num == TASKS_SIZE / 2 )) && [[ "${TEL_TRAINING:-false}" == "false" ]] && [[ "${task_code}" != $(get_training_code ${TELLINA_START_CODE} ${TELLINA_TRAINING_SIZE}) ]] && (( is_recovery != 1 )); then
    echo ${SLINE}
    echo "Way to go! You have finished the first half of the experiment!"
    echo ""
    begin_treatment 2
  fi

  if [[ "${TEL_TRAINING:-false}" != "true" ]] && \
    [[ "${INF_TRAINING:-false}" != "true" ]]; then
    # Increment the number of tasks finished by the user.
    task_num=$(( task_num + 1 ))
    echo "${task_num}" > "${INFRA_DIR}/.task_num"
  fi

  # Selects the next task code. "task_u" for infrastructure training, "task_v" for Tellina
  # training, or calculate the task_code from the current_task and task_set if not a training task.
  if [[ ${INF_TRAINING:-false} == "true" ]]; then

    # Only show training instructions for the first training task.
    if (( general_training_num == 0 )); then
      general_training
    fi

    general_training_num=$(( general_training_num + 1 ))
    task_code=$(get_training_code ${GENERAL_START_CODE} ${general_training_num})
    
  elif [[ ${TEL_TRAINING:-false} == "true" ]]; then

    if (( tellina_training_num == 0 )); then
      tellina_training
    fi
    
    tellina_training_num=$(( tellina_training_num + 1 ))
    task_code=$(get_training_code ${TELLINA_START_CODE} ${tellina_training_num})

  else
    task_code=$(get_task_code)

    if (( task_num == 1 )) || (( task_num == ( TASKS_SIZE / 2 ) + 1 )) || (( is_recovery == 1 )); then
      print_treatment
      is_recovery=0
      taskset_timestamp_start=$(date +%s) # Count in seconds
    fi 
  fi

  status="incomplete"

  start_task
  write_log
}

# This is called to start the user on a new task.
#
# Restores the file system and sets the variables.
# Writes "start task" to `.command`.
# Prints the description of the current task.
start_task() {
  reset_fs
  cd ${FS_DIR}

  SECONDS=0
  time_elapsed=0

  echo "start_task" > "${INFRA_DIR}/.command"

  print_task
}

# Disable training if completed. Prioritizes infrastructure training.
check_and_update_training_status() {
  if [[ "${INF_TRAINING:-false}" == "true" ]] && ((general_training_num == GENERAL_TRAINING_SIZE)); then
    if [[ "${status}" == "success" ]]; then
      # If the user successfully did the infrastructure training, disables it.
      unset INF_TRAINING
    fi
  elif [[ "${TEL_TRAINING:-false}" == "true" ]] && ((tellina_training_num == TELLINA_TRAINING_SIZE)); then
    if [[ "${status}" == "success" ]]; then
      # if the user successfully did the Tellina training, disables it.
      unset TEL_TRAINING
    fi
  fi
}

# Prints the current task number and its description. Prints a special header if this is a training task.
print_task() {
  echo ${HLINE}

  if [[ "${INF_TRAINING}" == "true" ]]; then
    echo "> Training ${general_training_num}/${GENERAL_TRAINING_SIZE} <"
  elif [[ "${TEL_TRAINING}" == "true" ]]; then
    echo "> Training ${tellina_training_num}/${TELLINA_TRAINING_SIZE} <"
  else
    local half_tasks_size=$((TASKS_SIZE / 2))
    local local_task_num=$(((( task_num - 1 ) % half_tasks_size ) + 1))
    echo "Task: ${local_task_num}/${half_tasks_size}"
  fi

  ${INFRA_DIR}/jq-linux64 -r '.description' \
    "${TASKS_DIR}/task_${task_code}/task_${task_code}.json"
}

# See documentation for ./verify_task.py for more details on what it does.
#
# Parameters:
# - $1: the directory that the user command was run in.
#
# Runs ./verify_task.py with the global task_code and the command in .command
# and captures its exit code.
#
# If ./verify_task.py returns exit code:
# - 0: sets $status to success.
# - 2: prints a prompt warning that the user has changed the file system and
#      resets the file system.
# - Otherwise: prints a prompt that the actual output does not match.
#
# Returns the exit code of ./verify_task.py
verify_task() {
  # Verify the output of the previous command.
  local exit_code
  local user_command="$(cat "${INFRA_DIR}/.command")"

  "${INFRA_DIR}"/verify_task.py ${task_code} "$1" ${user_command}
  exit_code=$?

  case $exit_code in
    0)
      status="success"
      ;;
    1)
      echo "File system does not match expected. A diff has been shown."
      reset_fs
      ;;
    2)
      echo "You have modified the file system. It will now be reset to its original state."
      reset_fs
      ;;
    3)
      echo "Command output does not match expected output. A diff has been shown."
      ;;
  esac

  return $exit_code
}



# Writes the command in `.command` to the log file on the server with a POST
# request.
write_log() {
  curl -s -X POST ${POST_HANDLER} \
    -d client_time_stamp="$(date --utc +%FT%TZ)" \
    -d user_id="$UW_NETID" \
    -d task_order="$TASK_ORDER" \
    -d task_code="$task_code" \
    -d treatment="$treatment" \
    -d time_elapsed="$time_elapsed" \
    -d status="$status" \
    -d command="$(cat "${INFRA_DIR}/.command")" &>> ${INF_LOG_FILE}
}

# "Uninstalls" Bash Preexec by removing its triggers.
# Remove all variable files created by the infrastructure.
# Stops the experiment completely by returning from the sourced scripts.
end_experiment() {
  # This effectively uninstalls Bash Pre-exec.
  # Makes it so any commands typed after the experiment has ended will not be
  # passed through preexec and precmd.
  PROMPT_COMMAND=${PROMPT_COMMAND_OG}
  trap - DEBUG

  # Remove all variable files.
  find ${INFRA_DIR} -type f -name ".*" -delete
  cd "${EXP_DIR}"

  echo ${SLINE}
  echo "Congratulations! You have completed the interactive portion of the experiment."
  echo "Please fill out a <5 minute survey at https://forms.gle/xjAqf1YrvfKMZunL8 ."
  echo ""
  echo "Thank you for your participation!"

  return 0
}

# Prints to stdout the character with the given numeric ASCII value.
#
# Exit status:
# - 0 if the passed value is within 0...256.  (And does no output.)
# - 1 otherwise.
chr() {
  [ "$1" -gt 0 ] && [ "$1" -lt 256 ] || return 1
  printf "\\$(printf '%03o' "$1")"
}

# Prints to stdout the numeric ASCII value of the given character.
ord() {
  LC_CTYPE=C printf '%d' "'$1"
}

# Prints the nth alphabetic character. n is 1-based; that is, char_from(1) is
# "a".
# $1: the number n specifying which character.
char_from() {
  local num_a=$(ord "a")
  local num_fr=$((num_a + $1 - 1))

  echo $(chr ${num_fr})
}

# Gets the code for the training task.
# $1: The first training task's code
# $2: The number of the current training task (1-indexed)
# Example: 
#   get_training_code 'v' 1 => 'v' # First task code for training set starting at 'v' is 'v'
#   get_training_code 'v' 2 => 'w' # Second task code for training set starting at 'v' is 'w'
get_training_code() {
  local num_initial=$(ord $1) # First general training task
  local code=$((num_initial + $2 - 1))
  echo $(chr ${code})
}

# Prints the true task code, from the current user task number and task set.
# The user task numbering is always sequential.
#
# The user task number is the global variable task_num.
# The task set is the global variable task_set (either 1 or 2).
# Task set 1 contains tasks 1 through TASK_SIZE / 2.
# Task set 2 contains tasks (TASK_SIZE / 2) + 1 through TASK_SIZE.
#
# Example:  with TASK_SIZE == 22, task_set == 1, and task_num == 12, the output
# will be "a".
get_task_code() {
  if ((task_set == 1)); then
    local task_no=$((task_num > TASKS_SIZE / 2 ? \
      task_num - TASKS_SIZE / 2 : \
      task_num))
  else
    local task_no=$((task_num > TASKS_SIZE / 2 ? \
      task_num : \
      task_num + TASKS_SIZE / 2))
  fi


  echo "$(char_from ${task_no})"
}

# Resets the user's file system directory by syncing it with the
# infrastructure's file system directory.
reset_fs() {
  rsync --exclude=".*" --omit-dir-times --recursive --quiet --delete \
    --times \
    "${FS_SYNC_DIR}/" "${FS_DIR}"
}

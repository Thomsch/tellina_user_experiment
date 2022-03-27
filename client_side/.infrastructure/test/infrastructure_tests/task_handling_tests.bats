#!/usr/bin/env bats
load ../libs/setup

@test "start_task resets time variables" {
  local SLEEP_TIME=3
  local ACCEPTABLE_TIME=$((SLEEP_TIME / 2))
  local time_elapsed=$SECONDS
  local task_code='a'
  SECONDS=0

  sleep $SLEEP_TIME

  start_task

  [[ $SECONDS -lt $ACCEPTABLE_TIME ]]
  assert_output "$time_elapsed" 0
}

@test "next_task sets correct log information" {
  local TASKS_SIZE=10
  local task_num=0
  local task_set=1
  local status command task_code

  set +e
  next_task <<< "k"
  set -e

  command=$(cat "${INFRA_DIR}/.command")

  assert_output "$status" "incomplete"
  assert_output "$command" "start_task"
  assert_output "$task_code" "a"
}

@test "next_task increments task_num" {
  local task_num=0

  # Write log will fail because we don't have a URL for curl
  set +e
  next_task <<< "k"
  set -e

  assert_output "$task_num" 1

  task_num=$(cat "${INFRA_DIR}/.task_num")
  assert_output "$task_num" 1
}

@test "next_task resets the file system directory" {
  local task_num=0

  set +e
  next_task <<< "k"
  set -e

  assert_output "$task_num" 1
  run find ${fs_dir} -type f
  [[ -n "$output" ]]

  find ${FS_DIR} -type f -delete

  run find ${FS_DIR} -type f
  assert_output "$output" ""

  set +e
  next_task
  set -e

  assert_output "$task_num" 2
  run find ${fs_dir} -type f
  [[ -n "$output" ]]
}

@test "next_task ends experiment" {
  local TASKS_SIZE=10
  local task_num=10

  run next_task

  assert_success
}

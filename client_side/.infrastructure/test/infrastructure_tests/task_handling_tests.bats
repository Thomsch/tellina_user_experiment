#!/usr/bin/env bats
load ../libs/setup

@test "begin_treatment correct for first half of experiment" {
  # Parameters for test_set_task_set is in the order:
  # <TASK_ORDER> <EXPERIMENT_HALF> <EXPECTED_TREATMENT> <EXPECTED_TASK_SET>

  test_begin_treatment "T1N2" 1 "T" 1
  test_begin_treatment "T2N1" 1 "T" 2
  test_begin_treatment "N1T2" 1 "N" 1
  test_begin_treatment "N2T1" 1 "N" 2
}

@test "begin_treatment correct for second half of experiment" {
  # Parameters for test_set_task_set is in the order:
  # <TASK_ORDER> <EXPERIMENT_HALF> <EXPECTED_TREATMENT> <EXPECTED_TASK_SET>

  test_begin_treatment "T1N2" 2 "N" 2
  test_begin_treatment "T2N1" 2 "N" 1
  test_begin_treatment "N1T2" 2 "T" 2
  test_begin_treatment "N2T1" 2 "T" 1
}

@test "start_task resets time variables" {
  local SLEEP_TIME=5
  local ACCEPTABLE_TIME=$((SLEEP_TIME / 2))
  local time_elapsed=$SECONDS
  SECONDS=0

  sleep $SLEEP_TIME

  start_task

  [[ $SECONDS -lt $ACCEPTABLE_TIME ]]
  assert_output "$time_elapsed" 0
}

@test "start_task sets correct log information" {
  local TASKS_SIZE=10
  local task_num=1
  local task_set=1
  local status command task_code

  start_task

  command=$(cat "${INFRA_DIR}/.command")

  assert_output "$status" "incomplete"
  assert_output "$command" "start_task"
  assert_output "$task_code" "a"
}

@test "start_task switches treatment" {
  local TASKS_SIZE=6
  local TASK_ORDER="T1N2"
  local task_num task_set time_elapsed status task_code treatment

  task_num=3
  begin_treatment 1

  INF_TRAINING=false
  TEL_TRAINING=false

  start_task

  assert_output "$treatment" "T"
  assert_output "$task_set" 1
  assert_output "$task_code" "c"

  task_num=4

  start_task

  assert_output "$treatment" "N"
  assert_output "$task_set" 2
  assert_output "$task_code" "d"
}

@test "next_task increments task_num" {
  local task_num=0

  # Write log will fail because we don't have a URL for curl
  set +e
  next_task
  set -e

  assert_output "$task_num" 1

  task_num=$(cat "${INFRA_DIR}/.task_num")
  assert_output "$task_num" 1
}

@test "next_task resets the file system directory" {
  local task_num=0

  set +e
  next_task
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
  local task_num=9

  run next_task

  assert_success
}

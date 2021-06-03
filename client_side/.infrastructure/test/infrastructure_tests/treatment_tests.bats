#!/usr/bin/env bats
load ../libs/setup

@test "start_task switches treatment T2N1" {
  local TASKS_SIZE=6
  local TASK_ORDER="T2N1"
  local task_num task_set time_elapsed status task_code treatment

  task_num=3
  begin_treatment 1

  INF_TRAINING=false
  TEL_TRAINING=false

  start_task

  assert_output "$treatment" "T"
  assert_output "$task_set" 2
  assert_output "$task_code" "f"

  task_num=4

  start_task

  assert_output "$treatment" "N"
  assert_output "$task_set" 1
  assert_output "$task_code" "a"
}

@test "start_task switches treatment T1N2" {
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
#!/usr/bin/env bats
load ../libs/setup

@test "next_task switches treatment N1T2" {
  local TASKS_SIZE=6
  local TASK_ORDER="N1T2"
  local task_num task_set time_elapsed status task_code treatment
  local TEL_TRAINING INF_TRAINING

  begin_treatment 1
  INF_TRAINING=""
  task_num=3
  task_code='c'

  set +e
  next_task
  set -e
  status="success"

  assert_output "$TEL_TRAINING" "true"
  assert_output "$treatment" "T"
  assert_output "$task_set" 2
  assert_output "$task_code" "v"
  assert_output "$task_num" 3

  set +e
  next_task
  set -e

  assert_output "$TEL_TRAINING" ""
  assert_output "$treatment" "T"
  assert_output "$task_set" 2
  assert_output "$task_code" "d"
  assert_output "$task_num" 4
}

@test "next_task switches treatment N2T1" {
  local TASKS_SIZE=6
  local TASK_ORDER="N2T1"
  local task_num task_set time_elapsed status task_code treatment
  local TEL_TRAINING INF_TRAINING

  begin_treatment 1
  INF_TRAINING=""
  task_num=3
  task_code='f'

  set +e
  next_task
  set -e
  status="success"

  assert_output "$TEL_TRAINING" "true"
  assert_output "$treatment" "T"
  assert_output "$task_set" 1
  assert_output "$task_code" "v"
  assert_output "$task_num" 3

  set +e
  next_task
  set -e

  assert_output "$TEL_TRAINING" ""
  assert_output "$treatment" "T"
  assert_output "$task_set" 1
  assert_output "$task_code" "a"
  assert_output "$task_num" 4
}

@test "next_task switches treatment T2N1" {
  local TASKS_SIZE=6
  local TASK_ORDER="T2N1"
  local task_num task_set time_elapsed status task_code treatment

  begin_treatment 1
  task_num=3
  task_code='f'

  INF_TRAINING=false
  TEL_TRAINING=false

  set +e
  next_task
  set -e

  assert_output "$treatment" "N"
  assert_output "$task_set" 1
  assert_output "$task_num" 4
  assert_output "$task_code" "a"
}

@test "next_task switches treatment T1N2" {
  local TASKS_SIZE=6
  local TASK_ORDER="T1N2"
  local task_num task_set time_elapsed status task_code treatment

  begin_treatment 1
  task_num=3
  task_code='c'

  INF_TRAINING=false
  TEL_TRAINING=false

  set +e
  next_task
  set -e

  assert_output "$treatment" "N"
  assert_output "$task_set" 2
  assert_output "$task_num" 4
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
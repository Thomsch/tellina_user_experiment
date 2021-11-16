#!/usr/bin/env bats
load ../libs/setup

@test "current_treatment is overriden when recovery" {
  local is_recovery=1
  local TASKS_SIZE=16
  local TASK_ORDER="N1T2"
  local task_num=9

  begin_treatment 1
  assert_output "${treatment}" "T"
  assert_output "${task_set}" 2

  is_recovery=0
  begin_treatment 1
  assert_output "${treatment}" "N"
  assert_output "${task_set}" 1
}

@test "current_treatment is not overriden when no recovery" {
  local is_recovery=0
  local TASKS_SIZE=16
  local TASK_ORDER="N1T2"
  local task_num=9

  begin_treatment 1
  assert_output "${treatment}" "N"
  assert_output "${task_set}" 1
}

@test "no general training when recovering" {
  local TASKS_SIZE=16
  local TASK_ORDER="N1T2"
  local task_num=0

  local is_recovery=1
  begin_treatment 1
  assert_output "${INF_TRAINING}" ""
  assert_output "${TEL_TRAINING}" ""
  unset INF_TRAINING

  local is_recovery=0
  begin_treatment 1
  assert_output "${INF_TRAINING}" "true" # training is allowed because it's the first task and no recovery
  assert_output "${TEL_TRAINING}" ""
  unset INF_TRAINING

  local is_recovery=0
  local task_num=1
  begin_treatment 1
  assert_output "${INF_TRAINING}" ""
  assert_output "${TEL_TRAINING}" ""
  unset INF_TRAINING

  local is_recovery=1
  local task_num=1
  begin_treatment 1
  assert_output "${INF_TRAINING}" ""
  assert_output "${TEL_TRAINING}" ""
  unset INF_TRAINING
}
#!/usr/bin/env bats
load ../libs/setup

@test "start_experiment single training set N1T2" {
  local TASKS_SIZE=6
  local TASK_ORDER="N1T2"
  local GENERAL_START_CODE='v'
  local GENERAL_TRAINING_SIZE=1
  local task_num task_set time_elapsed status task_code treatment
  local TEL_TRAINING INF_TRAINING
  local general_training_num tellina_training_num

  task_num=0

  set +e
  start_experiment <<< "k" # Mimics a keypress
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "v"
  assert_output "$INF_TRAINING" "true"
  assert_output "$TEL_TRAINING" ""
  assert_output "$general_training_num" 1

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 1
  assert_output "$task_code" "a"
  assert_output "$INF_TRAINING" ""
  assert_output "$TEL_TRAINING" ""
}

@test "start_experiment single training with 2 training tasks N1T2" {
  local TASKS_SIZE=6
  local TASK_ORDER="N1T2"
  local GENERAL_START_CODE='v'
  local GENERAL_TRAINING_SIZE=2
  local task_num task_set time_elapsed status task_code treatment
  local TEL_TRAINING INF_TRAINING
  local general_training_num tellina_training_num

  task_num=0

  set +e
  start_experiment <<< "k" # Mimics a keypress
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "v"
  assert_output "$INF_TRAINING" "true"
  assert_output "$TEL_TRAINING" ""
  assert_output "$general_training_num" 1

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "w"
  assert_output "$INF_TRAINING" "true"
  assert_output "$TEL_TRAINING" ""
  assert_output "$general_training_num" 2

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 1
  assert_output "$task_code" "a"
  assert_output "$INF_TRAINING" ""
  assert_output "$TEL_TRAINING" ""
}

@test "start_experiment single training N2T1" {
  local TASKS_SIZE=6
  local TASK_ORDER="N2T1"
  local GENERAL_START_CODE='v'
  local GENERAL_TRAINING_SIZE=2
  local task_num task_set time_elapsed status task_code treatment
  local TEL_TRAINING INF_TRAINING
  local general_training_num tellina_training_num

  task_num=0

  set +e
  start_experiment <<< "k" # Mimics a keypress
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "v"
  assert_output "$INF_TRAINING" "true"
  assert_output "$TEL_TRAINING" ""
  assert_output "$general_training_num" 1

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "w"
  assert_output "$INF_TRAINING" "true"
  assert_output "$TEL_TRAINING" ""
  assert_output "$general_training_num" 2

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 1
  assert_output "$task_code" "d"
  assert_output "$INF_TRAINING" ""
  assert_output "$TEL_TRAINING" ""
}

@test "start_experiment double training T2N1" {
  local TASKS_SIZE=6
  local TASK_ORDER="T2N1"
  local GENERAL_START_CODE='v'
  local GENERAL_TRAINING_SIZE=1
  local TELLINA_START_CODE='x'
  local TELLINA_TRAINING_SIZE=2
  local task_num task_set time_elapsed status task_code treatment
  local TEL_TRAINING INF_TRAINING
  local general_training_num tellina_training_num

  task_num=0

  set +e
  start_experiment <<< "k" # Mimics a keypress
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "v"
  assert_output "$INF_TRAINING" "true"
  assert_output "$TEL_TRAINING" "true"
  assert_output "$general_training_num" 1

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "x"
  assert_output "$INF_TRAINING" ""
  assert_output "$TEL_TRAINING" "true"
  assert_output "$general_training_num" 1
  assert_output "$tellina_training_num" 1

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "y"
  assert_output "$INF_TRAINING" ""
  assert_output "$TEL_TRAINING" "true"
  assert_output "$general_training_num" 1
  assert_output "$tellina_training_num" 2

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 1
  assert_output "$task_code" "d"
  assert_output "$INF_TRAINING" ""
  assert_output "$TEL_TRAINING" ""
}

@test "start_experiment double training T1N2" {
  local TASKS_SIZE=6
  local TASK_ORDER="T1N2"
  local GENERAL_START_CODE='s'
  local GENERAL_TRAINING_SIZE=1
  local TELLINA_START_CODE='m'
  local TELLINA_TRAINING_SIZE=1
  local task_num task_set time_elapsed status task_code treatment
  local TEL_TRAINING INF_TRAINING
  local general_training_num tellina_training_num

  task_num=0

  set +e
  start_experiment <<< "k" # Mimics a keypress
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "s"
  assert_output "$INF_TRAINING" "true"
  assert_output "$TEL_TRAINING" "true"
  assert_output "$general_training_num" 1
  assert_output "$tellina_training_num" 0

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "m"
  assert_output "$INF_TRAINING" ""
  assert_output "$TEL_TRAINING" "true"
  assert_output "$general_training_num" 1
  assert_output "$tellina_training_num" 1

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 1
  assert_output "$task_code" "a"
  assert_output "$INF_TRAINING" ""
  assert_output "$TEL_TRAINING" ""
}

@test "next_task switches treatment N1T2" {
  local TASKS_SIZE=6
  local TASK_ORDER="N1T2"
  local task_num task_set time_elapsed status task_code treatment
  local TEL_TRAINING INF_TRAINING

  local GENERAL_START_CODE='v'
  local GENERAL_TRAINING_SIZE=1
  local TELLINA_START_CODE='x'
  local TELLINA_TRAINING_SIZE=2
  local general_training_num tellina_training_num

  begin_treatment 1
  INF_TRAINING=""
  task_num=3
  task_code='c'

  status="success"
  set +e
  next_task
  set -e

  assert_output "$TEL_TRAINING" "true"
  assert_output "$treatment" "T"
  assert_output "$task_set" 2
  assert_output "$task_code" "x"
  assert_output "$task_num" 3
  assert_output "$tellina_training_num" 1

  status="success"
  set +e
  next_task
  set -e

  assert_output "$TEL_TRAINING" "true"
  assert_output "$treatment" "T"
  assert_output "$task_set" 2
  assert_output "$task_code" "y"
  assert_output "$task_num" 3
  assert_output "$tellina_training_num" 2

  status="success"
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
  
  local GENERAL_START_CODE='v'
  local GENERAL_TRAINING_SIZE=1
  local TELLINA_START_CODE='x'
  local TELLINA_TRAINING_SIZE=1
  local tellina_training_num


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
  assert_output "$task_code" "x"
  assert_output "$task_num" 3
  assert_output "$tellina_training_num" 1

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

@test "start_experiment training same N1T2" {
  local TASKS_SIZE=6
  local TASK_ORDER="N1T2"
  local GENERAL_START_CODE='a'
  local GENERAL_TRAINING_SIZE=2
  local task_num task_set time_elapsed status task_code treatment
  local TEL_TRAINING INF_TRAINING

  task_num=0

  set +e
  start_experiment <<< "k" # Mimics a keypress
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "a"
  assert_output "$INF_TRAINING" "true"
  assert_output "$TEL_TRAINING" ""

  status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 0
  assert_output "$task_code" "b"
  assert_output "$INF_TRAINING" "true"
  assert_output "$TEL_TRAINING" ""

    status="success"
  set +e
  next_task
  set -e

  assert_output "$task_num" 1
  assert_output "$task_code" "a"
  assert_output "$INF_TRAINING" ""
  assert_output "$TEL_TRAINING" ""
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
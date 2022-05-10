#!/usr/bin/env bats
#
# Each correctness test checks the correctness for different ways the user's
# command can be quoted.
load ../libs/setup

export FS_DIR
export USER_OUT
export TASKS_DIR
export TMP_DIFF

@test "verify_task select task success" {
  # Parameters for test_verify_task are
  # <task_code> <command> <expected status> <expected exit code>

  # cmd should be a $'single quoted' string preceeded by a '$'.
  # See "Quoting" section in 'man bash' for why this works.
  local cmd

  cmd=$'find . -type f -size +10k'
  test_verify_task "j" "$cmd" "success" 0
}

@test "verify_task select task unchanged file system failure" {
  local cmd

  cmd=$'find \'"."\' -type f'
  test_verify_task "j" "$cmd" "incomplete" 3
}

@test "verify_task select task changed file system failure" {
  local cmd

  # rm -r *
  cmd=$'rm -r *'
  test_verify_task "b" "$cmd" "incomplete" 2

  # find content -type f -size +10k -size -800c -delete
  cmd=$'find css -type f -delete'
  test_verify_task "j" "$cmd" "incomplete" 2
}

@test "verify_task file system task success" {
  local cmd

  # find css/ -type f | xargs rm
  cmd='find . -type d -empty -delete'
  test_verify_task "a" "$cmd" "success" 0
}

@test "verify_task task_i accept implicit relative path" {
  local cmd

  cmd=$'diff -qr content/labs/ content/lessons/'
  test_verify_task "i" "$cmd" "success" 0
}

@test "verify_task task_i accept explicit relative path" {
  local cmd

  cmd=$'diff -qr ./content/labs/ ./content/lessons/'
  test_verify_task "i" "$cmd" "success" 0
}

@test "verify_task task_i accept mixed relative path" {
  local cmd

  cmd=$'diff -qr content/labs/ ./content/lessons/'
  test_verify_task "i" "$cmd" "success" 0

    cmd=$'diff -qr ./content/labs/ content/lessons/'
  test_verify_task "i" "$cmd" "success" 0
}

@test "verify_task file system task failure" {
  local cmd # should 'single quoted'

  cmd='find . -type f -delete'
  test_verify_task "a" "$cmd" "incomplete" 1
}

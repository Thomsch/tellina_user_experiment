#!/usr/bin/env/ bats
#
# Tests utility code used by the client side infrastructure to handle internal
# information.
load ../libs/setup

@test "chr correct lower case output" {
  run chr 97
  assert_success
  assert_output "$output" "a"

  run chr 110
  assert_success
  assert_output "$output" "n"

  run chr 122
  assert_success
  assert_output "$output" "z"
}

@test "chr correct upper case output" {
  run chr 65
  assert_success
  assert_output "$output" "A"

  run chr 78
  assert_success
  assert_output "$output" "N"

  run chr 90
  assert_success
  assert_output "$output" "Z"
}

@test "chr fails on bad input" {
  run chr 256
  assert_failure

  run chr 300
  assert_failure

  run chr -1
  assert_failure
}

@test "ord correct lower case output" {
  run ord "a"
  assert_success
  assert_output "$output" 97

  run ord "n"
  assert_success
  assert_output "$output" 110

  run ord "z"
  assert_success
  assert_output "$output" 122
}

@test "ord correct upper case output" {
  run ord "A"
  assert_success
  assert_output "$output" 65

  run ord "N"
  assert_success
  assert_output "$output" 78

  run ord "Z"
  assert_success
  assert_output "$output" 90
}

@test "char_from correct nth character of lower case alphabet" {
  local lower_alph=(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  for i in {1..26}; do
    run char_from $i
    [[ $status == 0 ]]

    debug "Input: $i"
    assert_output $output ${lower_alph[i - 1]}
  done
}

@test "get_training_code gives correct code for general training" {
  run get_training_code 'v' 1
  assert_output $output 'v'

  run get_training_code 'v' 2
  assert_output $output 'w'

  run get_training_code 'v' 3 # Should throw an error because v and w are the only training tasks
  assert_output $output 'x'
}

@test "get_training_code gives correct code for tellina training" {
  run get_training_code 'y' 1
  assert_output $output 'y'

  run get_training_code 'y' 2
  assert_output $output 'z'

  run get_training_code 'y' 3 # Should throw an error because v and w are the only training tasks
  assert_output $output '{'
}
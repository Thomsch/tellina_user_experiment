#!/usr/bin/env python3

"""
Determine whether the user's command has solved the task.

Parameters:
- args[1]: the current true task code.
- args[2]: the directory in which to run the given user command.
- args[3:]: the user's command.

This script has the following exit codes:
- 0: The verification is successful.
- 1: The file system does not match expected and the task is a file system task.
- 2: The file system has been changed and the task is a select task.
- 3: The output does not match expected and the task is a select task.

In addition, two files called "actual" and "expected" will be created
in TMP_DIFF_DIR if the verification fails.
"""

import sys
import os
import shutil
import subprocess
import filecmp

# Exit codes
VERIFICATION_SUCCESS = 0
FILE_SYSTEM_FAILURE  = 1
FILE_SYSTEM_MODIFIED = 2
STANDARD_OUT_FAILURE = 3
UNEXPECTED_FAILURE   = 4
SUBPROCESS_FAILURE   = 5

# Gets all the environment variables
FS_DIR = os.environ['FS_DIR']
USER_OUT_DIR = os.environ['USER_OUT']
TMP_DIFF_DIR = os.environ['TMP_DIFF']

# Establishes files for all the outputs
USER_STDERR = os.path.join(USER_OUT_DIR, 'std_err')

USER_FS_FILE = os.path.join(USER_OUT_DIR, 'fs_out')
USER_STDOUT_FILE = os.path.join(USER_OUT_DIR, 'std_out')

ACTUAL_FILE = os.path.join(TMP_DIFF_DIR, 'actual')
EXPECTED_FILE = os.path.join(TMP_DIFF_DIR, 'expected')

# There are two types of tasks: those that expect output, and
# those that expect a modification to the file system.
FILESYSTEM_TASKS = {'v', 'y', 'x', 'h', 'a', 'd', 'e'}

# These task rely on the `find` utility to complete the task. 
# They require their output to be normalized for consistent behavior
# across different systems.
NORMALIZE_FIND_TASKS = {'g', 'j', 'k', 'f'}

# Magic string to trigger the 'expected command'
MAGIC_SHOW_EXPECTED_COMMAND = "MAGIC_STRING_EXPECTED_COMMAND"

class cd:
    """Context manager for changing the current working directory"""
    def __init__(self, newPath):
        self.newPath = os.path.expanduser(newPath)

    def __enter__(self):
        self.savedPath = os.getcwd()
        os.chdir(self.newPath)

    def __exit__(self, etype, value, traceback):
        os.chdir(self.savedPath)

def main():

    # the true task code
    task_code = sys.argv[1]
    command_dir = sys.argv[2]
    # the current command
    command = ' '.join(sys.argv[3:])

    # Special behavior when using expected help command
    if command == MAGIC_SHOW_EXPECTED_COMMAND:
        check_fs = task_code in FILESYSTEM_TASKS # True if this is a filesystem task.
        generate_expected(task_code, check_fs)
        generate_actual(check_fs)
        sys.exit(0)

    try:

        # Always:
        # - Get the current state of the file system and compare it to the expected
        #   file system for the current task.  (For a select task, this ensures that
        #   it was not changed).
        # If it is a "select" task and the file system was not modified, also:
        # - Re-execute the user command and capture the `stdout`.
        # - Check that the captured `stdout` of the user command matches the
        #   corresponding expected output.

        devnull = open(os.devnull, 'wb')

        with open(USER_FS_FILE, 'w') as user_out:
            with cd(FS_DIR):
                filesystem = subprocess.call('find .', shell=True, stderr=devnull, stdout=user_out)

        normalize_and_copy_output(USER_FS_FILE, ACTUAL_FILE)

        # Verify checks whether or not the file system state is as expected.
        fs_good = verify(ACTUAL_FILE, task_code, True)

        if not fs_good:
            if task_code in FILESYSTEM_TASKS:
                sys.exit(FILE_SYSTEM_FAILURE)
            else:
                sys.exit(FILE_SYSTEM_MODIFIED)
        else:
            if task_code in FILESYSTEM_TASKS:
                sys.exit(VERIFICATION_SUCCESS)
            else:
                with open(USER_STDOUT_FILE, 'w') as user_out:
                    with open(USER_STDERR, 'w') as user_err:
                        # shell=True is needed here for several reasons:
                        # 1. It preserves quoting for user commands given that
                        # the command argument passed to the call is a string.
                        # (see https://docs.python.org/3/library/subprocess.html#popen-constructor starting at "On POSIX with shell=True")
                        # 2. It reduces the need to replace shell piplines.
                        # (see https://docs.python.org/3/library/subprocess.html#replacing-shell-pipeline)
                        with cd(command_dir):
                            stdout = subprocess.call(command, shell=True, stderr=user_err, stdout=user_out)
                
                if task_code in NORMALIZE_FIND_TASKS:
                    normalize_and_copy_output(USER_STDOUT_FILE, ACTUAL_FILE)
                else:
                    shutil.copy(USER_STDOUT_FILE, ACTUAL_FILE)

                if verify(ACTUAL_FILE, task_code, False):
                    sys.exit(VERIFICATION_SUCCESS)
                else:
                    sys.exit(STANDARD_OUT_FAILURE)
    except (OSError, subprocess.CalledProcessError) as e:
        print(e)
        sys.exit(SUBPROCESS_FAILURE)

def normalize_and_copy_output(subprocess_output_file, normalized_output_file):
    """
    Normalizes the contents of file subprocess_output (sorts lines, removes
    leading './') and writes the result to file normalized_output.

    This step accounts for platform difference changing the output of the `find` utility.

    Removing leading `./` ensures calls to `find '.' ...` and `find ...` yield the same output.

    Sorting the lines ensures the order of the output doesn't change between systems as
    the file order is given by the layout of the filesystem's i-nodes.
    """
    with open(normalized_output_file, 'w') as normalized_output:
        with open(subprocess_output_file) as subprocess_output:
            lines = []
            for line in subprocess_output.read().splitlines():
                if line == './' or line == '.':
                    lines.append(line)
                else:
                    lines.append(line.lstrip('./'))

            lines = sorted(lines)
            for line in lines:
                print(line, file=normalized_output)

def verify(normalized_output_file, task_code, check_fs):
    """Returns true if verification succeeded, false if it failed."""
    task = "task_{}".format(task_code)

    task_verify_file = os.path.join(
        os.environ['TASKS_DIR'], "{task}/{task}.{out_type}.out"
            .format(task=task, out_type="fs" if check_fs else "select"))

    # Remove non leading "./" for output in task i.
    if task_code == 'i':
        clean_lines = []
        with open(normalized_output_file, 'r') as file:
            for line in file.read().splitlines():
                clean_line = line.replace("./", "")
                clean_lines.append(clean_line)
        
        with open(normalized_output_file, 'w') as file:
            for line in clean_lines:
                print(line, file=file)

    # compare normalized output file and task verification file
    files_match = filecmp.cmp(normalized_output_file, task_verify_file)
    if not files_match:
        shutil.copy(task_verify_file, EXPECTED_FILE)

    return files_match

def generate_expected(task_code, check_fs):
    task = "task_{}".format(task_code)

    task_verify_file = os.path.join(
        os.environ['TASKS_DIR'], "{task}/{task}.{out_type}.out"
            .format(task=task, out_type="fs" if check_fs else "select"))
    
    shutil.copy(task_verify_file, EXPECTED_FILE)

def generate_actual(check_fs):
    if check_fs:
        devnull = open(os.devnull, 'wb')

        with open(USER_FS_FILE, 'w') as user_out:
            with cd(FS_DIR):
                filesystem = subprocess.call('find .', shell=True, stderr=devnull, stdout=user_out)

        normalize_and_copy_output(USER_FS_FILE, ACTUAL_FILE)
    else:
        open(ACTUAL_FILE, 'w').close() # Empties ACTUAL_FILE

if __name__ == '__main__':
    main()

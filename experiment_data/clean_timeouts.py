# -----------------------------------------------------------------------------
# Adds tasks that participants couldn't do because of taskset timeout.
# For example, if user P's taskset timed out on task b, when there were still
# task c and d to do in the current task set, this script will add new 
# entries for task c and d and set their elapsed time to the timeout time 
# (MAX_TIME).
#
# This script also replaces `skip` and `timeout` entries to the max timeout 
# time (MAX_TIME).
# -----------------------------------------------------------------------------
import sys
import csv
from csv import DictReader
from csv import DictWriter
import os 
import copy

MAX_TIME=360
TASK_GROUP_1=['a', 'b', 'c', 'd', 'e', 'f']
TASK_GROUP_2=['g', 'h', 'i', 'j', 'k', 'l']

def main():
    if len(sys.argv) != 3:
        print("Usage: <in.csv> <out.csv>")
        exit(1)

    file_in = sys.argv[1]
    file_out = sys.argv[2]
    dir_path = os.path.dirname(os.path.realpath(__file__))

    # open file in read mode
    with open(os.path.join(dir_path,file_in), 'r') as read_obj:
        csv_reader = DictReader(read_obj)

        fieldnames = csv_reader.fieldnames
        with open(os.path.join(dir_path,file_out), 'w') as write_obj:

            writer = DictWriter(write_obj, fieldnames, quoting=csv.QUOTE_MINIMAL, delimiter=',')
            writer.writeheader()
            
            line_number = 1
            task = ""
            # Iterate over each row in the csv using reader object
            for row in csv_reader:
                status = row['status']
                task = row['task_code']

                if status == "set-timeout":
                    if task in TASK_GROUP_1:
                        rows = missing_tasks(task, TASK_GROUP_1, row)
                        writer.writerows(rows)
                    elif task in TASK_GROUP_2:
                        rows = missing_tasks(task, TASK_GROUP_2, row)
                        writer.writerows(rows)
                elif status == "skip" or status == "timeout":
                    row['time_elapsed'] = MAX_TIME
                    writer.writerow(row)
                else:
                    row.pop(None, None)
                    writer.writerow(row)
                line_number=line_number+1
        return 0

def missing_tasks(task, group, row):
    new_rows = []
    for index in range(group.index(task), len(group)):
        new_row = copy.deepcopy(row)
        new_row['task_code'] = group[index]
        new_row['time_elapsed'] = MAX_TIME
        new_row['command'] = "NA"
        print("Copy: ")
        print(new_row)
        print(f"-> missing task {group[index]}")
        new_rows.append(new_row)
    return new_rows

if __name__ == "__main__":
    main()
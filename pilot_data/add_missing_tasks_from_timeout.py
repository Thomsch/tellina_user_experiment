import csv
from csv import DictReader
from csv import DictWriter
import os 
import copy

MAX_TIME =360

def missing_tasks(task, group, treatment, row):
    new_rows = []
    for index in range(group.index(task), len(group)):
        new_row = copy.deepcopy(row)
        new_row['task_code'] = group[index]
        new_row['time_elapsed'] = MAX_TIME
        print("Copy: ")
        print(new_row)
        print(f"-> missing task {group[index]}")
        new_rows.append(new_row)
    return new_rows

task_group_1 = ['a', 'b', 'c', 'd', 'e', 'f']
task_group_2 = ['g', 'h', 'i', 'j', 'k', 'l']

dir_path = os.path.dirname(os.path.realpath(__file__))
# open file in read mode
with open(os.path.join(dir_path,'./raw_data.csv'), 'r') as read_obj:
    # pass the file object to reader() to get the reader object
    csv_reader = DictReader(read_obj)

    filednames = csv_reader.fieldnames
    with open(os.path.join(dir_path,'./data.csv'), 'w') as write_obj:

        writer = DictWriter(write_obj, filednames, quoting=csv.QUOTE_MINIMAL, delimiter=',')
        writer.writeheader()
        
        line_number = 1
        # Iterate over each row in the csv using reader object

        participant = ""
        task = ""

        for row in csv_reader:
            status = row['status']
            task = row['task_code']
            treatment = row['treatment']
            time_elapsed = row['time_elapsed']

            if status == "set-timeout":
                if task in task_group_1:
                    rows = missing_tasks(task, task_group_1, treatment, row)
                    writer.writerows(rows)
                elif task in task_group_2:
                    rows = missing_tasks(task, task_group_2, treatment, row)
                    writer.writerows(rows)
            elif status == "skip" or status == "timeout":
                row['time_elapsed'] = MAX_TIME
                writer.writerow(row)
            else:
                row.pop(None, None)
                writer.writerow(row)
            line_number=line_number+1

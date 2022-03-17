# Tasks
This file contains the training tasks and experiment tasks present in `client_side/.infrastructure/tasks/. The tasks are adapted from the sampling script in this folder that were then validated from our pilot.

## Experiment Tasks
|Rewritten Prompt|Original Solution|
-------|-----------------
| Recursively delete all empty subdirectories under the current directory | `find . -depth  -type d -delete -empty -exec rmdir {} \;` |
| Show the lines of `./content/review/review2.md` that are not in `./content/review/review1.md` | `comm -23 content/review/review2.md content/review/review1.md` |
| Count the number of files in './content/labs/' and subdirectories recursively. | `find "content/labs" -type f \| wc -l` |
| Remove all files except 'tips.md' in directory './content/'. | `find content/ -maxdepth 1 ! -name "tips.md" -type f -delete` |
| Recursively remove all files in the './css/' directory. | `find css -type f \| xargs rm` |
| List the names of the directories that are children of children of the './content/' directory. | `find content/ -mindepth 2 -maxdepth 2 -type d -exec basename {} \;` |
| List recursively all the non-markdown files in the current directory. | `find . -type f ! -name "*.md"` |
| Delete recursively all markdown files starting with a number under the current directory. | `find . -type f -name "[[:digit:]]*.md" -delete` |
| Show which files differ recursively between './content/labs/' and './content/lessons/'. | `diff -qr content/labs/ content/lessons/` |
| Recursively list all files in the current directory that are larger than 10kB. | `find . -size +10k` |
| Find all lines containing 'why' (case insensitive) in files with 'review' in their filename recursively contained in the current directory. | `find . -name *review* -exec grep -Hni 'why' {} \;` |
| Show the size of files and directories in 'content/' in the expected human-friendly format, ordered by size. | `du -hs content/* \| sort -hr` |

## Training Tasks
|Rewritten Prompt|Original Solution|
-------|-----------------
| Rename file './README.md' to './README.txt'. | `mv README.md README.txt` |
| Display the content of the CSS file in the './css/' directory. | `cat css/app.css` |
| Delete recursively all files containing 'glyph' in their filename under the current directory. | `find . -name '*glyph*' -delete` |
| Copy './content/tips.md' in new directory './content/backup/'. | `mkdir -p "content/backup" && cp content/tips.md "content/backup"` |
| Print the number of lines of './content/syllabus.md'. | `cat content/syllabus.md | wc -l ` |

## Count
Counting the commands in the original solutions, excluding the original traning tasks that were not sampled by this method (*Recursively remove all files in the './css/' directory* and *Recursively list all files in the current directory that are larger than 10kB*).

### How many times each command appears in the original solutions?
- `find` 8
- `wc` 2
- `grep` 1
- `sort` 1
- `cat` 2
- `mv` 1
- `cp` 1
- `mkdir` 1
- `comm` 1
- `diff` 1
- `du` 1
- `rmdir` 1
- `basename` 1

### How many commands appears in the original solutions?
- 1 command: 8 solutions
- 2 commands: 7 solutions

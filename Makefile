#########################
## Files and directories
#########################

# Directory of distribution which is a symbolic link to CLIENT_DIR.
# This allows naming the directory distributed to the users without directly
# changing the CLIENT_DIR's name.
DIST_NAME=experiment

# The name of the distribution.
ZIP_DIST_NAME=$(DIST_NAME).zip

CLIENT_DIR=client_side
BACKEND_DIR=backend

# This operation is safe because the test frame work will clean up any backup,
# temporary files, etc.
CLIENT_FILES=$(shell find $(CLIENT_DIR) -type f)

INFRA_DIR=$(DIST_NAME)/.infrastructure
TEST_DIR=$(INFRA_DIR)/test

#########################
## Host
#########################

# The machine that is hosting the website
HOST=tschweiz@attu.cs.washington.edu

# The website's directory on HOST
HOST_DIR=/cse/web/homes/tschweiz/research

# The host folder containing the website
WEBSITE_NAME=en2bash-study

# Physical location where the website is hosted
PUBLIC_SITE=$(HOST_DIR)/$(WEBSITE_NAME)

# Hosted testing location
STAGING_SITE=$(HOST_DIR)/staging/$(WEBSITE_NAME)

# Local folder to store what is going to be hosted.
BUILD_TARGET=distribution

#########################
## Commands
#########################

RM=rm -rf
ZIP=zip -qr

TIMESTAMP=$(shell date +%Y-%m-%dT%H-%M-%S)

#########################
## Tasks
#########################

# See https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html
.PHONY: all test distribute publish publish-staging cp_static dist-static dist-backend

all: test distribute

test: $(DIST_NAME)
	$(MAKE) -C $(INFRA_DIR) test

# Assemble hosted content in folder specified by BUILD_TARGET
# log.csv needs to be writeable for the post_handler in the server.
distribute: $(ZIP_DIST_NAME) dist-static dist-backend
	mkdir -p $(BUILD_TARGET)
	mv $< $(BUILD_TARGET)
	find $(BUILD_TARGET) -name "README.md" -type f -delete
	chmod 666 $(BUILD_TARGET)/backend/log.csv

# Publish the distribution to the production host folder.
publish: test distribute
	@echo "Publishing $(BUILD_TARGET)..."
	
	@echo "Saving existing log file with timestamp $(TIMESTAMP)..."
	@scp -p $(HOST):$(PUBLIC_SITE)/backend/log.csv $(HOST):$(PUBLIC_SITE)/backend/log-$(TIMESTAMP).csv
	@scp -p $(HOST):$(PUBLIC_SITE)/backend/log.csv log-$(TIMESTAMP).csv

	@echo "Uploading new version, overriden files..."
	@scp -pr $(BUILD_TARGET)/* $(HOST):$(PUBLIC_SITE)

# Publish the distribution to the testing host folder.
publish-staging: test distribute
	@echo "Publishing $(BUILD_TARGET) in **staging environment**..."
	@scp -pr $(BUILD_TARGET)/* $(HOST):$(STAGING_SITE)

clean: 
	$(RM) $(ZIP_DIST_NAME)
	$(RM) $(DIST_NAME)
	$(RM) $(BUILD_TARGET)

# Distribute static resources
dist-static:
	cp -a static/. $(BUILD_TARGET)

# Distribute the backend
dist-backend:
	cp -r -p $(BACKEND_DIR) $(BUILD_TARGET)

$(ZIP_DIST_NAME): $(DIST_NAME) $(CLIENT_FILES) test
# Delete Emacs backup files.
	find . -name '*~' -delete
	$(ZIP) $@ $<

$(DIST_NAME): clean
	cp -r $(CLIENT_DIR) $@
	find $@ -name ".gitkeep" -type f -delete

# Check that the host has the website directory.
%/$(WEBSITE_NAME):
	@echo -n "Checking that host directory $@ exists... "
	@ssh $(HOST) '[ -d $@ ]'
	@echo "OK."

BASH_SCRIPTS = $(shell grep -r -l '^\#! \?\(/bin/\|/usr/bin/env \)bash' * | grep -v .git | grep -v "~" | grep -v '.csv')
shell-script-style:
	shellcheck --format=gcc ${BASH_SCRIPTS}
	checkbashisms ${SH_SCRIPTS}

PYTHON_FILES=$(wildcard **/*.py)
python-style:
	black ${PYTHON_FILES}
	pylint -f parseable --disable=W,invalid-name ${PYTHON_FILES}

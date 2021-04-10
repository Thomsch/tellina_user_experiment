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
# This operation is safe because the test frame work will clean up any backup,
# temporary files, etc.
CLIENT_FILES=$(shell find $(CLIENT_DIR) -type f)

FS_DIR=$(CLIENT_DIR)/file_system

INFRA_DIR=$(CLIENT_DIR)/.infrastructure
TEST_DIR=$(INFRA_DIR)/test

#########################
## Host
#########################

# The machine that is hosting the website
HOST=tschweiz@attu.cs.washington.edu

# The website's directory on HOST
HOST_DIR=/cse/web/homes/tschweiz/research

# The host folder containing the website
WEBSITE_NAME=tellina_user_study

# Physical location where the website is hosted
PUBLIC_SITE=$(HOST_DIR)/$(WEBSITE_NAME)

# Hosted testing location
STAGING_SITE=$(HOST_DIR)/staging/$(WEBSITE_NAME)

#########################
## Commands
#########################

RM=rm -rf
ZIP=zip -qr

#########################
## Tasks
#########################

.PHONY: all test publish-distribution stage-distribution

all: $(ZIP_DIST_NAME)

test:
	$(MAKE) -C $(INFRA_DIR) test

# Publish the distribution to the production host folder.
publish: $(ZIP_DIST_NAME) $(PUBLIC_SITE)
	@echo "Publishing $<"
	@scp $< $(HOST):$(PUBLIC_SITE)

# Publish the distribution to the testing host folder.
stage-distribution: $(ZIP_DIST_NAME) $(STAGING_SITE)
	@echo "Staging $<"
	@scp $< $(HOST):$(STAGING_SITE)

clean: clean-dist clean-fs-dir

clean-dist:
	$(RM) $(ZIP_DIST_NAME)
	$(RM) $(DIST_NAME)

clean-fs-dir:
	$(RM) $(FS_DIR)

$(ZIP_DIST_NAME): $(DIST_NAME) $(CLIENT_FILES) test
	$(ZIP) $@ $<

$(DIST_NAME):
	ln -s $(CLIENT_DIR) $@

$(FS_DIR):
	cp -r $(INFRA_DIR)/file_system $@
	find $@ -type f -exec chmod a+w {} \;

# Check that the host has the website directory.
%/$(WEBSITE_NAME):
	@echo -n "Checking that host directory $@ exists... "
	@ssh $(HOST) '[ -d $@ ]'
	@echo "OK."

# common variables for tasks, make flags, meta rules

# Export environment variables if a .env file is present.
ifeq ($(ENV_EXPORTED),) # ENV vars not yet exported
ifneq ("$(wildcard .env)","")
sinclude .env
export $(shell [ -f .env ] && sed 's/=.*//' .env)
export ENV_EXPORTED=true
$(info Note — An .env file exists. Its contents have been exported as environment variables.)
endif
endif

# Enforce repo ownership
ifeq ("$(wildcard ft.yml)","")
$(error 'Projects making use of n-gage *must* define an ft.yml file containing the repo owner’s details (see any next- repo for required structure)')
$(error 'If you are creating a project not to be maintained by the next team please feel free to copy what you need from our build tools but don’t add an ft.yml.')
$(error 'Integrating with our tooling may result in unwanted effects e.g. nightly builds, slack alerts, emails etc')
endif

# ./node_modules/.bin on the PATH
export PATH := $(PATH):./node_modules/.bin

# Use bash not sh
SHELL := /bin/bash

ifeq ("$(wildcard node_modules/@financial-times/n-gage/index.mk)","")
PATH_TO_NGAGE :=
else
PATH_TO_NGAGE := node_modules/@financial-times/n-gage/
endif

# verify that githooks are configured correctly
GITHOOKS := $(shell node ${PATH_TO_NGAGE}scripts/githooks.js)
ifneq ("$(GITHOOKS)","")
$(error $(GITHOOKS))
endif

# Some handy utilities
GLOB = git ls-files -z $1 | tr '\0' '\n' | xargs -I {} find {} ! -type l
NPM_INSTALL = npm prune --production=false --no-package-lock && npm install --no-package-lock
BOWER_INSTALL = bower prune && bower install --config.registry.search=https://origami-bower-registry.ft.com --config.registry.search=https://registry.bower.io
JSON_GET_VALUE = grep $1 | head -n 1 | sed 's/[," ]//g' | cut -d : -f 2
IS_GIT_IGNORED = grep -q $(if $1, $1, $@) .gitignore
VERSION = master
APP_NAME = $(shell cat package.json 2>/dev/null | $(call JSON_GET_VALUE,name))
DONE = echo ✓ $@ done
IS_USER_FACING = `find . -type d \( -path ./bower_components -o -path ./node_modules -o -path ./coverage \) -prune -o -name '*.html' -print`
MAKEFILE_HAS_A11Y = `grep -rli "a11y" Makefile`
REPLACE_IN_GITIGNORE = sed -i -e 's/$1/$2/g' .gitignore && rm -f .gitignore-e ||:
ENTRY_MAKEFILE = $(firstword $(MAKEFILE_LIST))

#
# META TASKS
#

# Note: A 'node_modules' directory is created when n-gage self-installs.
# However: Subsequent calls to `node_modules`, made in order to execute $NPM_INSTALL,
# are *not* processed because the node_modules directory exists.
# Therefore use .PHONY to tell Make to not look for a node_modules file/folder,
# but to run the node_modules task instead. 'bower_components' is incuded for similar
# reasons, though it's not strictly neccessary at this point in time.
.PHONY: test node_modules bower_components
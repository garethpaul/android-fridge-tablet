.DEFAULT_GOAL := check
.PHONY: __repository-make-authority build check lint root-test test verify
.SECONDEXPANSION:

override SHELL := /bin/sh
override .SHELLFLAGS := -c
build check lint root-test test verify __repository-make-authority: override SHELL := /bin/sh
build check lint root-test test verify __repository-make-authority: override .SHELLFLAGS := -c

ifeq ($(origin ANDROID_HOME),undefined)
override ANDROID_HOME :=
else
override ANDROID_HOME := $(value ANDROID_HOME)
endif
ifeq ($(origin ANDROID_SDK_ROOT),undefined)
override ANDROID_SDK_ROOT :=
else
override ANDROID_SDK_ROOT := $(value ANDROID_SDK_ROOT)
endif
override ROOT := $(shell path='$(subst ','"'"',$(value MAKEFILE_LIST))'; path=$$(/usr/bin/printf '%s' "$$path" | /usr/bin/sed 's/^ //'); [ -f "$$path" ] || exit 1; directory=$$(/usr/bin/dirname -- "$$path"); CDPATH= cd -- "$$directory" && /bin/pwd -P)
ifeq ($(origin GRADLE),undefined)
override GRADLE := $(ROOT)/gradlew
else
override GRADLE := $(value GRADLE)
endif
override ANDROID_SDK := $(if $(ANDROID_HOME),$(ANDROID_HOME),$(ANDROID_SDK_ROOT))
export ANDROID_HOME ANDROID_SDK_ROOT GRADLE ROOT

override REPOSITORY_MAKE_DOLLAR := $$
override REPOSITORY_MAKE_OPEN := (
override REPOSITORY_MAKE_OPEN_BRACE := {
define REPOSITORY_REJECT_MAKE_SYNTAX
ifneq ($$(findstring $$(REPOSITORY_MAKE_DOLLAR)$$(REPOSITORY_MAKE_OPEN),$$(value $(1))),)
$$(error $(1) must be a literal value, not Make syntax)
endif
ifneq ($$(findstring $$(REPOSITORY_MAKE_DOLLAR)$$(REPOSITORY_MAKE_OPEN_BRACE),$$(value $(1))),)
$$(error $(1) must be a literal value, not Make syntax)
endif
endef
$(foreach variable,ANDROID_HOME ANDROID_SDK_ROOT GRADLE,$(eval $(call REPOSITORY_REJECT_MAKE_SYNTAX,$(variable))))

ifeq ($(strip $(ROOT)),)
$(error repository Makefile path could not be resolved)
endif
ifeq ($(strip $(GRADLE)),)
$(error GRADLE must be a literal executable path)
endif

ifneq ($(filter command line,$(origin MAKEFLAGS)),)
$(error MAKEFLAGS must not be overridden for repository verification)
endif
override REPOSITORY_MAKE_FIRST_FLAGS := $(firstword $(MAKEFLAGS))
ifneq ($(filter -%,$(REPOSITORY_MAKE_FIRST_FLAGS)),)
override REPOSITORY_MAKE_FIRST_FLAGS :=
endif
override REPOSITORY_MAKE_SHORT_FLAGS := $(REPOSITORY_MAKE_FIRST_FLAGS) $(filter-out --%,$(filter -%,$(MAKEFLAGS)))
ifneq ($(findstring n,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring t,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring q,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring i,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(filter --just-print --dry-run --recon --touch --question --ignore-errors,$(MAKEFLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(strip $(MAKEFILES)),)
$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)
endif
override MAKEFILES :=
ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif

override REPOSITORY_SHELL_LITERAL = $(subst $$,$$$$,$(subst ','"'"',$1))
override REPOSITORY_ROOT_LITERAL := $(call REPOSITORY_SHELL_LITERAL,$(ROOT))
override REPOSITORY_GRADLE_LITERAL := $(call REPOSITORY_SHELL_LITERAL,$(GRADLE))
override REPOSITORY_ANDROID_SDK_LITERAL := $(call REPOSITORY_SHELL_LITERAL,$(ANDROID_SDK))

build check lint root-test test verify:: $$(if $$(filter file,$$(origin MAKEFILE_LIST)),,$$(error MAKEFILE_LIST must not be overridden))
build check lint root-test test verify:: $$(if $$(shell path=$$$$(/usr/bin/printf '%s' '$$(subst ','"'"',$$(MAKEFILE_LIST))' | /usr/bin/sed 's/^ //') && [ -f "$$$$path" ] && /usr/bin/printf '%s' ok),,$$(error repository Makefile must be loaded alone))
build check lint root-test test verify:: __repository-make-authority

__repository-make-authority::
	@:

define REPOSITORY_PUBLIC_RECIPES
root-test::
	/bin/sh '$(REPOSITORY_ROOT_LITERAL)/scripts/test-makefile-root.sh'

lint::
	/bin/sh '$(REPOSITORY_ROOT_LITERAL)/scripts/check-baseline.sh'
	@if [ -n '$(REPOSITORY_ANDROID_SDK_LITERAL)' ] && [ -d '$(REPOSITORY_ANDROID_SDK_LITERAL)' ]; then \
		cd '$(REPOSITORY_ROOT_LITERAL)' && ANDROID_HOME='$(REPOSITORY_ANDROID_SDK_LITERAL)' ANDROID_SDK_ROOT='$(REPOSITORY_ANDROID_SDK_LITERAL)' '$(REPOSITORY_GRADLE_LITERAL)' lint --no-daemon; \
	else echo "Android SDK not configured; Gradle lint skipped."; fi

test::
	/bin/sh '$(REPOSITORY_ROOT_LITERAL)/scripts/test-item-store.sh'
	/bin/sh '$(REPOSITORY_ROOT_LITERAL)/scripts/test-check-baseline.sh'
	@if [ -n '$(REPOSITORY_ANDROID_SDK_LITERAL)' ] && [ -d '$(REPOSITORY_ANDROID_SDK_LITERAL)' ]; then \
		cd '$(REPOSITORY_ROOT_LITERAL)' && ANDROID_HOME='$(REPOSITORY_ANDROID_SDK_LITERAL)' ANDROID_SDK_ROOT='$(REPOSITORY_ANDROID_SDK_LITERAL)' '$(REPOSITORY_GRADLE_LITERAL)' test --no-daemon; \
	else echo "Android SDK not configured; Gradle tests skipped."; fi

build::
	@if [ -n '$(REPOSITORY_ANDROID_SDK_LITERAL)' ] && [ -d '$(REPOSITORY_ANDROID_SDK_LITERAL)' ]; then \
		cd '$(REPOSITORY_ROOT_LITERAL)' && ANDROID_HOME='$(REPOSITORY_ANDROID_SDK_LITERAL)' ANDROID_SDK_ROOT='$(REPOSITORY_ANDROID_SDK_LITERAL)' '$(REPOSITORY_GRADLE_LITERAL)' assembleDebug --no-daemon; \
	else echo "Android SDK not configured; Gradle build skipped."; fi

verify:: root-test lint test build
check:: verify
endef
$(eval $(REPOSITORY_PUBLIC_RECIPES))

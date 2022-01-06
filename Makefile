# Set the shell
SHELL := /bin/bash

# Set an output prefix, which is the local directory if not specified
PREFIX?=$(shell pwd)

# Set the build dir, where built cross-compiled binaries will be output
BUILDDIR := ${PREFIX}/cross

CROSS_TARGETS := aarch64-unknown-linux-musl	\
				 x86_64-unknown-linux-musl \
				 x86_64-unknown-freebsd	\
				 x86_64-unknown-illumos \
				 x86_64-apple-darwin \
				 x86_64-pc-windows-msvc \
				 i686-pc-windows-msvc

#aarch64-apple-darwin \

# For this to work, you need to install toml-cli: https://github.com/gnprice/toml-cli
# `cargo install toml-cli`
VERSION := $(shell toml get $(CURDIR)/Cargo.toml package.version | jq -r .)

GITCOMMIT := $(shell git rev-parse --short HEAD)
GITUNTRACKEDCHANGES := $(shell git status --porcelain --untracked-files=no)
ifneq ($(GITUNTRACKEDCHANGES),)
	GITCOMMIT := $(GITCOMMIT)-dirty
endif
ifeq ($(GITCOMMIT),)
    GITCOMMIT := ${GITHUB_SHA}
endif

define buildrelease
rustup target add $(1)
cargo build \
	--target $(1) \
	-Z unstable-options \
	--out-dir $(BUILDDIR);
md5sum $(BUILDDIR)/$(NAME)-$(1) > $(BUILDDIR)/$(NAME)-$(1).md5;
sha256sum $(BUILDDIR)/$(NAME)-$(1) > $(BUILDDIR)/$(NAME)-$(1).sha256;
echo -e "### $(1)\n\n" >> $(BUILDDIR)/README.md;
echo -e "\`\`\`console" >> $(BUILDDIR)/README.md;
echo -e "# Export the sha256sum for verification." >> $(BUILDDIR)/README.md;
echo -e "$$ export OXIDE_CLI_SHA256=\"`cat $(BUILDDIR)/$(NAME)-$(1).sha256 | awk '{print $$1}'`\"\n\n" >> $(BUILDDIR)/README.md;
echo -e "# Download and check the sha256sum." >> $(BUILDDIR)/README.md;
echo -e "$$ curl -fSL \"https://dl.oxide.computer/releases/cli/$(VERSION)/$(NAME)-$(1)\" -o \"/usr/local/bin/oxide\" \\" >> $(BUILDDIR)/README.md;
echo -e "\t&& echo \"\$${OXIDE_CLI_SHA256}  /usr/local/bin/oxide\" | sha256sum -c - \\" >> $(BUILDDIR)/README.md;
echo -e "\t&& chmod a+x \"/usr/local/bin/oxide\"\n\n" >> $(BUILDDIR)/README.md;
echo -e "$$ echo \"oxide cli installed!\"\n" >> $(BUILDDIR)/README.md;
echo -e "# Run it!" >> $(BUILDDIR)/README.md;
echo -e "$$ oxide -h" >> $(BUILDDIR)/README.md;
echo -e "\`\`\`\n\n" >> $(BUILDDIR)/README.md;
endef

# If running on a Mac you will need:
# 	brew install filosottile/musl-cross/musl-cross
.PHONY: release
release: src/*.rs Cargo.toml ## Builds the cross-compiled binaries, naming them in such a way for release (eg. binary-OS-ARCH).
	@echo "+ $@"
	$(foreach TARGET,$(CROSS_TARGETS), $(call buildrelease,$(TARGET)))

.PHONY: tag
tag: ## Create a new git tag to prepare to build a release.
	git tag -sa $(VERSION) -m "$(VERSION)"
	@echo "Run git push origin $(VERSION) to push your new tag to GitHub and trigger a release."

.PHONY: AUTHORS
AUTHORS:
	@$(file >$@,# This file lists all individuals having contributed content to the repository.)
	@$(file >>$@,# For how it is generated, see `make AUTHORS`.)
	@echo "$(shell git log --format='\n%aN <%aE>' | LC_ALL=C.UTF-8 sort -uf)" >> $@

.PHONY: clean
clean: ## Cleanup any build binaries or packages.
	@echo "+ $@"
	$(RM) -r $(BUILDDIR)

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | sed 's/^[^:]*://g' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check_defined = \
    $(strip $(foreach 1,$1, \
	$(call __check_defined,$1,$(strip $(value 2)))))

__check_defined = \
    $(if $(value $1),, \
    $(error Undefined $1$(if $2, ($2))$(if $(value @), \
    required by target `$@')))

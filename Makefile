SHELL := /bin/bash
.SHELLFLAGS := -eo pipefail -c

LIGATURIZER_DIR := Ligaturizer
OUTPUT_DIR := fonts
LIG_OUTPUT_DIR := $(LIGATURIZER_DIR)/fonts/output
FIRA_MONO_TARGET_DIR := $(LIGATURIZER_DIR)/fonts/fira-mono
VARIANT_SCRIPT := scripts/apply_fira_code_variants.py

FIRA_MONO_VERSION := 4.106
FIRA_MONO_ARCHIVE := Fira-$(FIRA_MONO_VERSION).zip
FIRA_MONO_DIR := Fira-$(FIRA_MONO_VERSION)
FIRA_MONO_URL := https://github.com/mozilla/Fira/archive/refs/tags/$(FIRA_MONO_VERSION).zip

FIRA_CODE_VERSION := 6.2
FIRA_CODE_ARCHIVE := Fira_Code_v$(FIRA_CODE_VERSION).zip
FIRA_CODE_DIR := Fira_Code_v$(FIRA_CODE_VERSION)
FIRA_CODE_URL := https://github.com/tonsky/FiraCode/releases/download/$(FIRA_CODE_VERSION)/$(FIRA_CODE_ARCHIVE)

FIRA_MONO_WEIGHTS := Regular Medium Bold
FIRA_MONO_NAMES := $(addprefix FiraMono-,$(FIRA_MONO_WEIGHTS))
FIRA_CODE_NAMES := $(addprefix FiraCode-,$(FIRA_MONO_WEIGHTS))

SOURCE_FONTS := $(addprefix $(FIRA_MONO_DIR)/otf/,$(addsuffix .otf,$(FIRA_MONO_NAMES)))
VARIANT_FONTS := $(addprefix $(FIRA_CODE_DIR)/ttf/,$(addsuffix .ttf,$(FIRA_CODE_NAMES)))
LIG_FONTS := $(addprefix $(LIG_OUTPUT_DIR)/LigaFiraMono-,$(addsuffix .otf,$(FIRA_MONO_WEIGHTS)))
FINAL_FONTS := $(addprefix $(OUTPUT_DIR)/LigaFiraMono-,$(addsuffix .otf,$(FIRA_MONO_WEIGHTS)))

.DEFAULT_GOAL := all
.SECONDARY: $(LIG_FONTS)

.PHONY: all build deps cleanup clean

all: build

build: deps $(FINAL_FONTS)

deps:
	@for tool in curl git unzip; do \
		if ! command -v "$$tool" >/dev/null 2>&1; then \
			echo "$$tool is required." >&2; \
			exit 1; \
		fi; \
	done
	@if ! command -v fontforge >/dev/null 2>&1; then \
		if ! command -v brew >/dev/null 2>&1; then \
			echo "Homebrew is required to install fontforge; please install Homebrew first." >&2; \
			exit 1; \
		fi; \
		brew install fontforge; \
	fi

cleanup:
	rm -rf $(LIGATURIZER_DIR) $(FIRA_MONO_DIR) $(FIRA_CODE_DIR)

$(OUTPUT_DIR):
	mkdir -p $@

$(FIRA_MONO_ARCHIVE):
	curl --fail --location --retry 3 --output "$@.tmp" "$(FIRA_MONO_URL)"
	unzip -tq "$@.tmp"
	mv "$@.tmp" "$@"

$(FIRA_CODE_ARCHIVE):
	curl --fail --location --retry 3 --output "$@.tmp" "$(FIRA_CODE_URL)"
	unzip -tq "$@.tmp"
	mv "$@.tmp" "$@"

$(FIRA_MONO_DIR)/.extracted: $(FIRA_MONO_ARCHIVE)
	rm -rf $(FIRA_MONO_DIR)
	unzip -q "$<" '$(FIRA_MONO_DIR)/otf/FiraMono-*.otf'
	@for font in $(SOURCE_FONTS); do \
		test -f "$$font"; \
	done
	touch $@

$(FIRA_CODE_DIR)/.extracted: $(FIRA_CODE_ARCHIVE)
	rm -rf $(FIRA_CODE_DIR)
	mkdir -p $(FIRA_CODE_DIR)
	unzip -q "$<" $(addprefix ttf/,$(addsuffix .ttf,$(FIRA_CODE_NAMES))) -d $(FIRA_CODE_DIR)
	@for font in $(VARIANT_FONTS); do \
		test -f "$$font"; \
	done
	touch $@

$(FIRA_MONO_DIR)/otf/FiraMono-%.otf: $(FIRA_MONO_DIR)/.extracted
	@test -f "$@"

$(FIRA_CODE_DIR)/ttf/FiraCode-%.ttf: $(FIRA_CODE_DIR)/.extracted
	@test -f "$@"

$(LIGATURIZER_DIR)/.git:
	git clone --depth 1 https://github.com/ToxicFrog/Ligaturizer.git $(LIGATURIZER_DIR)

$(LIGATURIZER_DIR)/build.py $(LIGATURIZER_DIR)/ligatures.py: $(LIGATURIZER_DIR)/.git
	@test -f "$@"

$(LIGATURIZER_DIR)/fonts/fira/.git: $(LIGATURIZER_DIR)/.git
	git -C $(LIGATURIZER_DIR) submodule update --init --depth 1 fonts/fira

$(FIRA_MONO_TARGET_DIR)/.prepared: $(SOURCE_FONTS) $(LIGATURIZER_DIR)/.git
	rm -rf $(FIRA_MONO_TARGET_DIR)
	mkdir -p $(FIRA_MONO_TARGET_DIR)
	cp $(SOURCE_FONTS) $(FIRA_MONO_TARGET_DIR)/
	@for font in $(FIRA_MONO_NAMES); do \
		test -f "$(FIRA_MONO_TARGET_DIR)/$$font.otf"; \
	done
	touch $@

$(LIGATURIZER_DIR)/.patched: Makefile $(LIGATURIZER_DIR)/build.py $(LIGATURIZER_DIR)/ligatures.py
	@tmp=$$(mktemp) && \
	awk 'BEGIN { in_prefixed=0; in_renamed=0 } \
	/^prefixed_fonts[[:space:]]*=/ { \
		print "prefixed_fonts = ["; \
		print "]"; \
		in_prefixed=1; next; \
	} \
	in_prefixed { \
		if ($$0 ~ /^[[:space:]]*]/) { in_prefixed=0 } \
		next; \
	} \
	/^renamed_fonts[[:space:]]*=/ { \
		print "renamed_fonts = {"; \
		print "  '\''fonts/fira-mono/FiraMono-*.otf'\'': '\''Liga Fira Mono'\''"; \
		print "}"; \
		in_renamed=1; \
		if ($$0 ~ /}/) { in_renamed=0 } \
		next; \
	} \
	in_renamed { \
		if ($$0 ~ /^[[:space:]]*}/) { in_renamed=0 } \
		next; \
	} \
	{ print }' "$(LIGATURIZER_DIR)/build.py" > $$tmp && mv $$tmp "$(LIGATURIZER_DIR)/build.py"
	@tmp=$$(mktemp) && \
	awk 'BEGIN { \
		skip=0; \
		targets["    {   # &&"]=1;  \
		targets["    {   # ~@"]=1;  \
		targets["    {   # \\/"]=1; \
		targets["    {   # .?"]=1;  \
		targets["    {   # ?:"]=1;  \
		targets["    {   # ?="]=1;  \
		targets["    {   # ?."]=1;  \
		targets["    {   # ??"]=1;  \
		targets["    {   # ;;"]=1;  \
		targets["    {   # /\\"]=1; \
	} \
	targets[$$0] { skip=1; next } \
	skip && $$0 ~ /^[[:space:]]*},[[:space:]]*$$/ { skip=0; next } \
	skip { next } \
	{ print }' "$(LIGATURIZER_DIR)/ligatures.py" > $$tmp && mv $$tmp "$(LIGATURIZER_DIR)/ligatures.py"
	touch $@

$(LIGATURIZER_DIR)/.built: $(LIGATURIZER_DIR)/.patched $(FIRA_MONO_TARGET_DIR)/.prepared $(LIGATURIZER_DIR)/fonts/fira/.git
	$(MAKE) -C $(LIGATURIZER_DIR) without-characters
	@for font in $(LIG_FONTS); do \
		test -f "$$font"; \
	done
	touch $@

$(LIG_OUTPUT_DIR)/LigaFiraMono-%.otf: $(LIGATURIZER_DIR)/.built
	@test -f "$@"

$(OUTPUT_DIR)/LigaFiraMono-%.otf: $(LIG_OUTPUT_DIR)/LigaFiraMono-%.otf $(FIRA_CODE_DIR)/ttf/FiraCode-%.ttf $(VARIANT_SCRIPT) | $(OUTPUT_DIR)
	fontforge -lang=py -script $(VARIANT_SCRIPT) "$<" "$(word 2,$^)" "$@"

clean: cleanup
	rm -rf $(OUTPUT_DIR)

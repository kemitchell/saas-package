CFCM=node_modules/.bin/commonform-commonmark
CFDOCX=node_modules/.bin/commonform-docx
CFHTML=node_modules/.bin/commonform-html
CRITIQUE=node_modules/.bin/commonform-critique
JSON=node_modules/.bin/json
LINT=node_modules/.bin/commonform-lint

VERSION=$(shell (git diff-index --quiet HEAD && git describe --exact-match --tags 2>/dev/null | sed 's/v/Version /'))

DOCXFLAGS=--edition "$(or $(VERSION),Development Draft)" --indent-margins --left-align-title --number outline --styles configuration/styles.json

BUILD=build
FORMS=arbitration base insurance order patent publicity support uptime
MARKDOWN=$(addsuffix .md,$(FORMS))
DOCX=$(addprefix $(BUILD)/,$(MARKDOWN:.md=.docx))
PDF=$(addprefix $(BUILD)/,$(MARKDOWN:.md=.pdf))
ODT=$(addprefix $(BUILD)/,$(MARKDOWN:.md=.odt))
HTML=$(addprefix $(BUILD)/,$(MARKDOWN:.md=.html))
COMMONFORMS=$(addprefix $(BUILD)/,$(MARKDOWN:.md=.form.json))

all: $(COMMONFORMS) $(DOCX) $(ODT) $(HTML) $(PDF)

%.pdf: %.docx
	unoconv -o $@ $<

%.odt: %.docx
	unoconv -o $@ $<

$(BUILD)/%.docx: %$(BUILD)/.form.json $(BUILD)/%.directions.json configuration/blanks.json configuration/%.options configuration/%.signatures.json configuration/styles.json | $(CFDOCX) $(BUILD)
	$(CFDOCX) $(DOCXFLAGS) $(shell cat configuration/$*.options) --directions $(BUILD)/$*.directions.json --values configuration/blanks.json --signatures configuration/$*.signatures.json $(BUILD)/$*.form.json > $@

$(BUILD)/%.docx: $(BUILD)/%.form.json $(BUILD)/%.directions.json configuration/blanks.json configuration/%.options configuration/no-signatures.json configuration/styles.json | $(CFDOCX) $(BUILD)
	$(CFDOCX) $(DOCXFLAGS) $(shell cat configuration/$*.options) --directions $(BUILD)/$*.directions.json --values configuration/blanks.json --signatures configuration/no-signatures.json $(BUILD)/$*.form.json > $@

$(BUILD)/%.html: $(BUILD)/%.form.json $(BUILD)/%.directions.json configuration/blanks.json configuration/%.options | $(CFHTML) $(BUILD)
	$(CFHTML) --html5 $(shell cat configuration/$*.options) --directions $(BUILD)/$*.directions.json --values configuration/blanks.json < $(BUILD)/$*.form.json > $@

$(BUILD)/%.parsed.json: %.md | $(CFCM) $(BUILD)
	$(CFCM) parse < $< > $@

$(BUILD)/%.form.json: $(BUILD)/%.parsed.json | $(JSON) $(BUILD)
	$(JSON) form < $< > $@

$(BUILD)/%.directions.json: $(BUILD)/%.parsed.json | $(JSON) $(BUILD)
	$(JSON) directions < $< > $@

$(BUILD):
	mkdir $(BUILD)

$(CFHTML) $(CFDOCX) $(CFCM) $(JSON):
	npm install

.PHONY: clean lint critique docker

clean:
	rm -rf $(BUILD)

lint: $(COMMONFORMS) | $(LINT)
	for form in $(COMMONFORMS); do echo "\n$$form" ; $(LINT) < $$form | json -a message | sort -u | fgrep -v "is used only once" ; done

critique: $(COMMONFORMS) | $(CRITIQUE)
	for form in $(COMMONFORMS); do echo "\n$$form" ; $(CRITIQUE) < $$form | json -a message | sort -u ; done

docker:
	docker build -t saas-passport .
	docker run --name saas-passport saas-passport
	docker cp saas-passport:/workdir/$(BUILD) .
	docker rm saas-passport

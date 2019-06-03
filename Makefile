CFCM=node_modules/.bin/commonform-commonmark
CFDOCX=node_modules/.bin/commonform-docx
CRITIQUE=node_modules/.bin/commonform-critique
JSON=node_modules/.bin/json
LINT=node_modules/.bin/commonform-lint

DOCXFLAGS=--indent-margins --left-align-title --number outline --styles styles.json

BUILD=build
FORMS=arbitration base insurance order patent publicity support uptime
MARKDOWN=$(addsuffix .md,$(FORMS))
DOCX=$(addprefix $(BUILD)/,$(MARKDOWN:.md=.docx))
PDF=$(addprefix $(BUILD)/,$(MARKDOWN:.md=.pdf))
COMMONFORMS=$(addprefix $(BUILD)/,$(MARKDOWN:.md=.form.json))

all: $(COMMONFORMS) $(DOCX) $(PDF)

%.pdf: %.docx
	unoconv $<

$(BUILD)/%.docx: %$(BUILD)/.form.json $(BUILD)/%.values.json configuration/%.options %.signatures.json styles.json | $(CFDOCX) $(BUILD)
	$(CFDOCX) $(DOCXFLAGS) $(shell cat configuration/$*.options) --signatures $*.signatures.json $(BUILD)/$*.form.json $(BUILD)/$*.values.json > $@

$(BUILD)/%.docx: $(BUILD)/%.form.json $(BUILD)/%.values.json configuration/%.options no-signatures.json styles.json | $(CFDOCX) $(BUILD)
	$(CFDOCX) $(DOCXFLAGS) $(shell cat configuration/$*.options) --signatures no-signatures.json $(BUILD)/$*.form.json $(BUILD)/$*.values.json > $@

$(BUILD)/%.values.json: $(BUILD)/%.directions.json blanks.json | $(BUILD)
	node make-directions.js $^ > $@

$(BUILD)/%.parsed.json: %.md | $(CFCM) $(BUILD)
	$(CFCM) parse < $< > $@

$(BUILD)/%.form.json: $(BUILD)/%.parsed.json | $(JSON) $(BUILD)
	$(JSON) form < $< > $@

$(BUILD)/%.directions.json: $(BUILD)/%.parsed.json | $(JSON) $(BUILD)
	$(JSON) directions < $< > $@

$(BUILD):
	mkdir $(BUILD)

$(CFDOCX) $(CFCM) $(JSON):
	npm install

.PHONY: clean lint critique

clean:
	rm -rf $(BUILD)

lint: $(COMMONFORMS) | $(LINT)
	for form in $(COMMONFORMS); do echo "\n$$form" ; $(LINT) < $$form | json -a message | sort -u | fgrep -v "is used only once" ; done

critique: $(COMMONFORMS) | $(CRITIQUE)
	for form in $(COMMONFORMS); do echo "\n$$form" ; $(CRITIQUE) < $$form | json -a message | sort -u ; done

CFCM=node_modules/.bin/commonform-commonmark
CFDOCX=node_modules/.bin/commonform-docx
JSON=node_modules/.bin/json

DOCXFLAGS=--indent-margins --left-align-title --number outline --styles styles.json

BUILD=build
FORMS=arbitration base insurance order patent publicity support uptime
MARKDOWN=$(addsuffix .md,$(FORMS))
DOCX=$(addprefix $(BUILD)/,$(MARKDOWN:.md=.docx))
PDF=$(addprefix $(BUILD)/,$(MARKDOWN:.md=.pdf))

all: $(DOCX) $(PDF)

%.pdf: %.docx
	unoconv $<

$(BUILD)/%.docx: %.form.json %.values.json %.options %.signatures.json styles.json | $(CFDOCX) $(BUILD)
	$(CFDOCX) $(DOCXFLAGS) $(shell cat $*.options) --signatures $*.signatures.json $*.form.json $*.values.json > $@

$(BUILD)/%.docx: %.form.json %.values.json %.options no-signatures.json styles.json | $(CFDOCX) $(BUILD)
	$(CFDOCX) $(DOCXFLAGS) $(shell cat $*.options) --signatures no-signatures.json $*.form.json $*.values.json > $@

%.values.json: %.directions.json blanks.json
	node make-directions.js $^ > $@

%.parsed.json: %.md | $(CFCM)
	$(CFCM) parse < $< > $@

%.form.json: %.parsed.json | $(JSON)
	$(JSON) form < $< > $@

%.directions.json: %.parsed.json | $(JSON)
	$(JSON) directions < $< > $@

$(BUILD):
	mkdir $(BUILD)

$(CFDOCX) $(CFCM) $(JSON):
	npm install

.PHONY: clean

clean:
	rm -rf $(BUILD)

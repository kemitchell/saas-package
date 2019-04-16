CFTEMPLATE=node_modules/.bin/cftemplate
COMMONFORM=node_modules/.bin/commonform
DOCXFLAGS=-f docx --indent-margins --left-align-title -n outline --styles styles.json

BUILD=build
TEMPLATES=$(wildcard *.cftemplate)
CFORM=$(TEMPLATES:.cftemplate=.cform)
DOCX=$(addprefix $(BUILD)/,$(TEMPLATES:.cftemplate=.docx))
PDF=$(addprefix $(BUILD)/,$(TEMPLATES:.cftemplate=.pdf))
ALL=$(CFORM) $(DOCX) $(PDF)

all: $(DOCX) $(PDF)

%.pdf: %.docx
	unoconv $<

$(BUILD)/%.docx: %.cform %.options %.json blanks.json styles.json | $(COMMONFORM) $(BUILD)
	$(COMMONFORM) render $(DOCXFLAGS) $(shell cat $*.options) --blanks blanks.json --signatures $*.json $< > $@

.INTERMEDIATE: $(CFORM)

%.cform: %.cftemplate | $(CFTEMPLATE)
	$(CFTEMPLATE) $< > $@

$(BUILD):
	mkdir $(BUILD)

$(CFTEMPLATE) $(COMMONFORM):
	npm install

.PHONY: clean

clean:
	rm -f $(BUILD)

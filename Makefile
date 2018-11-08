CFTEMPLATE=node_modules/.bin/cftemplate
COMMONFORM=node_modules/.bin/commonform
DOCXFLAGS=-f docx --indent-margins --left-align-title -n outline --styles styles.json

TEMPLATES=$(wildcard *.cftemplate)
CFORM=$(TEMPLATES:.cftemplate=.cform)
DOCX=$(TEMPLATES:.cftemplate=.docx)
PDF=$(TEMPLATES:.cftemplate=.pdf)
ALL=$(CFORM) $(DOCX) $(PDF)

all: $(CFORM) $(DOCX) $(PDF)

%.pdf: %.docx
	unoconv $<

%.docx: %.cform %.options %.json blanks.json styles.json | $(COMMONFORM)
	$(COMMONFORM) render $(DOCXFLAGS) $(shell cat $*.options) --blanks blanks.json --signatures $*.json $< > $@

%.cform: %.cftemplate | $(CFTEMPLATE)
	$(CFTEMPLATE) $< > $@

$(CFTEMPLATE) $(COMMONFORM):
	npm install

.PHONY: clean

clean:
	rm -f $(ALL)

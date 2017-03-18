MANDIR      = $(DESTDIR)/usr/share/man/man1
LICENSEDIR  = $(DESTDIR)/usr/share/licenses/lux
UDEVDIR     = $(DESTDIR)/etc/udev/rules.d
BINDIR      = $(DESTDIR)/usr/bin
UDEVRULE    = rules.d/99-lux.rules
MANPAGE     = lux.1.gz

$(MANPAGE):
	help2man -n 'Shell script to easily control brightness on backlight controllers.' \
		-N -h -h -v -v src/lux.sh | gzip - > $(MANPAGE)

install: $(MANPAGE)
	mkdir -p $(MANDIR)
	mkdir -p $(LICENSEDIR)
	mkdir -p $(UDEVDIR)
	mkdir -p $(BINDIR)
	chmod 644 $<
	chmod 644 LICENSE
	chmod 644 $(UDEVRULE)
	chmod 755 src/lux.sh
	cp $< $(MANDIR)/$<
	cp LICENSE $(LICENSEDIR)/LICENSE
	cp $(UDEVRULE) $(UDEVDIR)/99-lux.rules
	cp src/lux.sh $(BINDIR)/lux

uninstall:
	$(RM) -r $(LICENSEDIR)
	$(RM) $(MANDIR)/$(MANPAGE) $(UDEVDIR)/$(UDEVRULE) $(BINDIR)/lux

.PHONY: install uninstall

MANDIR      = $(DESTDIR)/usr/share/man/man1
LICENSEDIR  = $(DESTDIR)/usr/share/licenses/lux
UDEVDIR     = $(DESTDIR)/etc/udev/rules.d
BINDIR      = $(DESTDIR)/usr/bin

PKGNAME     = lux
SCRIPT      = $(PKGNAME).sh
UDEVRULE    = 99-$(PKGNAME).rules
MANPAGE     = $(PKGNAME).1.gz

install: $(MANPAGE)
	mkdir -p $(MANDIR)
	mkdir -p $(LICENSEDIR)
	mkdir -p $(UDEVDIR)
	mkdir -p $(BINDIR)
	chmod 644 $<
	chmod 644 LICENSE
	chmod 644 $(UDEVRULE)
	chmod 755 $(SCRIPT)
	cp $< $(MANDIR)/$<
	cp LICENSE $(LICENSEDIR)/LICENSE
	cp $(UDEVRULE) $(UDEVDIR)/$(UDEVRULE)
	cp $(SCRIPT) $(BINDIR)/$(PKGNAME)

$(MANPAGE):
	help2man -n 'Shell script to easily control brightness.' \
		-N -h -h -v -v ./$(SCRIPT) | gzip - > $(MANPAGE)

uninstall:
	$(RM) -r $(LICENSEDIR)
	$(RM) $(MANDIR)/$(MANPAGE) $(UDEVDIR)/$(UDEVRULE) $(BINDIR)/$(PKGNAME)

.PHONY: install uninstall

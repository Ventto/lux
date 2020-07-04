LICENSEDIR  = $(DESTDIR)/usr/share/licenses/lux
UDEVDIR     = $(DESTDIR)/etc/udev/rules.d
BINDIR      = $(DESTDIR)/usr/bin

PKGNAME     = lux
SCRIPT      = $(PKGNAME).sh
UDEVRULE    = 99-$(PKGNAME).rules

install:
	mkdir -p $(LICENSEDIR)
	mkdir -p $(UDEVDIR)
	mkdir -p $(BINDIR)
	chmod 644 LICENSE
	chmod 644 $(UDEVRULE)
	chmod 755 $(SCRIPT)
	cp LICENSE $(LICENSEDIR)/LICENSE
	cp $(UDEVRULE) $(UDEVDIR)/$(UDEVRULE)
	cp $(SCRIPT) $(BINDIR)/$(PKGNAME)

uninstall:
	$(RM) -r $(LICENSEDIR)
	$(RM) $(UDEVDIR)/$(UDEVRULE) $(BINDIR)/$(PKGNAME)

.PHONY: install uninstall

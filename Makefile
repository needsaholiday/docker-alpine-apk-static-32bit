SEED = http://dl-3.alpinelinux.org/alpine
VERSION = v3.9
ARCH = x86

CURL = curl -sL

sbin/apk.static: etc/apk/repositories
	$(eval MIRROR = $(shell sed 1q etc/apk/repositories)/$(ARCH)/)
	$(eval APK = $(shell $(CURL) $(MIRROR) \
		|sed -n 's:.*\(apk-tools-static.*apk\).*$$:\1:p'))
	$(CURL) -z $(APK) -o $(APK) $(MIRROR)$(APK) && tar xzf $(APK) $@

etc/apk/repositories:	MIRRORS.txt
	sed 's:$$:$(VERSION)/main:' $< >$@

MIRRORS.txt:
	$(CURL) -z $@ -o $@ $(SEED)/$@ \

clean :
	-rm -rf MIRRORS.txt *.apk etc/ sbin/

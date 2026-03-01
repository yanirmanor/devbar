PREFIX ?= /usr/local

build:
	swift build -c release --disable-sandbox

install: build
	install -d $(PREFIX)/bin
	install .build/release/DevBar $(PREFIX)/bin/devbar

uninstall:
	rm -f $(PREFIX)/bin/devbar

clean:
	swift package clean

.PHONY: build install uninstall clean

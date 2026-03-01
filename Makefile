PREFIX ?= /usr/local
APP_NAME = DevBar.app
APP_DIR = $(APP_NAME)/Contents

build:
	swift build -c release --disable-sandbox

app: build
	mkdir -p "$(APP_DIR)/MacOS"
	mkdir -p "$(APP_DIR)/Resources"
	cp .build/release/DevBar "$(APP_DIR)/MacOS/DevBar"
	cp assets/Info.plist "$(APP_DIR)/Info.plist"
	if [ -f assets/AppIcon.icns ]; then cp assets/AppIcon.icns "$(APP_DIR)/Resources/AppIcon.icns"; fi

install-app: app
	cp -R $(APP_NAME) /Applications/$(APP_NAME)

install: build
	install -d $(PREFIX)/bin
	install .build/release/DevBar $(PREFIX)/bin/devbar

uninstall:
	rm -f $(PREFIX)/bin/devbar
	rm -rf /Applications/$(APP_NAME)

clean:
	swift package clean
	rm -rf $(APP_NAME)

.PHONY: build app install install-app uninstall clean

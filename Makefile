# Variables
TARGET := zig-out/bin
INSTALL_DIR := /usr/local/bin
BINARY := ztatusbar
OPTIMIZE := ReleaseFast
# OPTIMIZE := ReleaseSafe

all: build

build:
	zig build -Doptimize=$(OPTIMIZE)

install: build
	install -m 0755 $(TARGET)/$(BINARY) $(INSTALL_DIR)

uninstall:
	rm -f $(INSTALL_DIR)/$(BINARY)

clean:
	rm -rdf zig-out/ .zig-cache/

.PHONY: all build install uninstall clean

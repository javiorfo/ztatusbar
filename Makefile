TARGET := zig-out/bin
INSTALL_DIR := /usr/local/bin
BINARY := ztatusbar

# ReleaseFast, ReleaseSafe, ReleaseSmall or Debug
OPTIMIZE ?= ReleaseFast

all: build

build:
	@echo "Building with optimization $(OPTIMIZE)"
	zig build -Doptimize=$(OPTIMIZE)

install: build
	install -m 0755 $(TARGET)/$(BINARY) $(INSTALL_DIR)
	@echo "Done!"

uninstall:
	rm -f $(INSTALL_DIR)/$(BINARY)

clean:
	rm -rdf zig-out/ .zig-cache/

.PHONY: all build install uninstall clean

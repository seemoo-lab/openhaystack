APPDIR := OpenHaystack

default:

install-hooks: .pre-commit
	cp .pre-commit .git/hooks/pre-commit

app-autoformat:
	swift-format format -i -r $(APPDIR)
	clang-format -i $(shell find $(APPDIR) -name '*.h' -o -name '*.m')

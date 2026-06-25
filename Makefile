.PHONY: build
build:
	swift build

.PHONY: run
run:
	swift run

.PHONY: test
test:
	swift test

.PHONY: lint
lint:
	swiftlint lint --strict

.PHONY: bundle
bundle:
	bash scripts/bundle.sh

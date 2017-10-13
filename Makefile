VERSION = $(shell grep s.version Binson.podspec | cut -f2 -d= | cut -f1 -d{)
FLAGS = -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

all: lint build test

test:
	swift test ${FLAGS}

build:
	swift build ${FLAGS}

lint:
	swiftlint

clean:
	rm -rf .build *~ .*~ *.log

version:
	@echo ${VERSION}

tag:
	git tag ${VERSION}

pushtag: tag
	git push origin --tags

verify:
	pod spec lint Binson.podspec

format:
	swiftformat --hexliteralcase lowercase --hexgrouping none --ranges nospace --wrapelements beforefirst --self remove Package.swift

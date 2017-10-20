VERSION = $(shell grep s.version Binson.podspec | cut -f2 -d= | cut -f1 -d{)
FLAGS = -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"
BUILD_TOOL?=xcodebuild

all: lint test

test: build
	swift test ${FLAGS}

build:
	swift build ${FLAGS}

lint:
	swiftlint

docs:
	jazzy --theme fullwidth

clean:
	rm -rf .build *~ .*~ *.
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Debug clean
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Release clean
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Test clean

version:
	@echo ${VERSION}

tag:
	git tag -a ${VERSION} -m "New Binson release: ${VERSION}"

pushtag:
	git push --follow-tags

verify:
	pod spec lint Binson.podspec

format:
	swiftformat --hexliteralcase lowercase --hexgrouping none --ranges nospace --wrapelements beforefirst --self remove Package.swift

list:
	xcodebuild -project Binson.xcodeproj  -list

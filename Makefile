VERSION = $(shell grep s.version Binson.podspec | cut -f2 -d= | cut -f1 -d{)
FLAGS = -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"
BUILD_TOOL?=xcodebuild
SWIFT?=swift

XCODE_PROJECT?=Binson.xcodeproj
XCODE_SCHEME?=Binson-Package

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

list:
	$(BUILD_TOOL) -project Binson.xcodeproj  -list

xcodebuild-ios:
	$(BUILD_TOOL) -project $(XCODE_PROJECT) -scheme $(XCODE_SCHEME) -destination "platform=iOS Simulator,name=iPhone 6" build-for-testing test

xcodebuild-osx:
	$(BUILD_TOOL) -project $(XCODE_PROJECT) -scheme $(XCODE_SCHEME) build-for-testing test

dependencies:
	$(SWIFT) package show-dependencies

describe: list dependencies
	$(SWIFT) package describe

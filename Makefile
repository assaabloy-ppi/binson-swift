VERSION       = $(shell grep s.version Binson.podspec | cut -f2 -d= | cut -f1 -d{)

SWIFT         = swift
SWIFT_FLAGS   = -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

BUILD_TOOL    = xcodebuild
XCODE_PROJECT = Binson.xcodeproj
XCODE_SCHEME  = Binson-Package
XCODE         = $(BUILD_TOOL) -project $(XCODE_PROJECT) $(XCODE_FLAGS)
IOS_FLAGS     = -destination "platform=iOS Simulator,name=iPhone 6"
OSX_FLAGS     =

all: lint xcodebuild-ios xcodebuild-osx

test: build
	swift test $(SWIFT_FLAGS)

build:
	swift build $(SWIFT_FLAGS)

lint:
	swiftlint

docs:
	jazzy --theme fullwidth

clean:
	rm -rf .build *~ .*~ *.
	$(XCODE) -configuration Debug clean
	$(XCODE) -configuration Release clean
	$(XCODE) -configuration Test clean

version:
	@echo $(VERSION)

tag:
	git tag -a $(VERSION) -m "New Binson release: $(VERSION)"

pushtag:
	git push --follow-tags

verify:
	pod spec lint Binson.podspec

list:
	$(XCODE) -list

xcodebuild-ios:
	$(XCODE) -scheme $(XCODE_SCHEME) $(IOS_FLAGS) build-for-testing test  | xcpretty && exit ${PIPESTATUS[0]}

xcodebuild-osx:
	$(XCODE) -scheme $(XCODE_SCHEME) $(OSX_FLAGS) build-for-testing test | xcpretty && exit ${PIPESTATUS[0]}

dependencies:
	$(SWIFT) package show-dependencies

describe: list dependencies
	$(SWIFT) package describe

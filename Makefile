VERSION       = $(shell grep s.version Binson.podspec | cut -f2 -d= | cut -f1 -d{)

SWIFT         = swift
SWIFT_FLAGS   = -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

IOS_FLAGS     = -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6S'
OSX_FLAGS     = -sdk macosx

XCODE         = xcodebuild
XCODE_PROJECT = Binson.xcodeproj
XCODE_SCHEME  = Binson-Package
XCODE_FLAGS   =
XCODE_CMD     = $(XCODE) -project $(XCODE_PROJECT) $(XCODE_FLAGS)

all: lint xcodebuild-ios xcodebuild-osx

test: build
	$(SWIFT) test $(SWIFT_FLAGS)

build:
	$(SWIFT) build $(SWIFT_FLAGS)

lint:
	swiftlint

docs:
	jazzy --theme fullwidth

clean:
	rm -rf .build *~ .*~ *.
	$(XCODE_CMD) -configuration Debug clean
	$(XCODE_CMD) -configuration Release clean
	$(XCODE_CMD) -configuration Test clean

version:
	@echo $(VERSION)

tag:
	git tag -a $(VERSION) -m "New Binson release: $(VERSION)"

pushtag:
	git push --follow-tags

verify:
	pod spec lint Binson.podspec

list:
	$(XCODE_CMD) -list

xcodebuild-ios:
	$(XCODE_CMD) -scheme $(XCODE_SCHEME) $(IOS_FLAGS) build-for-testing test  | xcpretty && exit $(PIPESTATUS[0])

xcodebuild-osx:
	$(XCODE_CMD) -scheme $(XCODE_SCHEME) $(OSX_FLAGS) build-for-testing test | xcpretty && exit $(PIPESTATUS[0])

dependencies:
	$(SWIFT_CMD) package show-dependencies

describe: list dependencies
	$(SWIFT_CMD) package describe

coverage:
	$(XCODE_CMD) -scheme $(XCODE_SCHEME) $(OSX_FLAGS) -configuration Debug -enableCodeCoverage YES test
	slather coverage --scheme $(XCODE_SCHEME) --show $(XCODE_PROJECT)

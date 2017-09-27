VERSION = $(shell grep s.version Binson.podspec | cut -f2 -d=)

lint:
	swiftlint

pod-install:
	pod install

pod-update:
	pod update

clean:
	rm -rf .build *~ .*~ *.log

cleaner: clean
	rm -rf Pods

version:
	@echo ${VERSION}

tag:
	git tag ${VERSION}

pushtag: tag
	git push origin --tags
	

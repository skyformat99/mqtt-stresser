appname := mqtt-stresser
namespace := inovex
sources := $(wildcard *.go)

build = GOOS=$(1) GOARCH=$(2) go build -o build/$(appname)-$(1)-$(2)$(3)
static-build = CGO_ENABLED=0 GOOS=$(1) GOARCH=$(2) go build -a -installsuffix cgo -o build/$(appname)-$(1)-$(2)-static$(3) .
tar = cd build && tar -cvzf $(appname)-$(1)-$(2).tar.gz $(appname)-$(1)-$(2)$(3) && rm $(appname)-$(1)-$(2)$(3)
zip = cd build && zip $(appname)-$(1)-$(2).zip $(appname)-$(1)-$(2)$(3) && rm $(appname)-$(1)-$(2)$(3)

.PHONY: all windows darwin linux clean container push-container windows-static darwin-static linux-static windows-compressed linux-compressed darwin-compressed

all: windows darwin linux windows-static darwin-static linux-static

all-static: windows-static darwin-static linux-static

release-files: windows-compressed linux-compressed darwin-compressed

clean:
	rm -rf build/

fmt:
	@gofmt -l -w $(sources)

vendor-deps:
	@echo ">> Fetching dependencies"
	go get github.com/rancher/trash

vendor: vendor-deps
	rm -r vendor/
	${GOPATH}/bin/trash -u
	${GOPATH}/bin/trash

##### LINUX #####
linux: build/$(appname)-linux-amd64

linux-compressed: build/$(appname)-linux-amd64.tar.gz

linux-static: build/$(appname)-linux-amd64-static

build/$(appname)-linux-amd64:
	$(call build,linux,amd64,)

build/$(appname)-linux-amd64.tar.gz: build/$(appname)-linux-amd64
	$(call tar,linux,amd64)

build/$(appname)-linux-amd64-static:
	$(call static-build,linux,amd64,)


##### DARWIN (MAC) #####
darwin: build/$(appname)-darwin-amd64

darwin-compressed: build/$(appname)-darwin-amd64.tar.gz

darwin-static: build/$(appname)-darwin-amd64-static

build/$(appname)-darwin-amd64:
	$(call build,darwin,amd64,)

build/$(appname)-darwin-amd64.tar.gz: build/$(appname)-darwin-amd64
	$(call tar,darwin,amd64)


build/$(appname)-darwin-amd64-static:
	$(call static-build,darwin,amd64,)


##### WINDOWS #####

windows: build/$(appname)-windows-amd64

windows-compressed: build/$(appname)-windows-amd64.zip

windows-static: build/$(appname)-windows-amd64-static

build/$(appname)-windows-amd64:
	$(call build,windows,amd64,.exe)

build/$(appname)-windows-amd64.zip: build/$(appname)-windows-amd64
	$(call zip,windows,amd64,.exe)



build/$(appname)-windows-amd64-static:
	$(call static-build,windows,amd64,)


##### DOCKER #####
container: clean
	docker build \
		--build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")\
		--build-arg VCS_REF=$(shell git rev-parse --short HEAD) \
	 	--build-arg VERSION=$(shell git describe --all | sed  -e  's%tags/%%g'  -e 's%/%.%g' ) \
	 	-t $(namespace)/$(appname) .

	 	docker run -it --rm $(namespace)/$(appname) --help


push-container:
	docker tag $(namespace)/$(appname) $(namespace)/$(appname):$(VERSION)
	docker push $(namespace)/$(appname):$(VERSION)


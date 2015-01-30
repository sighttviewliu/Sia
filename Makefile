# all will build and install developer binaries, which have debugging enabled
# and much faster mining and block constants.
all: install

# fmt calls go fmt on all packages.
fmt:
	go fmt ./...

# install builds and installs developer binaries.
install: fmt
	go install -a -tags=dev ./...

# clean removes all directories that get automatically created during
# development.
clean:
	rm -rf hostdir release whitepaper.aux whitepaper.log whitepaper.pdf         \
		sia.wallet sia/test.wallet sia/hostdir* sia/renterDownload cover

# test runs the short tests for Sia, and aims to always take less than 2
# seconds.
#
# Touching a file in the consensus folder forces the build tag files to be
# rebuilt. This can also be achieved with 'go test -a', however using the '-a'
# flag results in a multi-second compile time, which is undesirable. Leaving
# out both the touch and the '-a' means that sometimes the tests will be run
# using the developer constants, which is very slow.
test: clean fmt
	@touch consensus/blocknode.go
	go test -short -tags=test ./...

#  test-long does a forced rebuild of all packages, and then runs both the
#  short and long tests with the race libraries enabled. test-long aims to be
#  thorough.
test-long: clean fmt
	go test -a -v -race -short -tags=test ./...
	go test -a -v -race -tags=test ./...

# cover runs the long tests and creats html files that show you which lines
# have been hit during testing and how many times each line has been hit.
coverpackages = consensus crypto encoding hash modules/hostdb network siad
cover: clean
	@mkdir -p cover
	@for package in $(coverpackages); do \
		go test -a -v -tags=test -covermode=atomic -coverprofile=cover/$$package.out ./$$package ; \
		go tool cover -html=cover/$$package.out -o=cover/$$package.html ; \
		rm cover/$$package.out ; \
	done

# whitepaper builds the whitepaper from whitepaper.tex. pdflatex has to be
# called twice because references will not update correctly the first time.
whitepaper:
	@pdflatex whitepaper.tex > /dev/null
	pdflatex whitepaper.tex

# dependencies installs all of the dependencies that are required for building
# Sia.
dependencies:
	go install -race std
	go get -u code.google.com/p/gcfg
	go get -u github.com/agl/ed25519
	go get -u github.com/inconshreveable/go-update
	go get -u github.com/laher/goxc
	go get -u github.com/mitchellh/go-homedir
	go get -u github.com/spf13/cobra
	go get -u github.com/stretchr/graceful
	go get -u golang.org/x/crypto/twofish
	go get -u golang.org/x/tools/cmd/cover

# release builds and installs release binaries.
release: dependencies test-long
	go install -a ./...

# xc builds and packages release binaries for all systems by using goxc.
# Cross Compile - makes binaries for windows, linux, and mac, 32 and 64 bit.
xc: dependencies test-long
	goxc -arch="amd64" -bc="linux windows darwin" -d=release -pv=0.2.0          \
		-br=release -pr=beta -include=example-config,LICENSE*,README*           \
		-tasks-=deb,deb-dev,deb-source,go-test
	# Need some command here to make sure that the release constants got used.

.PHONY: all fmt install clean test test-long cover whitepaper dependencies release xc

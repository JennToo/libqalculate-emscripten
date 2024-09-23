DOCKER_CMD = docker run -i --rm -u $(shell id -u):$(shell id -g) \
	-v $(PWD):$(PWD) -w $(1) qalc-builder:local

GMP_FILE := gmp-6.1.2.tar.lz
GMP_URL := https://gmplib.org/download/gmp/$(GMP_FILE)

MPFR_FILE := mpfr-4.2.1.tar.xz
MPFR_URL := https://www.mpfr.org/mpfr-current/$(MPFR_FILE)

LIBQALCULATE_FILE := libqalculate-5.2.0.tar.gz
LIBQALCULATE_URL := https://github.com/Qalculate/libqalculate/releases/download/v5.2.0/$(LIBQALCULATE_FILE)

LIBXML2_FILE := libxml2-2.9.12.tar.gz
LIBXML2_URL := ftp://xmlsoft.org/libxml2/$(LIBXML2_FILE)

.PHONE: all
all: build/libqalculate/.built build/test.html

build/.docker: Dockerfile
	docker build -t qalc-builder:local .
	touch $@

build/$(GMP_FILE):
	mkdir -p build
	curl --fail -L -o $@ $(GMP_URL)

build/$(MPFR_FILE):
	mkdir -p build
	curl --fail -L -o $@ $(MPFR_URL)

build/$(LIBQALCULATE_FILE):
	mkdir -p build
	curl --fail -L -o $@ $(LIBQALCULATE_URL)

build/$(LIBXML2_FILE):
	mkdir -p build
	curl --fail -L -o $@ $(LIBXML2_URL)

build/gmp/.unpacked: build/$(GMP_FILE)
	mkdir -p build/gmp
	tar -C build/gmp --strip-components=1 -xf $<
	touch $@

build/mpfr/.unpacked: build/$(MPFR_FILE)
	mkdir -p build/mpfr
	tar -C build/mpfr --strip-components=1 -xf $<
	touch $@

build/libqalculate/.unpacked: build/$(LIBQALCULATE_FILE)
	mkdir -p build/libqalculate
	tar -C build/libqalculate --strip-components=1 -xf $<
	touch $@

build/libxml2/.unpacked: build/$(LIBXML2_FILE)
	mkdir -p build/libxml2
	tar -C build/libxml2 --strip-components=1 -xf $<
	touch $@

build/gmp/.built: build/gmp/.unpacked build/.docker | build/prefix
	$(call DOCKER_CMD,$(abspath build/gmp)) emconfigure ./configure --disable-assembly --host none --enable-cxx  --prefix=$(PWD)/build/prefix CLFAGS=-O3 CXXFLAGS=-O3
	$(call DOCKER_CMD,$(abspath build/gmp)) emmake make -j8
	$(call DOCKER_CMD,$(abspath build/gmp)) emmake make install
	touch $@

build/mpfr/.built: build/mpfr/.unpacked build/gmp/.built build/.docker | build/prefix
	$(call DOCKER_CMD,$(abspath build/mpfr)) emconfigure ./configure --host none --prefix=$(PWD)/build/prefix --with-gmp=$(PWD)/build/prefix CLFAGS=-O3 CXXFLAGS=-O3
	$(call DOCKER_CMD,$(abspath build/mpfr)) emmake make -j8
	$(call DOCKER_CMD,$(abspath build/mpfr)) emmake make install
	touch $@

build/libxml2/.built: build/libxml2/.unpacked build/.docker | build/prefix
	$(call DOCKER_CMD,$(abspath build/libxml2)) emconfigure ./configure --host none --prefix=$(PWD)/build/prefix CLFAGS=-O3 CXXFLAGS=-O3
	$(call DOCKER_CMD,$(abspath build/libxml2)) emmake make -j8
	$(call DOCKER_CMD,$(abspath build/libxml2)) emmake make install
	touch $@

build/libqalculate/.built: build/libqalculate/.unpacked build/mpfr/.built build/gmp/.built build/libxml2/.built build/.docker | build/prefix
	$(call DOCKER_CMD,$(abspath build/libqalculate)) emconfigure ./configure \
		--prefix=$(PWD)/build/prefix \
		--without-libcurl \
		--without-icu \
		CFLAGS="-I$(PWD)/build/prefix/include -O3" \
		CXXFLAGS="-I$(PWD)/build/prefix/include -O3" \
		LDFLAGS=-L$(PWD)/build/prefix/lib \
		PKG_CONFIG_PATH=$(PWD)/build/prefix/lib/pkgconfig
	$(call DOCKER_CMD,$(abspath build/libqalculate)) emmake make -j8
	$(call DOCKER_CMD,$(abspath build/libqalculate)) emmake make install
	touch $@

build/test.html: src/main.cpp build/libqalculate/.built
	$(call DOCKER_CMD,$(PWD)) em++ -o $@ src/main.cpp -I$(PWD)/build/prefix/include -L$(PWD)/build/prefix/lib -lqalculate -lmpfr -lgmp -lxml2 -O3

build/prefix:
	mkdir -p $@

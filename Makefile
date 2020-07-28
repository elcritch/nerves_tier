PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/build
DESTDIR= $(PREFIX)/

all: zerotier-1.4.6.tar.gz compile install
	@echo compiled zerotier
	@echo zerotier builddir: $(BUILD)/

zerotier-1.4.6.tar.gz:
	mkdir -p $(BUILD)/ $(BUILD)/src
	curl -L https://github.com/zerotier/ZeroTierOne/archive/1.4.6.tar.gz --output $(BUILD)/zerotier-1.4.6.tar.gz
	tar xvf $(BUILD)/zerotier-*.tar.gz -C $(BUILD)/src --strip-components=1
	sed -i.bak 's/^MINIUPNPC_IS_NEW_ENOUGH/#MINIUPNPC_IS_NEW_ENOUGH/' $(BUILD)/src/make-linux.mk

compile:
	CFLAGS="-fPIC" CXXFLAGS="-fPIC" $(MAKE) -C $(BUILD)/src/ 

install:
	DESTDIR=$(DESTDIR) $(MAKE) -C $(BUILD)/src/ install

clean:
	rm $(BUILD)/zerotier-*.tar.gz
	rm -Rf $(BUILD)/src/*
	rm -Rf $(BUILD)/priv/usr $(BUILD)/priv/var

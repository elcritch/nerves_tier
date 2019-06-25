
all: zerotier-1.2.12.tar.gz compile install
	@echo compiled zerotier

zerotier-1.2.12.tar.gz:
	curl -L https://github.com/zerotier/ZeroTierOne/archive/1.2.12.tar.gz --output zerotier-1.2.12.tar.gz
	tar xvf zerotier-*.tar.gz -C src --strip-components=1

compile:
	$(MAKE) -C src/ 

install:
	DESTDIR=../priv/ $(MAKE) -C src/ install

clean:
	rm zerotier-*.tar.gz
	rm -Rf src/*

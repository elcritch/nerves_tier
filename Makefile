
all: download
	@echo hello

download: 
	curl -L https://github.com/zerotier/ZeroTierOne/archive/1.2.12.tar.gz --output zerotier-1.2.12.tar.gz



clean:
	rm zerotier-*.tar.gz

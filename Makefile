# Makefile for building the project

app_name=talk_matterbridge

matterbridge_version=1.23.2

project_dir=$(CURDIR)/../$(app_name)
build_dir=$(CURDIR)/build/artifacts
appstore_dir=$(build_dir)/appstore
source_dir=$(build_dir)/source
sign_dir=$(build_dir)/sign
package_name=$(app_name)
cert_dir=$(HOME)/.nextcloud/certificates
version+=master

all: binaries appstore

release: binaries appstore create-tag

.PHONY: binaries
binaries:
	rm -rf "$(project_dir)/bin"
	mkdir -p "$(project_dir)/bin"
	curl -L --output "$(project_dir)/bin/matterbridge-$(matterbridge_version)-linux-32bit" "https://github.com/42wim/matterbridge/releases/download/v$(matterbridge_version)/matterbridge-$(matterbridge_version)-linux-32bit"
	chmod +x "$(project_dir)/bin/matterbridge-$(matterbridge_version)-linux-32bit"
	curl -L --output "$(project_dir)/bin/matterbridge-$(matterbridge_version)-linux-64bit" "https://github.com/42wim/matterbridge/releases/download/v$(matterbridge_version)/matterbridge-$(matterbridge_version)-linux-64bit"
	chmod +x "$(project_dir)/bin/matterbridge-$(matterbridge_version)-linux-64bit"
	curl -L --output "$(project_dir)/bin/matterbridge-$(matterbridge_version)-linux-arm64" "https://github.com/42wim/matterbridge/releases/download/v$(matterbridge_version)/matterbridge-$(matterbridge_version)-linux-arm64"
	chmod +x "$(project_dir)/bin/matterbridge-$(matterbridge_version)-linux-arm64"
	curl -L --output "$(project_dir)/bin/matterbridge-$(matterbridge_version)-linux-armv6" "https://github.com/42wim/matterbridge/releases/download/v$(matterbridge_version)/matterbridge-$(matterbridge_version)-linux-armv6"
	chmod +x "$(project_dir)/bin/matterbridge-$(matterbridge_version)-linux-armv6"

create-tag:
	git tag -a v$(version) -m "Tagging the $(version) release."
	git push origin v$(version)

appstore:
	rm -rf $(build_dir)
	mkdir -p $(sign_dir)
	rsync -a \
	--exclude=.git \
	--exclude=/build \
	--exclude=Makefile \
	--exclude=README.md \
	$(project_dir)/ $(sign_dir)/$(app_name)
	@if [ -f $(cert_dir)/$(app_name).key ]; then \
		echo "Signing app files …"; \
		php ../../occ integrity:sign-app \
			--privateKey=$(cert_dir)/$(app_name).key\
			--certificate=$(cert_dir)/$(app_name).crt\
			--path=$(sign_dir)/$(app_name); \
	fi
	tar -czf $(build_dir)/$(app_name)-$(version).tar.gz \
		-C $(sign_dir) $(app_name)
	@if [ -f $(cert_dir)/$(app_name).key ]; then \
		echo "Signing package …"; \
		openssl dgst -sha512 -sign $(cert_dir)/$(app_name).key $(build_dir)/$(app_name)-$(version).tar.gz | openssl base64; \
	fi

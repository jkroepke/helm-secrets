SHELL=/bin/bash

SOPS_VERSION="2.0.8"

SOPS_DEB_URL="https://go.mozilla.org/sops/dist/sops_${SOPS_VERSION}_amd64.deb"
SOPS_DEB_MD5="fda670df3e8b8efccbc66f92864c0556"
SOPS_RPM_URL="https://go.mozilla.org/sops/dist/sops-${SOPS_VERSION}-1.x86_64.rpm"

UNAME := $(shell uname)
ifeq ($(UNAME),Linux)
   LINUX_DISTRO := $(shell lsb_release -is)
endif

HELM_VERSION := $(shell helm version -c --short | cut -d ' ' -f2)

init: sops sopsdiff

sops:
ifeq ($(UNAME), Darwin) #Mac OS
	@brew install sops
else ifeq ($(UNAME), Linux) #Linux
    ifeq ($(LINUX_DISTRO), Ubuntu) #Ubuntu
	@curl ${SOPS_DEB_URL} > /tmp/sops.deb
	@if [ "`/usr/bin/md5sum /tmp/sops.deb | cut -d ' ' -f 1`" == ${SOPS_DEB_MD5} ]; then sudo dpkg -i /tmp/sops.deb; else echo "Wrong MD5";fi
    endif
else
	@rpm -ivh ${SOPS_RPM_URL}
endif

sopsdiff:
	@git config diff.sopsdiffer.textconv "so

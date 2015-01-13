filename = $(lastword $(subst /, ,$(1)))

LINUX_URL = https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.18.tar.xz
LINUX_TARBALL = $(call filename,$(LINUX_URL))
LINUX_DIR = $(LINUX_TARBALL:.tar.xz=)

EDK2_URL = https://github.com/tianocore/edk2/archive/8c83d0c0b9bd102cd905c83b2644a543e9711815.tar.gz
EDK2_TARBALL = $(call filename,$(EDK2_URL))
EDK2_DIR = edk2-$(EDK2_TARBALL:.tar.gz=)

BUSYBOX_URL = http://busybox.net/downloads/busybox-1.23.0.tar.bz2
BUSYBOX_TARBALL = $(call filename,$(BUSYBOX_URL))
BUSYBOX_DIR = $(BUSYBOX_TARBALL:.tar.bz2=)

AARCH64_GCC_URL = http://releases.linaro.org/14.08/components/toolchain/binaries/gcc-linaro-aarch64-linux-gnu-4.9-2014.08_linux.tar.xz
AARCH64_GCC_TARBALL = $(call filename,$(AARCH64_GCC_URL))
AARCH64_GCC_DIR = $(AARCH64_GCC_TARBALL:.tar.xz=)

aarch64-linux-gnu-gcc := toolchains/$(AARCH64_GCC_DIR)

AARCH64_NONE_GCC_URL = http://releases.linaro.org/14.07/components/toolchain/binaries/gcc-linaro-aarch64-none-elf-4.9-2014.07_linux.tar.xz
AARCH64_NONE_GCC_TARBALL = $(call filename,$(AARCH64_NONE_GCC_URL))
AARCH64_NONE_GCC_DIR = $(AARCH64_NONE_GCC_TARBALL:.tar.xz=)

aarch64-none-elf-gcc := toolchains/$(AARCH64_NONE_GCC_DIR)

SHELL = /bin/bash
CURL = curl -L
_NPROCESSORS_ONLN = $(shell getconf _NPROCESSORS_ONLN)
ifneq (,$(shell which ccache))
CCACHE = ccache #
endif

export PATH := $(PATH):$(PWD)/toolchains/$(AARCH64_NONE_GCC_DIR)/bin:$(PWD)/toolchains/$(AARCH64_GCC_DIR)/bin:$(PWD)/linux/usr


# Read stdin, expand ${VAR} environment variables, output to stdout
# http://superuser.com/a/302847
define expand-env-var
awk '{while(match($$0,"[$$]{[^}]*}")) {var=substr($$0,RSTART+2,RLENGTH -3);gsub("[$$]{"var"}",ENVIRON[var])}}1'
endef

ifeq ($(V),1)
  Q :=
  ECHO := @:
else
  Q := @
  ECHO := @echo
endif

all: build-linux build-arm-tf-bl1 build-arm-tf-fip build-rootfs build-dtb

#all: linux/arch/arm64/boot/Image
#all: arm-trusted-firmware/build/fvp/debug/bl1.bin
#all: arm-trusted-firmware/build/fvp/debug/fip.bin
#all: run/filesystem.cpio.gz
#all: optee_linuxdriver/fdts/fvp-foundation-gicv2-psci.dtb

#
# Download rules
#

.linux: downloads/$(LINUX_TARBALL)
	$(ECHO) '  TAR     linux'
	$(Q)rm -rf $(LINUX_DIR)
	$(Q)tar xf downloads/$(LINUX_TARBALL)
	$(Q)rm -rf linux
	$(Q)mv $(LINUX_DIR) linux
	$(Q)touch $@

downloads/$(LINUX_TARBALL):
	$(ECHO) '  CURL    $@'
	$(Q)$(CURL) $(LINUX_URL) -o $@


edk2: downloads/$(EDK2_TARBALL)
	$(ECHO) '  TAR     $@'
	$(Q)rm -rf $(EDK2_DIR)
	$(Q)tar xf downloads/$(EDK2_TARBALL)
	$(Q)rm -rf $@
	$(Q)mv $(EDK2_DIR) $@
	$(Q)touch $@

downloads/$(EDK2_TARBALL):
	$(ECHO) '  CURL    $@'
	$(Q)$(CURL) $(EDK2_URL) -o $@


gen_rootfs/.busybox: downloads/$(BUSYBOX_TARBALL)
	$(ECHO) '  TAR     gen_rootfs/busybox'
	$(Q)rm -rf gen_rootfs/$(BUSYBOX_DIR) gen_rootfs/busybox
	$(Q)cd gen_rootfs && tar xf ../downloads/$(BUSYBOX_TARBALL)
	$(Q)mv gen_rootfs/$(BUSYBOX_DIR) gen_rootfs/busybox
	$(Q)touch $@

downloads/$(BUSYBOX_TARBALL):
	$(ECHO) '  CURL    $@'
	$(Q)$(CURL) $(BUSYBOX_URL) -o $@


toolchains/$(AARCH64_GCC_DIR): downloads/$(AARCH64_GCC_TARBALL)
	$(ECHO) '  TAR     $@'
	$(Q)rm -rf toolchains/$(AARCH64_GCC_DIR)
	$(Q)cd toolchains && tar xf ../downloads/$(AARCH64_GCC_TARBALL)
	$(Q)touch $@

downloads/$(AARCH64_GCC_TARBALL):
	$(ECHO) '  CURL    $@'
	$(Q)$(CURL) $(AARCH64_GCC_URL) -o $@


toolchains/$(AARCH64_NONE_GCC_DIR): downloads/$(AARCH64_NONE_GCC_TARBALL)
	$(ECHO) '  TAR     $@'
	$(Q)rm -rf toolchains/$(AARCH64_NONE_GCC_DIR)
	$(Q)cd toolchains && tar xf ../downloads/$(AARCH64_NONE_GCC_TARBALL)
	$(Q)touch $@

downloads/$(AARCH64_NONE_GCC_TARBALL):
	$(ECHO) '  CURL    $@'
	$(Q)$(CURL) $(AARCH64_NONE_GCC_URL) -o $@

#
# Clean rules
#

clean: clean-linux clean-optee-os clean-optee-client clean-optee-linuxdriver clean-uefi clean-arm-tf clean-rootfs
	$(ECHO) '  CLEAN   .'

cleaner: clean
	$(ECHO) '  CLEANER .'
	$(Q)rm -rf $(LINUX_DIR) linux .linux
	$(Q)rm -rf $(EDK2_DIR) edk2
	$(Q)rm -rf gen_rootfs/$(BUSYBOX_DIR)
	$(Q)rm -rf toolchains/$(AARCH64_GCC_DIR)
	$(Q)rm -rf toolchains/$(AARCH64_NONE_GCC_DIR)

# Also remove downloaded files
distclean: cleaner
	$(ECHO) '  DISTCL  .'
	$(Q)rm -f downloads/$(LINUX_TARBALL)
	$(Q)rm -f downloads/$(EDK2_TARBALL)
	$(Q)rm -f downloads/$(BUSYBOX_TARBALL)
	$(Q)rm -f downloads/$(AARCH64_GCC_TARBALL)
	$(Q)rm -f downloads/$(AARCH64_NONE_GCC_DIR)


#
# Linux
#

.PHONY: build-linux
build-linux linux/arch/arm64/boot/Image: linux/.config $(aarch64-none-elf-gcc)
	$(Q)make -C linux \
	    -j$(_NPROCESSORS_ONLN) \
	    ARCH=arm64 \
	    CROSS_COMPILE="$(CCACHE)aarch64-none-elf-" \
	    LOCALVERSION=

linux/.config: .linux $(aarch64-none-elf-gcc)
	$(Q)make -C linux ARCH=arm64 CROSS_COMPILE=aarch64-none-elf- defconfig

linux/usr/gen_init_cpio: linux/.config
	$(Q)make -C linux ARCH=arm64 usr/gen_init_cpio

linux/scripts/dtc/dtc: linux/.config $(aarch64-none-elf-gcc)
	$(Q)make -C linux ARCH=arm64 CROSS_COMPILE=aarch64-none-elf- scripts

clean-linux:
	$(ECHO) '  CLEAN   linux'
	$(Q)-[ -d linux ] && make -C linux ARCH=arm64 CROSS_COMPILE=aarch64-none-elf- clean

#
# OP-TEE
#

.PHONY: build-optee-os
build-optee-os optee_os/out/arm32-plat-vexpress/core/tee.bin:
	$(ECHO) '  BUILD   optee_os'
	$(Q)make -C optee_os \
	    -j$(_NPROCESSORS_ONLN) \
	    CROSS_COMPILE="$(CCACHE)arm-linux-gnueabihf-" \
	    PLATFORM=vexpress-fvp \
	    CFG_TEE_CORE_LOG_LEVEL=4

clean-optee-os:
	$(ECHO) '  CLEAN   optee_os'
	$(Q)make -C optee_os \
	    -j$(_NPROCESSORS_ONLN) \
	    CROSS_COMPILE="$(CCACHE)arm-linux-gnueabihf-" \
	    PLATFORM=vexpress-fvp \
	    CFG_TEE_CORE_LOG_LEVEL=4 \
	    clean

#
# OP-TEE client
#

optee-client-files := optee_client/out/export/lib/libteec.so.1.0 \
		      optee_client/out/export/bin/tee-supplicant

.PHONY: build-optee-client
build-optee-client $(optee-client-files): $(aarch64-linux-gnu-gcc)
	$(ECHO) '  BUILD   optee_client'
	$(Q)make -C optee_client \
	    -j$(_NPROCESSORS_ONLN) \
	    CROSS_COMPILE="$(CCACHE)aarch64-linux-gnu-"

clean-optee-client:
	$(ECHO) '  CLEAN   optee_client'
	$(Q)make -C optee_client \
	    -j$(_NPROCESSORS_ONLN) \
	    CROSS_COMPILE="$(CCACHE)arm-linux-gnueabihf-" \
	    clean

#
# OP-TEE Linux driver
#

.PHONY: build-optee-linuxdriver
build-optee-linuxdriver optee_linuxdriver/optee.ko: linux/.config $(aarch64-linux-gnu-gcc)
	$(ECHO) '  BUILD   optee_linuxdriver'
	$(Q)make -C linux \
	    -j$(_NPROCESSORS_ONLN) \
	    ARCH=arm64 \
	    CROSS_COMPILE="$(CCACHE)aarch64-linux-gnu-" \
	    LOCALVERSION= \
	    M=../optee_linuxdriver \
	    modules

.PHONY: build-dtb
build-dtb: optee_linuxdriver/fdts/fvp-foundation-gicv2-psci.dtb

optee_linuxdriver/fdts/fvp-foundation-gicv2-psci.dtb: optee_linuxdriver/fdts/fvp-foundation-gicv2-psci.dts linux/scripts/dtc/dtc
	$(ECHO) '  GEN     $@'
	$(Q)cd optee_linuxdriver/fdts && \
	    ../../linux/scripts/dtc/dtc -O dtb -o fvp-foundation-gicv2-psci.dtb \
		-b 0 -i . fvp-foundation-gicv2-psci.dts

clean-dtb:
	$(ECHO) '  RM      optee_linuxdriver/fdts/fvp-foundation-gicv2-psci.dtb'
	$(Q)rm -f optee_linuxdriver/fdts/fvp-foundation-gicv2-psci.dtb

clean-optee-linuxdriver: clean-dtb
	$(ECHO) '  CLEAN   optee_linuxdriver'
	$(Q)-[ -d linux ] && make -C linux \
	    -j$(_NPROCESSORS_ONLN) \
	    ARCH=arm64 \
	    CROSS_COMPILE="$(CCACHE)aarch64-linux-gnu-" \
	    LOCALVERSION= \
	    M=../optee_linuxdriver \
	    clean

#
# UEFI
#

.PHONY: build-uefi
build-uefi edk2/Build/ArmVExpress-FVP-AArch64/RELEASE_GCC49/FV/FVP_AARCH64_EFI.fd: $(aarch64-none-elf-gcc) edk2/.BaseTools
	$(ECHO) '  BUILD   edk2'
	$(Q)set -e ; cd edk2 ; export GCC49_AARCH64_PREFIX='"$(CCACHE)aarch64-none-elf-"' ; \
	    . edksetup.sh ; \
	    make -f ArmPlatformPkg/Scripts/Makefile \
		EDK2_ARCH=AARCH64 \
		EDK2_DSC=ArmPlatformPkg/ArmVExpressPkg/ArmVExpress-FVP-AArch64.dsc \
		EDK2_TOOLCHAIN=GCC49 EDK2_BUILD=RELEASE \
		EDK2_MACROS="-n 6 -D ARM_FOUNDATION_FVP=1"
	$(Q)touch edk2/Build/ArmVExpress-FVP-AArch64/RELEASE_GCC49/FV/FVP_AARCH64_EFI.fd

edk2/.BaseTools: edk2
	$(ECHO) '  BUILD   edk2/BaseTools'
	$(Q)set -e ; cd edk2 ; export GCC49_AARCH64_PREFIX='"$(CCACHE)aarch64-none-elf-"' ; \
	    . edksetup.sh ; \
	    make -C BaseTools CC="$(CCACHE)gcc" CXX="$(CCACHE)g++" ; \
	    touch .BaseTools

clean-uefi: clean-uefi-basetools
	$(ECHO) '  CLEAN   edk2'
	$(Q)-[ -d edk2 ] && ( set -e ; cd edk2 ; \
	    . edksetup.sh ; \
	    make -f ArmPlatformPkg/Scripts/Makefile \
		EDK2_ARCH=AARCH64 \
		EDK2_DSC=ArmPlatformPkg/ArmVExpressPkg/ArmVExpress-FVP-AArch64.dsc \
		EDK2_TOOLCHAIN=GCC49 EDK2_BUILD=RELEASE \
		EDK2_MACROS="-n 6 -D ARM_FOUNDATION_FVP=1" \
		clean )

clean-uefi-basetools:
	$(ECHO) '  CLEAN   edk2/BaseTools'
	$(Q)-[ -d edk2 ] && ( set -e ; cd edk2 ; \
	    . edksetup.sh ; \
	    make -C BaseTools clean ; \
	    rm -f .BaseTools)

#
# ARM Trusted Firmware
#

.PHONY: build-arm-tf
build-arm-tf: build-arm-tf-fip build-arm-tf-bl1

ATF = arm-trusted-firmware/build/fvp/debug

define arm-tf-make
	$(ECHO) '  BUILD   $@'
	$(Q)export CFLAGS="-O0 -gdwarf-2" ; \
	    export BL32=$(PWD)/optee_os/out/arm32-plat-vexpress/core/tee.bin ; \
	    export BL33=$(PWD)/edk2/Build/ArmVExpress-FVP-AArch64/RELEASE_GCC49/FV/FVP_AARCH64_EFI.fd ; \
	    make -C arm-trusted-firmware \
		CROSS_COMPILE="$(CCACHE)aarch64-none-elf-" \
		DEBUG=1 \
		FVP_TSP_RAM_LOCATION=tdram \
		FVP_SHARED_DATA_LOCATION=tdram \
		PLAT=fvp \
		SPD=opteed \
		$(1)
endef

.PHONY: build-arm-tf-bl2-bl31
build-arm-tf-bl2-bl31 $(ATF)/bl2.bin $(ATF)/bl31.bin: $(aarch64-none-elf-gcc)
	$(call arm-tf-make, bl2 bl31)

# "make -C arm-trusted-firmware fip" always updates fip.bin, even if it is
# up-to-date, so we can't add just add build-arm-tf-fip and fip.bin to the
# left side of the above rule and add 'fip' to the make command. This would
# result in "make build-arm-tf-fip" always touching fip.bin.
# The double-colon rules below are processed in order, which solves the issue.

.PHONY: build-arm-tf-fip
build-arm-tf-fip :: build-arm-tf-bl2-bl31 build-optee-os build-uefi
build-arm-tf-fip :: $(ATF)/fip.bin

$(ATF)/fip.bin: $(ATF)/bl2.bin $(ATF)/bl31.bin optee_os/out/arm32-plat-vexpress/core/tee.bin edk2/Build/ArmVExpress-FVP-AArch64/RELEASE_GCC49/FV/FVP_AARCH64_EFI.fd $(aarch64-none-elf-gcc)
	$(call arm-tf-make, fip)

.PHONY: build-arm-tf-bl1
build-arm-tf-bl1 arm-trusted-firmware/build/fvp/debug/bl1.bin: $(aarch64-none-elf-gcc)
	$(call arm-tf-make, bl1)

clean-arm-tf:
	$(ECHO) '  CLEAN   arm-trusted-firmware'
	$(Q)make -C arm-trusted-firmware PLAT=fvp DEBUG=1 clean


#
# Root fs
#

.PHONY: build-rootfs
build-rootfs run/filesystem.cpio.gz: linux/usr/gen_init_cpio $(optee-client-files) optee_linuxdriver/optee.ko

run/filesystem.cpio.gz: gen_rootfs/filelist-tee.txt
	$(ECHO) "  GEN    $@"
	$(Q)(cd gen_rootfs && gen_init_cpio filelist-tee.txt) | gzip >$@

gen_rootfs/filelist-tee.txt: gen_rootfs/filelist-final.txt tee-files.txt
	$(ECHO) '  GEN    $@'
	$(Q)cat gen_rootfs/filelist-final.txt | sed '/fbtest/d' >$@
	$(Q)export KERNEL_VERSION=`cd linux ; make -s kernelversion` ;\
	    export TOP=$(PWD) ; \
	    $(expand-env-var) <tee-files.txt >>$@

gen_rootfs/filelist-final.txt: gen_rootfs/busybox $(aarch64-linux-gnu-gcc)
	$(ECHO) '  GEN    $@'
	$(Q)cd gen_rootfs ; \
	    export CC_DIR=$(PWD)/toolchains/$(AARCH64_GCC_DIR) ; \
	    ./generate-cpio-rootfs.sh fvp-aarch64

clean-rootfs:
	$(Q)rm -f run/filesystem.cpio.gz gen_rootfs/filelist-final.txt gen_rootfs/filelist-tee.txt
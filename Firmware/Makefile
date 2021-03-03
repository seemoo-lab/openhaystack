PLATFORM := nRF51822
NRF51_SDK_PATH := $(shell pwd)/nrf51_sdk_v4_4_2_33551
NRF51_SDK_DOWNLOAD_URL := https://developer.nordicsemi.com/nRF5_SDK/nRF51_SDK_v4.x.x/nrf51_sdk_v4_4_2_33551.zip
OPENHAYSTACK_FIRMWARE_PATH := $(shell pwd)/../OpenHaystack/OpenHaystack/HaystackApp/firmware.bin

export PLATFORM
export NRF51_SDK_PATH

ifeq ($(DEPLOY_PATH),)
	DEPLOY_PATH := /Volumes/MICROBIT
endif

offline-finding/build/offline-finding.bin: $(NRF51_SDK_PATH) blessed/.git
	$(MAKE) -C blessed
	$(MAKE) -C offline-finding

$(NRF51_SDK_PATH):
	wget $(NRF51_SDK_DOWNLOAD_URL)
	unzip $(NRF51_SDK_PATH).zip -d $(NRF51_SDK_PATH)

blessed/.git:
	git submodule update --init

clean:
	$(MAKE) -C blessed $@
	$(MAKE) -C offline-finding $@

install: offline-finding/build/offline-finding.bin
	cp $< $(DEPLOY_PATH)

update-app: offline-finding/build/offline-finding.bin
	cp $< $(OPENHAYSTACK_FIRMWARE_PATH)

.PHONY: clean install update-app

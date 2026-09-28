ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

before-all::
	@python3 scripts/generate_assets.py

TWEAK_NAME = AdShield

AdShield_FILES = \
	Tweak.xm \
	XAdapter.xm \
	Core/ASXSupport.m \
	Core/ASXCellGuard.m \
	Core/ASDomainRules.m \
	Core/ASPreferences.m \
	Core/ASRuleEngine.m \
	Core/ASLogger.m

AdShield_CFLAGS = -fobjc-arc -Wall -Wextra
AdShield_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += preferences app
include $(THEOS_MAKE_PATH)/aggregate.mk


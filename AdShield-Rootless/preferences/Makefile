ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AdShieldPrefs

AdShieldPrefs_FILES = ASRootListController.m ../Core/ASPreferences.m
AdShieldPrefs_FRAMEWORKS = UIKit
AdShieldPrefs_PRIVATE_FRAMEWORKS = Preferences
AdShieldPrefs_INSTALL_PATH = /Library/PreferenceBundles
AdShieldPrefs_CFLAGS = -fobjc-arc -Wall -Wextra -I$(THEOS_PROJECT_DIR)/..

include $(THEOS_MAKE_PATH)/bundle.mk

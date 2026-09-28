ARCHS = arm64
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = AdShieldApp

AdShieldApp_FILES = main.m ASAppDelegate.m ASViewController.m ../Core/ASPreferences.m ../Core/ASDomainRules.m
AdShieldApp_FRAMEWORKS = UIKit Foundation
AdShieldApp_CFLAGS = -fobjc-arc -Wall -Wextra -I$(THEOS_PROJECT_DIR)/..
AdShieldApp_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk


#GO_EASY_ON_ME=1
ARCHS = armv7 arm64
#TARGET = iphone:clang:latest:latest

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Epicentre

Epicentre_FILES = /mnt/d/codes/epicentre/Preferences/Epicentre.mm
Epicentre_FILES += /mnt/d/codes/epicentre/Preferences/EpicentreRootListController.m 
Epicentre_FILES += /mnt/d/codes/epicentre/Preferences/EpicentreListController.m
Epicentre_FILES += /mnt/d/codes/epicentre/Preferences/EpicentreDiscreteSliderTableCell.m 
Epicentre_FILES += /mnt/d/codes/epicentre/Preferences/EpicentreSocialCell.m 
Epicentre_FILES += /mnt/d/codes/epicentre/Preferences/EpicentreHeaderCell.m

Epicentre_INSTALL_PATH = /Library/PreferenceBundles
Epicentre_FRAMEWORKS = UIKit
Epicentre_FRAMEWORKS += CoreGraphics
Epicentre_PRIVATE_FRAMEWORKS = Preferences
Epicentre_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

ARCHS = armv7 arm64

include theos/makefiles/common.mk

TWEAK_NAME = Epicentre

Epicentre_FILES = /mnt/d/codes/epicentre/Tweak.xm
Epicentre_FILES += /mnt/d/codes/epicentre/EPCPreferences.mm
Epicentre_FILES += /mnt/d/codes/epicentre/EPCDraggableRotaryNumberView.mm
Epicentre_FILES += /mnt/d/codes/epicentre/EPCExpandingChestView.mm
Epicentre_FILES += /mnt/d/codes/epicentre/EPCRingView.mm
Epicentre_FILES += /mnt/d/codes/epicentre/EPCPasscodeChangedAlertWrapper.mm
Epicentre_FILES += /mnt/d/codes/epicentre/EPCPasscodeChangedAlertHandler.mm
#Epicentre_FILES += /mnt/d/codes/epicentre/EPCRingController.mm

Epicentre_FRAMEWORKS = UIKit
Epicentre_FRAMEWORKS += CoreGraphics
Epicentre_FRAMEWORKS += QuartzCore
Epicentre_FRAMEWORKS += CydiaSubstrate
Epicentre_CFLAGS = -fobjc-arc
Epicentre_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences

include $(THEOS_MAKE_PATH)/aggregate.mk

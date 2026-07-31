TARGET = iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = SplashText

SplashText_FILES = Tweak.x
SplashText_FRAMEWORKS = UIKit
SplashText_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
SplashText_CFLAGS = -fobjc-arc
SplashText_LDFLAGS = -Wl,-U,_objc_msgSend

include $(THEOS_MAKE_PATH)/library.mk

ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest
THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = Grams
Grams_FILES = Tweak.xm
Grams_FRAMEWORKS = UIKit
Grams_FRAMEWORKS += CoreGraphics
Grams_FRAMEWORKS += QuartzCore
Grams_LDFLAGS += -Wl,-segalign,4000
Grams_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

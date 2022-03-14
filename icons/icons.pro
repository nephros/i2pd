TEMPLATE = aux
# Configures svg to png
THEMENAME=sailfish-default
CONFIG += sailfish-svg2png

# also install SVG:
svg.path = /usr/share/icons/hicolor/scalable/apps
svg.files = svgs/i2p-banner.svg \
            svgs/icon-m-i2p.svg \
            svgs/icon-settings-i2p.svg

INSTALLS += svg

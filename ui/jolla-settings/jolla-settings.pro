TEMPLATE = aux

settings-entry.path = /usr/share/jolla-settings/entries
settings-entry.files = ./entries/i2pd.json

settings-ui.path = /usr/share/jolla-settings/pages/i2p
settings-ui.files = \
    pages/i2p/mainpage.qml \
    pages/i2p/EnableSwitch.qml

INSTALLS += settings-ui settings-entry

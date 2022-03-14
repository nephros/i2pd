import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.configuration 1.0

Page {
    id: page

    property bool activeState
    onActiveStateChanged: {
        enableSwitch.busy = false
    }

    Timer {
        id: checkState
        interval: 1000
        repeat: true
        onTriggered: {
            systemdServiceIface.updateProperties()
        }
    }

    DBusInterface {
        // qdbus --system org.freedesktop.systemd1 /org/freedesktop/systemd1/unit/i2pd_2eservice org.freedesktop.systemd1.Unit.ActiveState
        id: systemdServiceIface
        bus: DBus.SystemBus
        service: 'org.freedesktop.systemd1'
        path: '/org/freedesktop/systemd1/unit/i2pd_2eservice'
        iface: 'org.freedesktop.systemd1.Unit'

        signalsEnabled: true
        function updateProperties() {
            var activeProperty = systemdServiceIface.getProperty("ActiveState")
            console.log("ActiveState:", activeProperty)
            if (activeProperty === "active") {
                activeState = true
                checkState.stop()
            }
            else if (activeProperty === "inactive") {
                activeState = false
                checkState.stop()
            }
            else {
                checkState.start()
            }
        }

        onPropertiesChanged: updateProperties()
        Component.onCompleted: updateProperties()
    }

    DBusInterface {
        bus: DBus.SystemBus
        service: 'org.freedesktop.systemd1'
        path: '/org/freedesktop/systemd1/unit/i2pd_2eservice'
        iface: 'org.freedesktop.DBus.Properties'

        signalsEnabled: true
        onPropertiesChanged: systemdServiceIface.updateProperties()
        Component.onCompleted: systemdServiceIface.updateProperties()
    }

    DBusInterface {
        bus: DBus.SystemBus
        service: "org.freedesktop.systemd1"
        path: "/org/freedesktop/systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        signalsEnabled: true

        signal unitNew(string name)
        onUnitNew: {
            if (name == "i2pd.service") {
                systemdServiceIface.updateProperties()
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: page.width

            PageHeader {
                title: qsTr("I2P")
            }

            Image {
                id: banner
                anchors.horizontalCenter: parent.horizontalCenter
                width: enableItem.width
                sourceSize.width: width
                smooth: false
                fillMode: Image.PreserveAspectFit
                source: "image://theme/i2p-banner"
            }

            ListItem {
                id: enableItem

                contentHeight: enableSwitch.height
                _backgroundColor: "transparent"

                highlighted: enableSwitch.down || menuOpen

                showMenuOnPressAndHold: false
                menu: Component { FavoriteMenu { } }

                TextSwitch {
                    id: enableSwitch

                    property string entryPath: "system_settings/security/i2p/i2p_active"

                    automaticCheck: false
                    checked: activeState
                    text: "I2P Service" + " " + ( activeState ? "active" : "inactive" )
                    //description: qsTrId("settings_flight-la-flight-mode-description")

                    onClicked: {
                        if (enableSwitch.busy) {
                            return
                        }
                        systemdServiceIface.call(activeState ? "Stop" : "Start", ["replace"])
                        systemdServiceIface.updateProperties()
                        enableSwitch.busy = true
                    }
                    onPressAndHold: enableItem.showMenu({ settingEntryPath: entryPath, isFavorite: favorites.isFavorite(entryPath) })
                }
            }
        }
    }
}

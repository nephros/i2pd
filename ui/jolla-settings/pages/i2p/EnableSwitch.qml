import QtQuick 2.1
import Sailfish.Silica 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.configuration 1.0

Switch {
    id: enableSwitch

    property string entryPath
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
        id: systemdServiceIface
        bus: DBus.SystemBus
        service: 'org.freedesktop.systemd1'
        path: '/org/freedesktop/systemd1/unit/i2pd'
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
        path: '/org/freedesktop/systemd1/unit/i2pd'
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

    icon.source: "image://theme/icon-settings-i2p"
    checked: activeState == "active"
    automaticCheck: false
    onClicked: {
        if (enableSwitch.busy) {
            return
        }
        systemdServiceIface.call(activeState ? "Stop" : "Start", ["replace"])
        systemdServiceIface.updateProperties()
        enableSwitch.busy = true
    }

    Behavior on opacity { FadeAnimation { } }
}

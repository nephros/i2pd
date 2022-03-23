/*
 * Copyright (c) 2022 Peter G. <sailfish@nephros.org>
 *
 * License: Apache-2.0
 *
 */

import QtQuick 2.1
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import com.jolla.settings 1.0
import org.nemomobile.systemsettings 1.0

SettingsToggle {
    id: enableSwitch

    property bool activeState

    onActiveStateChanged: {
        busy = false
    }

    name: "I2P"
    activeText: "active"
    icon.source: "image://theme/icon-m-i2p"

    active: activeState
    checked: activeState

    //busy:

    menu: ContextMenu {
        SettingsMenuItem {
            onClicked: enableSwitch.goToSettings()
        }

        MenuItem {
            text: "Open Web Console"
            onClicked: Qt.openUrlExternally("http://127.0.0.1:7070")
        }
    }

    onToggled: {
        if (busy) {
            return
        }
        busy = true
        systemdServiceIface.call(activeState ? "Stop" : "Start", ["replace"])
        systemdServiceIface.updateProperties()
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

    Component.onCompleted: systemdServiceIface.updateProperties()

}

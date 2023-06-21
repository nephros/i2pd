// SPDX-FileCopyrightText: 2022 Peter G. <sailfish@nephros.org>
//
// SPDX-License-Identifier: Apache-2.0

import QtQuick 2.1
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import com.jolla.settings 1.0
import org.nemomobile.systemsettings 1.0

SettingsToggle {
    id: enableSwitch

    property alias serviceState: unit.activeState
    property bool activeState:   serviceState === "active"
    property bool inactiveState: !activeState && ((serviceState !== "inactive") && (serviceState !== "failed"))
    property bool busyState:     !activeState && ((serviceState !== "reloading") && (serviceState !== "activating") && (serviceState !== "deactivating"))

    active: activeState
    checked: activeState
    busy: busyState
    enabled: !busy

    name: "I2P"
    activeText: "I2P"
    icon.source: "image://theme/icon-m-i2p"

    menu: ContextMenu {
        SettingsMenuItem { onClicked: enableSwitch.goToSettings() }
        MenuItem {
            text: "Open Web Console"
            onClicked: Qt.openUrlExternally("http://127.0.0.1:7070")
        }
    }

    onToggled: unit.call(activeState ? "Stop" : "Start", ["replace"])

    DBusInterface {
        id: unit
        bus: DBus.SystemBus
        service: 'org.freedesktop.systemd1'
        path: '/org/freedesktop/systemd1/unit/i2pd_2eservice'
        iface: 'org.freedesktop.systemd1.Unit'

        property string activeState
        //property string subState
        //property string unitFileState

        signalsEnabled: true
        propertiesEnabled: true
    }
}

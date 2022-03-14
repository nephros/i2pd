import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.configuration 1.0
import Mer.Cutes 1.1

Page {
    id: page

    property bool activeState
    onActiveStateChanged: {
        enableSwitch.busy = false
    }

    CutesActor {
        id: tools
        source: "./tools.js"
    }

    ConfigurationGroup {
        id: proxyConf
        path: "/apps/i2p-button"
        property bool browserProxy: false
        property bool browserRestart: false
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
            console.debug("New unit: " + name)
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
                        if (proxyConf.browserProxy) {
                            var proxy_reply = function() {
                                var kill_reply = function() {
                                    if (!activeState) {
                                        var object = Qt.createQmlObject("import org.nemomobile.lipstick 0.1; LauncherItem { filePath: \"/usr/share/applications/sailfish-browser.desktop\" }", enableSwitch, "LauncherItem")
                                        object.launchApplication()
                                    }

                                    systemdServiceIface.updateProperties()
                                };
                                var kill_error = function(err) {
                                    console.log("error:", err);
                                };
                                if (proxyConf.browserRestart) {
                                    tools.request("kill_browser", {}, {
                                        on_reply: kill_reply, on_error: kill_error
                                    });
                                }
                            };
                            var proxy_error = function(err) {
                                console.log("error:", err);
                            };
                            tools.request(activeState ? "disable_proxy" : "enable_proxy", {}, {
                                on_reply: proxy_reply, on_error: proxy_error
                            });
                        }
                        else {
                            systemdServiceIface.updateProperties()
                        }
                        enableSwitch.busy = true
                    }
                    onPressAndHold: enableItem.showMenu({ settingEntryPath: entryPath, isFavorite: favorites.isFavorite(entryPath) })
                }
            }

            TextSwitch {
                id: proxySwitch

                automaticCheck: false
                checked: proxyConf.browserProxy
                text: "Sailfish browser proxy"
                description: "Automatically set proxy when enabling I2P"

                onClicked: {
                    proxyConf.browserProxy = !proxyConf.browserProxy
                }
            }

            TextSwitch {
                id: restartSwitch

                visible: proxyConf.browserProxy
                automaticCheck: false
                checked: proxyConf.browserRestart
                text: "Restart Sailfish browser"
                description: "Also restart Sailfish browser automatically"

                onClicked: {
                    proxyConf.browserRestart = !proxyConf.browserRestart
                }
            }
        }
    }
}

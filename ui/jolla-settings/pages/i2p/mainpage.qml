import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.configuration 1.0

Page {
    id: page

    property bool activeState
    //property bool enabledState
    onActiveStateChanged: {
        if (activeState) { daemonInfo.refreshInfo() }
    }

    Timer {
        id: checkState
        interval: 2000
        repeat: true
        running: Qt.application.state == Qt.ApplicationActive
        onTriggered: {
            systemdServiceIface.updateProperties()
        }
    }

    Timer {
        id: refreshTimer
        interval: 15000
        repeat: true
        triggeredOnStart: true
        running: activeState && Qt.application.state == Qt.ApplicationActive
        onTriggered: {
            daemonInfo.refreshInfo()
        }
    }

    DBusInterface {
        // qdbus --system org.freedesktop.systemd1 /org/freedesktop/systemd1/unit/i2pd_2eservice org.freedesktop.systemd1.Unit.ActiveState
        // valuse: "active", "reloading", "inactive", "failed", "activating", and "deactivating"
        id: systemdServiceIface
        bus: DBus.SystemBus
        service: 'org.freedesktop.systemd1'
        path: '/org/freedesktop/systemd1/unit/i2pd_2eservice'
        iface: 'org.freedesktop.systemd1.Unit'

        signalsEnabled: true
        function updateProperties() {
            var activeProperty = systemdServiceIface.getProperty("ActiveState")
            //var enabledProperty = systemdServiceIface.getProperty("UnitFileState")
            console.debug("ActiveState:", activeProperty)
            if (activeProperty === "active") {
                activeState = true
                startstopSwitch.busy = false
            }
            else if (activeProperty === "inactive" || activeProperty === "failed") {
                activeState = false
                startstopSwitch.busy = false
            } else {
                startstopSwitch.busy = true
            }
            /*
            if (enabledProperty === "enabled") {
                enabledState = true
            } else {
                enabledState = false
            }
            */
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
        onPropertiesChanged: { console.log("updating properties"); systemdServiceIface.updateProperties()}
        Component.onCompleted: systemdServiceIface.updateProperties()
    }

    /*
    DBusInterface {
        id: systemdManagerIface
        bus: DBus.SystemBus
        service: "org.freedesktop.systemd1"
        path: "/org/freedesktop/systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        signalsEnabled: true

        signal unitNew(string name)
        onUnitNew: {
            if (name == "i2pd.service") {
                console.debug("A wild unit appeared!", name);
                systemdServiceIface.updateProperties()
            }
        }
    }
    */

    Component { id: passdialog
        Dialog {
            property string user
            property string password
            Column {
                spacing: Theme.paddingMedium
                width: parent.width
                DialogHeader {}
                Label {
                    width: parent.width - Theme.horizontalPageMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    wrapMode: Text.WordWrap
                    text: "Specify the API credentials. If changed, they will be used in this session, but not stored."
                }
                TextField {
                    id: userField
                    width: parent.width
                    label: "I2P User"
                    placeholderText: user
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: passField.focus=true
                }
                PasswordField {
                    id: passField
                    width: parent.width
                    label: "I2P Password"
                    placeholderText: password
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: dialog.accept()
                }
            }
            onDone: {
                if (result == DialogResult.Accepted) {
                    user     = userField.text
                    password = passField.text
                }
            }
        }
    }
    PullDownMenu {
        flickable: flick
        MenuItem { text: "Change Credentials";
            onClicked: {
                var dialog = pageStack.push(passdialog, { "password": daemonInfo.httppassword, "user": daemonInfo.httpuser })
                dialog.accepted.connect(function() { daemonInfo.httppassword = dialog.password; daemonInfo.httpuser = dialog.user})
            }
        }
        MenuItem { text: "Refresh info"; onClicked: daemonInfo.refreshInfo()}
    }

    SilicaFlickable { id: flick
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("I2P")
                Image {
                    id: banner
                    anchors.centerIn: parent
                    height: parent.height
                    sourceSize.height: height
                    smooth: false
                    fillMode: Image.PreserveAspectFit
                    source: "image://theme/i2p-banner-dots"
                }
            }

            ListItem {
                id: enableItem

                contentHeight: startstopSwitch.height
                _backgroundColor: "transparent"

                highlighted: startstopSwitch.down || menuOpen

                showMenuOnPressAndHold: false
                menu: Component { FavoriteMenu { } }

                TextSwitch {
                    id: startstopSwitch

                    automaticCheck: false
                    checked: activeState
                    text: "I2P Service" + " " + ( activeState ? "active" : "inactive" )
                    description: activeState ? qsTr("Stopping may take some time.") : ""

                    onClicked: {
                        if (startstopSwitch.busy) {
                            return
                        }
                        systemdServiceIface.call(activeState ? "Stop" : "Start", ["replace"])
                        systemdServiceIface.updateProperties()
                        startstopSwitch.busy = true
                    }
                }
            }
            /*
            TextSwitch {
                    id: enableSwitch

                    automaticCheck: false
                    checked: enabledState
                    text: "Start at boot"
                    onClicked: {
                        enabledState ?
                                  systemdManagerIface.typedCall("DisableUnitFiles", [
                                              { "type": "as", "value":  [ "i2pd.service" ]},        // array of service names
                                              { "type": "b", "value": "false"}                      // session only?
                                            ])
                                : systemdManagerIface.typedCall("EnableUnitFiles", [
                                              { "type": "as", "value":  [ "i2pd.service" ]},        // array of service names
                                              { "type": "b", "value": "false"},                     // session only?
                                              { "type": "b", "value": "false"}                      // force?
                                            ])

                        systemdServiceIface.updateProperties()
                    }
            }
            */
            Separator { width: parent.width; color: Theme.secondaryColor; anchors.horizontalCenter: parent.horizontalCenter }
            Label { id: daemonInfo
                width: parent.width - Theme.itemSizeMedium
                anchors.horizontalCenter: parent.horizontalCenter

                color: Theme.secondaryColor
                wrapMode: Text.WordWrap
                textFormat: Text.RichText

                enabled: activeState

                property string httpaddr: 'http://127.0.0.1:7070'
                property string httpuser: 'jolla';
                property string httppassword: 'ahoisailors!';
                /*
                <b>Uptime:</b> 4 minutes, 29 seconds<br>
                <b>Network status:</b> Firewalled<br>
                <b>Family:</b> sailfishos<br>
                <b>Tunnel creation success rate:</b> 49%<br>
                <b>Received:</b> 489.98 KiB (1.07 KiB/s)<br>
                <b>Sent:</b> 465.04 KiB (0.99 KiB/s)<br>
                <b>Transit:</b> 0.00 KiB (0.00 KiB/s)<br>
                <b>Data path:</b> /home/.system/var/lib/i2pd<br>
                <div class='slide'><label for="slide-info">Hidden content. Press on text to see.</label>
                <input type="checkbox" id="slide-info" />
                <div class="slidecontent">
                <b>Router Ident:</b> XuizR1s~LaXCuBu5oA8flz6otMSOXJyZnsyOLa4CbXM=<br>
                <b>Router Family:</b> sailfishos<br>
                <b>Router Caps:</b> LU<br>
                <b>Version:</b> 2.41.0<br>
                <b>Our external address:</b><br>
                <table class="extaddr"><tbody>
                <tr>
                <td>NTCP2</td><td>supported</td>
                </tr>
                <tr>
                <td>SSU</td>
                <td>77.220.104.226:24895</td>
                </tr>
                </tbody></table>
                </div>
                </div>
                <b>Routers:</b> 1284 <b>Floodfills:</b> 789 <b>LeaseSets:</b> 0<br>
                <b>Client Tunnels:</b> 28 <b>Transit Tunnels:</b> 0<br>
                <br>
                <table class="services"><caption>Services</caption><tbody>
                <tr><td>HTTP Proxy</td><td class='enabled'>Enabled</td></tr>
                <tr><td>SOCKS Proxy</td><td class='enabled'>Enabled</td></tr>
                <tr><td>BOB</td><td class='disabled'>Disabled</td></tr>
                <tr><td>SAM</td><td class='disabled'>Disabled</td></tr>
                <tr><td>I2CP</td><td class='disabled'>Disabled</td></tr>
                <tr><td>I2PControl</td><td class='disabled'>Disabled</td></tr>
                </tbody></table>
                </div>
                */
                function refreshInfo() {
                    var xhr = new XMLHttpRequest();
                    //xhr.responseType="document";
                    xhr.open("GET", httpaddr, false, httpuser, httppassword);
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState == 4) {
                            if ((xhr.status >= "200" || xhr.status <= "300") ) {
                                var html = xhr.responseText
                                //var body = /<body.*?>([\s\S]*)<\/body>/.exec(content)[1];
                                //console.log("Body:", body);
                                var content = /<div class="content".*?>([\s\S]*)<\/div>/.exec(html)[1];
                                content = content.replace(/<label for=.*<\/label>/gm, "");
                                //console.log("content:", content);
                                daemonInfo.text = content;
                            } else {
                                daemonInfo.text = "";
                            }
                        }
                    }
                    xhr.send();
                }
            }
        }
    }
}

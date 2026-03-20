import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

Page {
    id: settingsPage
    allowedOrientations: Orientation.All

    // Persistent settings via dconf
    ConfigurationGroup {
        id: settings
        path: "/apps/harbour-spotclock"

        property string proxyUrl: "https://entsodata.ardcoras.fi/"
        property string biddingZone: "FI"
        property string vatPercent: "25.5"
        property bool alwaysShowQuarters: false
        property bool coverShowQuarters: false
    }

    // Zone list model, populated from proxy
    ListModel {
        id: zoneModel
    }

    Component.onCompleted: {
        // Fetch zones from proxy if URL is configured
        if (settings.proxyUrl.length > 0) {
            fetchZones(false);
        }
    }

    function fetchZones(autoOpenMenu) {
        var url = settings.proxyUrl + "/zones";
        dataController.request(url, "get", "", function(doc) {
            var json = doc.response;
            zoneModel.clear();
            if (json && json.zones) {
                for (var i = 0; i < json.zones.length; i++) {
                    zoneModel.append({
                        code: json.zones[i].code,
                        name: json.zones[i].name
                    });
                }
                // Set ComboBox to the saved zone
                for (var j = 0; j < zoneModel.count; j++) {
                    if (zoneModel.get(j).code === settings.biddingZone) {
                        zoneCombo.currentIndex = j;
                        break;
                    }
                }
                
                if (autoOpenMenu !== false) {
                    zoneCombo.forceActiveFocus();
                    if (zoneContextMenu) {
                        zoneContextMenu.show(zoneCombo);
                    }
                }
            }
        });
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: qsTr("Settings")
            }

            TextField {
                id: proxyUrlField
                width: parent.width
                label: qsTr("Proxy URL")
                placeholderText: qsTr("e.g. %1").arg("https://entsodata.ardcoras.fi")
                text: settings.proxyUrl
                inputMethodHints: Qt.ImhUrlCharactersOnly
                EnterKey.onClicked: {
                    if (settings.proxyUrl !== text) {
                        settings.proxyUrl = text;
                        fetchZones(true);
                    }
                    focus = false;
                }
                onActiveFocusChanged: {
                    if (!activeFocus && settings.proxyUrl !== text) {
                        settings.proxyUrl = text;
                        fetchZones(true);
                    }
                }
            }

            ComboBox {
                id: zoneCombo
                width: parent.width
                label: qsTr("ENTSO-E Area")
                description: zoneModel.count === 0 ? qsTr("Set proxy URL first, then zones will load") : ""

                menu: ContextMenu {
                    id: zoneContextMenu
                    Repeater {
                        model: zoneModel
                        MenuItem {
                            text: model.code + " — " + model.name
                            onClicked: {
                                settings.biddingZone = model.code;
                            }
                        }
                    }
                }
            }

            TextField {
                id: vatField
                width: parent.width
                label: qsTr("VAT (%)")
                placeholderText: "25.5"
                text: settings.vatPercent
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                EnterKey.onClicked: {
                    settings.vatPercent = text;
                    focus = false;
                }
                onTextChanged: {
                    settings.vatPercent = text;
                }
            }

            TextSwitch {
                id: quartersSwitch
                text: qsTr("Always show quarterly prices")
                description: qsTr("Show 15-minute price breakdown for every hour")
                checked: settings.alwaysShowQuarters
                onCheckedChanged: {
                    settings.alwaysShowQuarters = checked;
                }
            }

            TextSwitch {
                id: coverQuartersSwitch
                text: qsTr("Show quarterly prices on cover")
                description: qsTr("Show 15-minute price breakdown on the cover")
                checked: settings.coverShowQuarters
                onCheckedChanged: {
                    settings.coverShowQuarters = checked;
                }
            }

            SectionHeader {
                text: qsTr("Actions")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Reload zones from proxy")
                enabled: settings.proxyUrl.length > 0
                onClicked: fetchZones(true)
            }
        }
    }
}

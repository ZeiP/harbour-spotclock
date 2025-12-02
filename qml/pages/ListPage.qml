import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property string date: "";

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: getPrices()
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Scroll to top")
                onClicked: view.scrollToTop()
            }
        }

        width: parent.width;
        height: parent.height

        SilicaListView {
            id: view

            header: PageHeader {
                title: qsTr("Hourly rates on %1").arg(date);
            }

            ViewPlaceholder {
                enabled: priceList.count == 0
                text: qsTr("Nothing here")
            }

            width: parent.width
            height: parent.height
            model: priceList
            delegate: ListItem {
                width: parent.width
                height: Theme.itemSizeMedium

                Label {
                    id: label
                    text: qsTr("On %1 o'clock".arg(hour));
                }
                Label {
                    anchors.top: label.bottom
                    anchors.right: parent.right
                    font.pixelSize: Theme.fontSizeSmall
                    text: price
                }
            }
            Component.onCompleted: {
                getPrices();
            }
        }
    }

    function getPrices() {
        const date = new Date();
        var url = "https://www.sahkohinta-api.fi/api/v1/halpa?tunnit=24&tulos=sarja&aikaraja=" + date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
        priceList.clear();
        console.log(url);
        request(url, "get", "", function(doc) {
            var json = JSON.parse(doc.responseText);
            for(var i = 0; i < json.length; i++) {
                var tl = json[i];
                var item = {}
                var dateObject = new Date(tl.aikaleima_utc);
                item.price = (parseFloat(tl.hinta) * 1.255).toFixed(3); // Handle the VAT like this for now.

                item.hour = dateObject.getHours();
                page.date = dateObject.getDate() + "." + (dateObject.getMonth() + 1) + ".";
                priceList.append(item);
            }
        });
    }
}

import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    property var hour; // as Date object

    ListModel { id: coverModel }

    anchors.fill: parent

    property var controller: null

    Image {
        source: 'cover.png'
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: sourceSize.height * width / sourceSize.width
        asynchronous: true
    }

    Column {
        anchors.centerIn: parent
        Label {
            id: label
            text: qsTr("SpotClock")
        }

        Label {
            id: hourlabel
        }
        Label {
            id: pricelabel
        }
    }

    function setCover(spot) {
        var date = new Date()
        var dateString = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
        var hour = spot.getHours();
        hourlabel.text = qsTr("Today %1 o'clock").arg(hour);
        cover.hour = spot;
        pricelabel.text = qsTr("%1 snt / kWh").arg(controller.priceData[dateString][hour]['price']);
    }

    Timer {
        id: highlightedCheck
        interval: 60000 // 60 secs
        running: true
        repeat: true
        onTriggered: {
            var today = new Date();
            console.log("checking " + cover.hour + " (" + today.getHours() + ")");
            if (cover.hour !== today.getHours()) {
                setCover(today);
            }
        }
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: {
                hour.setHours(hour.getHours() - 1);
                setCover(hour);
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: {
                hour.setHours(hour.getHours() + 1);
                setCover(hour);
            }
        }
    }

    Component.onCompleted: {
        // For some reason Connect didn't work, so do it like this.
        controller.dataLoaded.connect(function(dateKey) {
            console.log("--- Signal reached: " + dateKey);
            hour = new Date()
            // Check if the loaded data matches the date this page is showing
            if (sameDate(dateKey, hour)) {
                console.log("Setting model");
                setCover(hour);
            }
        });
    }
}

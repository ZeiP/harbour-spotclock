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
        if (!spot) {
            hourlabel.text = qsTr("SpotClock");
            pricelabel.text = "...";
            return;
        }
        var dateString = spot.getFullYear() + "-" + controller.zeroPad(spot.getMonth() + 1) + "-" + controller.zeroPad(spot.getDate());
        var hour = spot.getHours();
        cover.hour = spot;

        if (!controller || !controller.priceData || !controller.priceData[dateString] || !controller.priceData[dateString][hour]) {
            hourlabel.text = qsTr("SpotClock");
            pricelabel.text = "...";
            return;
        }

        var entry = controller.priceData[dateString][hour];
        var price = entry['price'];

        if (controller.coverShowQuarters && entry['hasQuarters']) {
            var min = spot.getMinutes();
            var qStr = "00";
            if (min < 15) { qStr = "00"; price = entry['q0Price']; }
            else if (min < 30) { qStr = "15"; price = entry['q1Price']; }
            else if (min < 45) { qStr = "30"; price = entry['q2Price']; }
            else { qStr = "45"; price = entry['q3Price']; }
            hourlabel.text = qsTr("Today %1:%2").arg(controller.zeroPad(hour)).arg(qStr);
        } else {
            hourlabel.text = qsTr("Today %1 o'clock").arg(hour);
        }

        pricelabel.text = qsTr("%1 snt / kWh").arg(price);
    }

    Timer {
        id: updateTimer
        running: true
        repeat: false
        onTriggered: {
            var today = new Date();
            setCover(today);
            scheduleNextTick();
        }
    }

    function scheduleNextTick() {
        if (!controller) return;
        var now = new Date();
        var msToNext;
        if (controller.coverShowQuarters) {
            var nextQuarter = Math.floor(now.getMinutes() / 15 + 1) * 15;
            var nextTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), nextQuarter, 0, 0);
            msToNext = nextTime.getTime() - now.getTime();
        } else {
            var nextTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours() + 1, 0, 0, 0);
            msToNext = nextTime.getTime() - now.getTime();
        }
        updateTimer.interval = msToNext > 0 ? msToNext + 500 : 500;
        updateTimer.restart();
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

    Connections {
        target: controller
        onVatPercentChanged: setCover(cover.hour)
        onBiddingZoneChanged: setCover(cover.hour)
        onCoverShowQuartersChanged: {
            setCover(cover.hour)
            scheduleNextTick()
        }
        onProxyUrlChanged: setCover(cover.hour)
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
        scheduleNextTick();
    }
}

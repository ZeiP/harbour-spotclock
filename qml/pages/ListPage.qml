import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property var date;

    property int highlightedHour;

    property string pageTitle;

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

            Timer {
                id: highlightedCheck
                interval: 60000 // 60 secs
                running: true
                repeat: true
                onTriggered: {
                    var today = new Date();
                    console.log("checking " + page.highlightedHour + " (" + today.getHours() + ")");
                    if (page.highlightedHour !== today.getHours()) {
                        page.updateHighlight(today.getHours());
                    }
                }
            }
            Timer {
                id: tomorrowDataCheck
                interval: 900000 // 15 mins
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    var tomorrow = new Date();
                    tomorrow.setDate(tomorrow.getDate() + 1);
                    if (!dataController.getModelForDate(tomorrow) && date.getHours() > 13) {
                        dataController.fetchPrices(tomorrow);
                    }
                }
            }

            header: PageHeader {
                title: pageTitle
            }

            ButtonLayout {
                Button {
                    id: previousDay
                    text: ""
                    onClicked: {
                        const yesterday = new Date(page.date);
                        console.log("Starting from " + page.date.getDate());
                        yesterday.setDate(yesterday.getDate() - 1);
                        console.log("Switching to " + yesterday.getDate());
                        getPrices(yesterday);

//                        pageStack.push(Qt.resolvedUrl("ListPage.qml"), {date: yesterday});
                    }
                }
                Button {
                    id: nextDay
                    text: ""
                    enabled: false
                    onClicked: {
                        const tomorrow = new Date(page.date);
                        tomorrow.setDate(tomorrow.getDate() + 1);
                        console.log("Switching to " + tomorrow.getDate());
                        getPrices(tomorrow);
//                        pageStack.push(Qt.resolvedUrl("ListPage.qml"), {date: tomorrow});
                    }
                }
            }

            ViewPlaceholder {
                enabled: view.model.count == 0
                text: qsTr("Nothing here")
            }

            width: parent.width
            height: parent.height
            model: ListModel{}
            delegate: ListItem {
                width: parent.width
                height: Theme.itemSizeMedium
                highlighted: isHighlighted

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
                console.log("Completing page with " + page.date.getDate());

                page.getPrices(page.date);
            }
        }
    }

    // Gets the prices to the view model.
    function getPrices(date) {
        var model = dataController.getModelForDate(date); // Use the new function to look up the model
        page.date = date;

        const yesterday = new Date(page.date);
        yesterday.setDate(yesterday.getDate() - 1);
        previousDay.text = yesterday.getDate() + "." + (yesterday.getMonth() + 1) + ".";

        const tomorrow = new Date(page.date);
        tomorrow.setDate(tomorrow.getDate() + 1);
        nextDay.text = tomorrow.getDate() + "." + (tomorrow.getMonth() + 1) + ".";

        var today = new Date();
        var tomorrowString = tomorrow.getFullYear() + "-" + (tomorrow.getMonth() + 1) + "-" + tomorrow.getDate();
        const realTomorrow = new Date();
        realTomorrow.setDate(realTomorrow.getDate() + 1);
        if ((sameDate(page.date, today) && !dataController.priceData[tomorrowString]) || sameDate(page.date, realTomorrow)) {
            nextDay.enabled = false
        }
        else {
            nextDay.enabled = true
        }

        if (model) {
            // If model exists, use it immediately
            view.model = model;
            page.pageTitle = qsTr("Hourly rates on %1").arg(page.date.getDate() + "." + (page.date.getMonth() + 1) + ".");
            page.updateHighlight(today.getHours());
            console.log("Using cached model for date.");
        } else {
            // If model is null, fetch the data
            dataController.fetchPrices(date);
        }
    }

    function sameDate(date1, date2) {
        console.log("Comparing" + date1.getFullYear() + date2.getFullYear() + date1.getMonth() + date2.getMonth() + date1.getDate() + date2.getDate());
        return date1.getFullYear() === date2.getFullYear() && date1.getMonth() === date2.getMonth() && date1.getDate() === date2.getDate();
    }

    function updateHighlight(newHour) {
        console.log("Updating highlight");
        var today = new Date()
        if (sameDate(page.date, today)) {
            var modelCount = view.model.count;

            for (var i = 0; i < modelCount; i++) {
                var itemData = view.model.get(i);
                if (itemData.isHighlighted == true) {
                    view.model.set(i, { isHighlighted: false });
                }
                if (itemData.hour == newHour) {
                    view.model.set(i, { isHighlighted: true });
                    page.highlightedHour = newHour;
                }
            }
        }
    }

    Component.onCompleted: {
        // For some reason Connect didn't work, so do it like this.
        dataController.dataLoaded.connect(function(dateKey) {
            console.log("--- Signal reached: " + dateKey);
            // Check if the loaded data matches the date this page is showing
            if (sameDate(dateKey, page.date)) {
                console.log("Setting model");
                var model = dataController.getModelForDate(dateKey); // Use the new function to look up the model
                view.model = model;
                page.date = dateKey;
                var today = new Date();
                page.updateHighlight(today.getHours());
                page.pageTitle = qsTr("Hourly rates on %1").arg(page.date.getDate() + "." + (page.date.getMonth() + 1) + ".");
                console.log(page.date.getHours());
            }
        });
    }
}

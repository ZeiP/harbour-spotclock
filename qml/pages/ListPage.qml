import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property var date;

    property int highlightedHour;

    property string pageTitle;

    // Track the max price of the day for proportional bar widths
    property real maxPrice: 1.0

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
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
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
                interval: 900000 // default 15 mins
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    var today = new Date();
                    var tomorrow = new Date();
                    tomorrow.setDate(tomorrow.getDate() + 1);
                    var hasData = dataController.hasDataForDate(tomorrow);
                    
                    if (!hasData && today.getHours() >= 13) {
                        dataController.fetchPrices(tomorrow);
                        interval = 60000; // Switch to 1 minute polling if data is missing after 13:00
                    } else {
                        interval = 900000; // Reset to 15 minutes when data exists or before 13:00
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
                    }
                }
            }

            ViewPlaceholder {
                enabled: view.model.count == 0
                text: dataController.proxyUrl.length === 0 ?
                    qsTr("Configure proxy URL in Settings") :
                    qsTr("Nothing here")
            }

            width: parent.width
            height: parent.height
            model: ListModel{}
            delegate: ListItem {
                id: delegateItem
                width: parent.width
                contentHeight: mainColumn.height
                highlighted: isHighlighted

                // Toggle expanded on click (if quarters are available)
                onClicked: {
                    if (hasQuarters) {
                        var newExpanded = !sectionExpanded;
                        view.model.setProperty(index, "sectionExpanded", newExpanded);
                    }
                }

                Column {
                    id: mainColumn
                    width: parent.width

                    // Main hour row with price bar
                    Item {
                        width: parent.width
                        height: Theme.itemSizeMedium

                        // Price bar background — proportional width based on price vs max
                        Rectangle {
                            id: priceBar
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height - Theme.paddingSmall * 2
                            width: page.maxPrice > 0 ? (parseFloat(price) / page.maxPrice) * parent.width : 0
                            color: Theme.rgba(Theme.highlightColor, 0.15)
                            radius: Theme.paddingSmall / 2

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                            }
                        }

                        // Hour label
                        Label {
                            id: hourLabel
                            anchors {
                                left: parent.left
                                leftMargin: Theme.horizontalPageMargin
                                verticalCenter: parent.verticalCenter
                            }
                            text: qsTr("%1:00").arg(hour)
                            color: isHighlighted ? Theme.highlightColor : Theme.primaryColor
                        }

                        // Price label
                        Label {
                            anchors {
                                right: parent.right
                                rightMargin: Theme.horizontalPageMargin
                                verticalCenter: parent.verticalCenter
                            }
                            text: price + " c/kWh"
                            font.pixelSize: Theme.fontSizeSmall
                            color: isHighlighted ? Theme.highlightColor : Theme.primaryColor
                        }

                        // Expand indicator for rows with quarter data
                        Label {
                            visible: hasQuarters
                            anchors {
                                right: parent.right
                                rightMargin: Theme.horizontalPageMargin
                                top: parent.top
                                topMargin: Theme.paddingSmall
                            }
                            text: sectionExpanded ? "▲" : "▼"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                    }

                    // Expanded quarter details
                    Column {
                        id: quarterColumn
                        width: parent.width
                        clip: true
                        height: (hasQuarters && sectionExpanded) ? implicitHeight : 0
                        opacity: height > 0 ? 1.0 : 0.0

                        Behavior on height {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }

                        Repeater {
                            model: hasQuarters ? [
                                { minute: ":00", qPrice: q0Price },
                                { minute: ":15", qPrice: q1Price },
                                { minute: ":30", qPrice: q2Price },
                                { minute: ":45", qPrice: q3Price }
                            ] : []

                            Item {
                                width: quarterColumn.width
                                height: Theme.itemSizeExtraSmall

                                // Quarter price mini-bar
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.horizontalPageMargin * 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: parent.height - Theme.paddingSmall * 2
                                    width: page.maxPrice > 0 ? (parseFloat(modelData.qPrice) / page.maxPrice) * (parent.width - Theme.horizontalPageMargin * 2) : 0
                                    color: Theme.rgba(Theme.highlightColor, 0.08)
                                    radius: Theme.paddingSmall / 2
                                }

                                Label {
                                    anchors {
                                        left: parent.left
                                        leftMargin: Theme.horizontalPageMargin * 2
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: hour + modelData.minute
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.secondaryColor
                                }
                                Label {
                                    anchors {
                                        right: parent.right
                                        rightMargin: Theme.horizontalPageMargin
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: modelData.qPrice + " c/kWh"
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.secondaryColor
                                }
                            }
                        }

                        // Thin separator after quarters
                        Separator {
                            width: parent.width - Theme.horizontalPageMargin * 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Theme.secondaryColor
                        }
                    }
                }
            }
            Component.onCompleted: {
                console.log("Completing page with " + page.date.getDate());

                page.getPrices(page.date);
            }
        }
    }

    // Calculate the max price from the current model
    function updateMaxPrice() {
        var max = 0;
        for (var i = 0; i < view.model.count; i++) {
            var item = view.model.get(i);
            var p = parseFloat(item.price);
            if (p > max) max = p;
            
            if (item.hasQuarters) {
                var q0 = parseFloat(item.q0Price);
                var q1 = parseFloat(item.q1Price);
                var q2 = parseFloat(item.q2Price);
                var q3 = parseFloat(item.q3Price);
                if (q0 > max) max = q0;
                if (q1 > max) max = q1;
                if (q2 > max) max = q2;
                if (q3 > max) max = q3;
            }
        }
        page.maxPrice = max > 0 ? max : 1.0;
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
        page.updateNextDayStatus();

        if (model) {
            // If model exists, use it immediately
            view.model = model;
            page.pageTitle = qsTr("Hourly rates on %1").arg(page.date.getDate() + "." + (page.date.getMonth() + 1) + ".");
            page.updateHighlight(today.getHours());
            page.updateMaxPrice();
            console.log("Using cached model for date.");
        } else {
            // If model is null, fetch the data
            dataController.fetchPrices(date);
        }
    }

    function updateNextDayStatus() {
        const tomorrow = new Date(page.date);
        tomorrow.setDate(tomorrow.getDate() + 1);

        var today = new Date();
        var tomorrowString = tomorrow.getFullYear() + "-" + dataController.zeroPad(tomorrow.getMonth() + 1) + "-" + dataController.zeroPad(tomorrow.getDate());
        const realTomorrow = new Date();
        realTomorrow.setDate(realTomorrow.getDate() + 1);

        if ((sameDate(page.date, today) && !dataController.hasDataForDate(tomorrowString)) || sameDate(page.date, realTomorrow)) {
            nextDay.enabled = false;
        } else {
            nextDay.enabled = true;
        }
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
                page.updateMaxPrice();
                page.pageTitle = qsTr("Hourly rates on %1").arg(page.date.getDate() + "." + (page.date.getMonth() + 1) + ".");
                console.log(page.date.getHours());
            }
            page.updateNextDayStatus();
        });
    }

    Connections {
        target: dataController
        onVatPercentChanged: page.getPrices(page.date)
        onBiddingZoneChanged: page.getPrices(page.date)
        onProxyUrlChanged: page.getPrices(page.date)
        onAlwaysShowQuartersChanged: page.getPrices(page.date)
    }
}

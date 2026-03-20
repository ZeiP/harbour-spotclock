import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

Item {
    id: controller

    // Signal: Emitted when the API call is successful and data is populated
    signal dataLoaded(var dateKey)
    // Signal: Emitted when zone list is fetched
    signal zonesLoaded()

    property var priceData: ({})

    property ListModel priceList: ListModel { }

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

    // Zone list for SettingsPage ComboBox
    property var zoneList: []

    // Expose settings as properties for other components to read
    property alias proxyUrl: settings.proxyUrl
    property alias biddingZone: settings.biddingZone
    property alias vatPercent: settings.vatPercent
    property alias alwaysShowQuarters: settings.alwaysShowQuarters
    property alias coverShowQuarters: settings.coverShowQuarters

    onBiddingZoneChanged: {
        priceData = {};
    }

    onVatPercentChanged: {
        priceData = {};
    }

    onAlwaysShowQuartersChanged: {
        priceData = {};
    }

    onProxyUrlChanged: {
        priceData = {};
    }

    function zeroPad(n) {
        return ("0" + n).slice(-2);
    }

    function hasDataForDate(targetDate) {
        var dateString;
        if (typeof targetDate !== 'string') {
            dateString = targetDate.getFullYear() + "-" + zeroPad(targetDate.getMonth() + 1) + "-" + zeroPad(targetDate.getDate());
        }
        else {
            dateString = targetDate;
        }
        return priceData.hasOwnProperty(dateString);
    }

    function getModelForDate(targetDate) {
        var dateString;
        if (typeof targetDate !== 'string') {
            dateString = targetDate.getFullYear() + "-" + zeroPad(targetDate.getMonth() + 1) + "-" + zeroPad(targetDate.getDate());
        }
        else {
            dateString = targetDate;
        }

        console.log("Looking up data for key:", dateString);

        if (priceData.hasOwnProperty(dateString)) {
            var model = priceData[dateString];
            console.log("Model found:", model);

            priceList.clear()
            for (var i = 0; i < model.length; i++) {
                priceList.append(model[i]);
            }
            console.log("Set model to " + dateString + " firstprice " + model[0]['price']);
            return priceList;
        } else {
            console.warn("No data found for", dateString, ". Returning null.");
            return null;
        }
    }

    function request(url, method, data, callback) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = (function(mxhr) {
            return function() {
                console.log(mxhr.readyState);
                if(mxhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                    callback(mxhr);
                }
                else if (xhr.readyState === 4) {
                    console.error("Error fetching data from API with status code " + xhr.status);
                }
            }
        })(xhr);
        xhr.onerror = function() {
            console.error("The request failed due to a network error (e.g., offline, DNS failure, server not responding).");
        };

        console.log(url);
        xhr.open(method, url, true);
        xhr.responseType = 'json';
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("Accept", "application/json");
        if(method === "post" || method === "put") {
            xhr.send(data);
        }
        else {
            xhr.send('');
        }
    }

    function fetchZones() {
        if (!settings.proxyUrl || settings.proxyUrl.length === 0) {
            console.warn("Proxy URL not configured, cannot fetch zones");
            return;
        }
        var url = settings.proxyUrl + "/zones";
        request(url, "get", "", function(doc) {
            var json = doc.response;
            if (json && json.zones) {
                zoneList = json.zones;
                zonesLoaded();
                console.log("Loaded " + json.zones.length + " zones from proxy");
            }
        });
    }

    function fetchPrices(date) {
        var dateString = date.getFullYear() + "-" + zeroPad(date.getMonth() + 1) + "-" + zeroPad(date.getDate());

        if (!settings.proxyUrl || settings.proxyUrl.length === 0) {
            console.error("Proxy URL not configured");
            return;
        }

        var url = settings.proxyUrl + "/prices/" + settings.biddingZone + "/" + dateString;
        console.log(url);
        request(url, "get", "", function(doc) {
            var priceEntry = [];
            var json = doc.response;

            if (!json || !json.prices) {
                console.error("Invalid response from proxy");
                return;
            }

            var vatMultiplier = 1.0;
            var vat = parseFloat(settings.vatPercent);
            if (!isNaN(vat) && vat > 0) {
                vatMultiplier = 1.0 + vat / 100.0;
            }

            for (var i = 0; i < json.prices.length; i++) {
                var entry = json.prices[i];
                var item = {};
                item.hour = entry.hour;
                item.price = (parseFloat(entry.price) * vatMultiplier).toFixed(3);
                item.isHighlighted = false;
                item.sectionExpanded = settings.alwaysShowQuarters;

                // Handle quarter data
                if (entry.quarters && entry.quarters.length > 0) {
                    item.hasQuarters = true;
                    item.q0Price = (parseFloat(entry.quarters[0].price) * vatMultiplier).toFixed(3);
                    item.q1Price = (parseFloat(entry.quarters[1].price) * vatMultiplier).toFixed(3);
                    item.q2Price = (parseFloat(entry.quarters[2].price) * vatMultiplier).toFixed(3);
                    item.q3Price = (parseFloat(entry.quarters[3].price) * vatMultiplier).toFixed(3);
                } else {
                    item.hasQuarters = false;
                    item.q0Price = "0";
                    item.q1Price = "0";
                    item.q2Price = "0";
                    item.q3Price = "0";
                }

                priceEntry.push(item);
            }
            priceData[dateString] = priceEntry;
            console.log("Setting " + dateString + " prices from proxy");

            var dateObject = new Date(date);
            dataLoaded(dateObject); // Emit the signal
            console.log("--- SIGNAL EMITTED for " + dateString);
        });
    }
}

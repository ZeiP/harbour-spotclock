import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: controller

    // Signal: Emitted when the API call is successful and data is populated
    signal dataLoaded(var dateKey)

    property var priceData: ({})

    property ListModel priceList: ListModel { }

    function getModelForDate(targetDate) {
        var dateString;
        if (typeof targetDate !== 'string') {
            dateString = targetDate.getFullYear() + "-" + (targetDate.getMonth() + 1) + "-" + targetDate.getDate();
        }
        else {
            dateString = targetDate;
        }

        console.log("Looking up data for key:", dateString);

        // 2. Check if the model exists in the priceData structure.
        if (priceData.hasOwnProperty(dateString)) {
            var model = priceData[dateString];
            console.log("Model found:", model);

            // 3. Return the ListModel object.
            priceList.clear()
            for (var i = 0; i < model.length; i++) {
                priceList.append(model[i]);
            }
            console.log("Set model to " + dateString + " firstprice " + model[0]['price']);
            return priceList;
        } else {
            // 4. If the data is not yet in the structure, you can return an empty model
            // or trigger a fetch. Since your getPrices() handles the fetch,
            // returning an empty model is safer here.
            console.warn("No data found for", dateString, ". Returning null.");
            return null; // Or return Qt.createQmlObject('ListModel {}', page);
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

    function fetchPrices(date) {
        var dateString = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();

        var url = "https://www.sahkohinta-api.fi/api/v1/halpa?tunnit=24&tulos=sarja&aikaraja=" + date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
//        var url = "https://example.org";
        console.log(url);
        request(url, "get", "", function(doc) {
//            var fakeResponse = '[{"aikaleima_suomi":"2025-12-07T00:00","aikaleima_utc":"2025-12-06T22:00","hinta":1.241},{"aikaleima_suomi":"2025-12-07T01:00","aikaleima_utc":"2025-12-06T23:00","hinta":1.073},{"aikaleima_suomi":"2025-12-07T02:00","aikaleima_utc":"2025-12-07T00:00","hinta":0.96},{"aikaleima_suomi":"2025-12-07T03:00","aikaleima_utc":"2025-12-07T01:00","hinta":0.852},{"aikaleima_suomi":"2025-12-07T04:00","aikaleima_utc":"2025-12-07T02:00","hinta":0.732},{"aikaleima_suomi":"2025-12-07T05:00","aikaleima_utc":"2025-12-07T03:00","hinta":0.925},{"aikaleima_suomi":"2025-12-07T06:00","aikaleima_utc":"2025-12-07T04:00","hinta":0.993},{"aikaleima_suomi":"2025-12-07T07:00","aikaleima_utc":"2025-12-07T05:00","hinta":1.434},{"aikaleima_suomi":"2025-12-07T08:00","aikaleima_utc":"2025-12-07T06:00","hinta":1.898},{"aikaleima_suomi":"2025-12-07T09:00","aikaleima_utc":"2025-12-07T07:00","hinta":1.987},{"aikaleima_suomi":"2025-12-07T10:00","aikaleima_utc":"2025-12-07T08:00","hinta":2.113},{"aikaleima_suomi":"2025-12-07T11:00","aikaleima_utc":"2025-12-07T09:00","hinta":2.177},{"aikaleima_suomi":"2025-12-07T12:00","aikaleima_utc":"2025-12-07T10:00","hinta":2.45},{"aikaleima_suomi":"2025-12-07T13:00","aikaleima_utc":"2025-12-07T11:00","hinta":2.558},{"aikaleima_suomi":"2025-12-07T14:00","aikaleima_utc":"2025-12-07T12:00","hinta":2.714},{"aikaleima_suomi":"2025-12-07T15:00","aikaleima_utc":"2025-12-07T13:00","hinta":3.141},{"aikaleima_suomi":"2025-12-07T16:00","aikaleima_utc":"2025-12-07T14:00","hinta":3.328},{"aikaleima_suomi":"2025-12-07T17:00","aikaleima_utc":"2025-12-07T15:00","hinta":3.658},{"aikaleima_suomi":"2025-12-07T18:00","aikaleima_utc":"2025-12-07T16:00","hinta":3.694},{"aikaleima_suomi":"2025-12-07T19:00","aikaleima_utc":"2025-12-07T17:00","hinta":3.489},{"aikaleima_suomi":"2025-12-07T20:00","aikaleima_utc":"2025-12-07T18:00","hinta":3.165},{"aikaleima_suomi":"2025-12-07T21:00","aikaleima_utc":"2025-12-07T19:00","hinta":3.14},{"aikaleima_suomi":"2025-12-07T22:00","aikaleima_utc":"2025-12-07T20:00","hinta":3.271},{"aikaleima_suomi":"2025-12-07T23:00","aikaleima_utc":"2025-12-07T21:00","hinta":3.171}]';

            var priceEntry = [];

            var json = doc.response;
            for(var i = 0; i < json.length; i++) {
                var tl = json[i];
                var item = {}
                var dateObject = new Date(tl.aikaleima_utc);
                item.price = (parseFloat(tl.hinta) * 1.255).toFixed(3); // Handle the VAT like this for now.
                item.hour = dateObject.getHours();
                item.isHighlighted = false;
                priceEntry.push(item);
            }
            priceData[dateString] = priceEntry;
            console.log("Setting " + dateString + "to lastprice " + tl.hinta);

            dataLoaded(dateObject); // Emit the signal
            console.log("--- SIGNAL EMITTED for " + dateString);
        });
    }
}

import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow {
    initialPage: Component { ListPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    ListModel { id: priceList }



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
}

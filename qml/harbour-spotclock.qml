import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "cover"

ApplicationWindow {
    initialPage: Component { ListPage { date: new Date() } }
    DataController { id: dataController }
    cover: CoverPage {
        controller: dataController
    }
    allowedOrientations: defaultAllowedOrientations

    function sameDate(date1, date2) {
        console.log("Comparing" + date1.getFullYear() + date2.getFullYear() + date1.getMonth() + date2.getMonth() + date1.getDate() + date2.getDate());
        return date1.getFullYear() === date2.getFullYear() && date1.getMonth() === date2.getMonth() && date1.getDate() === date2.getDate();
    }
}

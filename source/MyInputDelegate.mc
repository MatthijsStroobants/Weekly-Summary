import Toybox.Graphics;
import Toybox.WatchUi;



class MyInputDelegate extends WatchUi.InputDelegate {

    var parentView;


    function initialize(view) {
        InputDelegate.initialize();
        parentView = view;
    }


    function onKey(keyEvent) {

        // Cycle through display modes
        switch (keyEvent.getKey()) {
            case WatchUi.KEY_UP:
                parentView.shiftWeek = (parentView.shiftWeek + 1) % (parentView.wToKeep - parentView.wOnDisplay + 1); // shift weeks forward
                WatchUi.requestUpdate();
                return true;
            case WatchUi.KEY_DOWN:
                parentView.sportMode = (parentView.sportMode + 1) % parentView.sports.size();
                WatchUi.requestUpdate(); // redraw the view
                return true;
            case WatchUi.KEY_ENTER:
                parentView.metricMode = (parentView.metricMode + 1) % parentView.metrics.size(); 
                WatchUi.requestUpdate(); // redraw the view
                return true;
            default:
                return false; // not handled
        }

    }


    function onTap(clickEvent) {
        System.println(clickEvent.getType());      // e.g. CLICK_TYPE_TAP = 0
        return true;
    }


    function onSwipe(swipeEvent) {
        // Cycle through display modes
        switch (swipeEvent.getDirection()) {
            case WatchUi.SWIPE_RIGHT:
                parentView.shiftWeek = (parentView.shiftWeek + 1) % (parentView.wToKeep - parentView.wOnDisplay + 1); // shift weeks forward
                WatchUi.requestUpdate();
                return true;
            case WatchUi.SWIPE_LEFT:
                parentView.shiftWeek = (parentView.shiftWeek + parentView.wToKeep - parentView.wOnDisplay) % (parentView.wToKeep - parentView.wOnDisplay + 1); // shift weeks forward
                WatchUi.requestUpdate();
                return true;
            case WatchUi.SWIPE_UP:
                parentView.sportMode = (parentView.sportMode + 1) % parentView.sports.size();
                WatchUi.requestUpdate(); // redraw the view
                return true;
            case WatchUi.SWIPE_DOWN:
                parentView.sportMode = (parentView.sportMode + parentView.sports.size() - 1) % parentView.sports.size(); 
                WatchUi.requestUpdate(); // redraw the view
                return true;
            default:
                return false; // not handled
        }
    }
}
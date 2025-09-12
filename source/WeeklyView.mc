import Toybox.Graphics;
import Toybox.WatchUi;


(:typecheck(false))
class WeeklyView extends WatchUi.View {

    var totals          = {};   // nested dictionary with totals per sport and metric per week

    var sports          = [];   // e.g. ["Run", "Bike", "Swim"]
    var metrics         = [];   // e.g. ["Dist", "Time"]

    var displayMode     = 0;    // 0 = weekly runs, 1 = something else, etc.
    var sportMode       = 0;    // 0 = run, 1 = bike, 2 = swim
    var metricMode      = 0;    // 0 = distance, 1 = time

    var shiftWeek       = 0;    // number of weeks to shift the display (0 = this week, 1 = last week, etc.)
    var wToKeep         = 9;    // number of weeks to keep in memory
    var wOnDisplay      = 5;    // number of weeks to display (max 11, including this week)
    
    var screenWidth;            // width of the screen
    var screenHeight;           // height of the screen

    // Bar parameters
    var barWidth;               // width of each bar
    var barHeight;              // height of each bar
    var maxBarHeight;           // max height of the tallest bar
    var colorBar;               // color of the bars

    var valWeek         = 0;    // distance for each week
    var maxVal          = 0;    // max distance among the weeks to scale the bars

    var labels          = ["This", "-1", "-2", "-3", "-4", "-5", "-6", "-7", "-8", "-9", "-10"]; // labels for the bars (this week, last week, etc.)

    // Coordinates
    var xTitle,         yTitle;         // position for the title
    var xAxisLabels,    yAxisLabels;    // position for the y-axis labels
    var xAxisVals,      yAxisVals;     // position for the x-axis values
    var xLegend,        yLegend;        // position for the legend
    var x,              y;              // position for each bar


    function initialize(localTotals, numWeeksToKeep, sportArray, metricArray) {
        View.initialize();

        totals  = localTotals;
        wToKeep = numWeeksToKeep;
        sports  = sportArray;
        metrics = metricArray;
    }


    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }


    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }


    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        // View.onUpdate(dc);

        screenWidth  = dc.getWidth();
        screenHeight = dc.getHeight();

        // Update Bar parameters
        barWidth     = ( 0.7 * screenWidth.toFloat() / (wOnDisplay+1.5) ).toNumber();
        maxBarHeight = (screenHeight * 0.6 * 0.6).toNumber(); 

        yTitle       = (screenHeight * 0.10).toNumber(); // y position for the title
        xTitle       = (screenWidth / 2    ).toNumber();                  // x 

        dc.clear(); // clear the screen
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(xTitle, yTitle, Graphics.FONT_SYSTEM_MEDIUM, sports[sportMode], Graphics.TEXT_JUSTIFY_CENTER);
        
        drawVertBars(dc);
    }


    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }


    // Draw vertical bars for weekly distances
    function drawVertBars(dc as Dc) as Void {
        
        xLegend     = ( screenWidth  / 2    ).toNumber();   
        yLegend     = ( screenHeight * 0.85 ).toNumber();

        maxVal      = 0; // reset maxVal

        // Find max value among chosen number of weeks for scaling
        for ( var week = 0; week < wToKeep; week += 1 ) {
            valWeek = totals[sports[sportMode]][metrics[metricMode]].hasKey(week) ? totals[sports[sportMode]][metrics[metricMode]][week] : 0;

            if ( valWeek > maxVal ) {
                maxVal = valWeek;
            }
        }
        if ( maxVal == 0 ) { maxVal = 1; } // avoid div by zero


        // Draw bars (this week = 0, last = 1, etc.)
        for (var w = 0; w < wOnDisplay; w += 1) {
            var week = (w + shiftWeek); // wrap around if shifting beyond available weeks
           
            if      ( week == 0 )                          { colorBar = Graphics.COLOR_PURPLE;   } 
            else if ( metrics[metricMode].equals("Dist") ) { colorBar = Graphics.COLOR_BLUE;     } 
            else                                           { colorBar = Graphics.COLOR_DK_GREEN; }

            // Get distance and scale to bar height
            valWeek     = totals[sports[sportMode]][metrics[metricMode]].hasKey(week) ? totals[sports[sportMode]][metrics[metricMode]][week] : 0;
            barHeight   = (valWeek.toFloat() / maxVal.toFloat()) * maxBarHeight.toFloat();

            if ( barHeight < 1.0 ) { barHeight = 1; } // minimum bar height

            // Calculate bar position
            x           = ( 0.15 * screenWidth + (1.0 - w.toFloat()/(wOnDisplay-1)) * (0.6 * screenWidth) ).toNumber();
            y           = ( screenHeight * 0.70                                                           ).toNumber();

            xAxisLabels = x + barWidth / 2;
            yAxisLabels = y + 5;

            xAxisVals   = x + barWidth / 2;
            yAxisVals   = y - barHeight - (5 + screenHeight*0.08).toNumber();


            // Draw bar growing from bottom to top
            dc.setColor     (colorBar, Graphics.COLOR_BLACK);
            dc.fillRectangle(x, y, barWidth, -barHeight);

            // Label at bottom (below the bar)
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawText(xAxisLabels, 
                        yAxisLabels,
                        Graphics.FONT_XTINY, 
                        labels[week],
                        Graphics.TEXT_JUSTIFY_CENTER);
            
            // "Weekly Dist." label below the bottom labels
            dc.drawText(xLegend, 
                        yLegend, 
                        Graphics.FONT_XTINY, 
                        metrics[metricMode] + " / Week", 
                        Graphics.TEXT_JUSTIFY_CENTER);

            // Distance text above the bar
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawText(xAxisVals, 
                        yAxisVals,
                        Graphics.FONT_XTINY,
                        valWeek.format("%.0f"),
                        Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}



import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.UserProfile;
import Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;


(:typecheck(false))
class WeeklyApp extends Application.AppBase {

    const numWeeksToKeep = 10;

    var totals       = {};
    var sports       = [ "Run", "Bike", "Swim" ];
    var metrics      = [ "Dist", "Time" ];
    var sports_size  = sports.size();
    var metrics_size = metrics.size();

    var now;                
    var nowUTC;
    var currentDate;
    var currentDateUTC;
    var currentDOW;
    var nextMondayMoment;


    function initialize() {
        AppBase.initialize();
    }


    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        putSportType    (); // initialize the sport types in the totals dictionary
        putSportMetric  (); // initialize the metrics for each sport type
        putPastWeeks    (); // initialize past weeks to zero
        getInfoToday    (); // get current date info
        getWeeklies     (); // populate the totals dictionary
        // populateSampleData();
    }


    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }


    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view             = new WeeklyView(totals, numWeeksToKeep, sports, metrics);
        var delegate         = new MyInputDelegate(view);

        return [ view, delegate ];
    }


    function getArrays() as [Array, Array] {
        return [ sports, metrics ];
    }


    // Initialize the sport types in the totals dictionary
    function putSportType() as Void {
        // var sports_size = sports.size();

        for (var i = 0; i < sports_size; i += 1) {
            totals.put(sports[i], {});
        }
    }


    // Initialize the metrics for each sport type
    function putSportMetric() as Void {
        for (var i = 0; i < sports_size; i += 1) {
            for (var j = 0; j < metrics_size; j += 1) {
                totals[sports[i]].put(metrics[j], {});
            }
        }
    }


    // Initialize past weeks to zero
    function putPastWeeks() as Void {
        for (var i = 0; i < sports_size; i += 1) {
            for (var j = 0; j < metrics_size; j += 1) {
                for (var k = 0; k <= numWeeksToKeep; k += 1) {
                    totals[sports[i]][metrics[j]].put(k, 0.0);
                }
            }
        }
    }


    // Convert total distances to km
    function convTotDist2km() as Void {
        for (var i = 0; i < sports_size; i += 1) {
            for (var k = 0; k <= numWeeksToKeep; k += 1) {
                totals[sports[i]]["Dist"][k] = (totals[sports[i]]["Dist"][k] * 0.001).toNumber(); // convert m to km
            }
        }
    }


    // Convert total time to hours
    function convTotTime2h() as Void {
        for (var i = 0; i < sports_size; i += 1) {
            for (var k = 0; k <= numWeeksToKeep; k += 1) {
                totals[sports[i]]["Time"][k] = (totals[sports[i]]["Time"][k] / (60*60)); // convert to sec to hours
            }
        }
    }


    // Get current date info
    function getInfoToday() as Void {
        now                 = new Time.Moment(Time.now().value());                
        nowUTC              = Gregorian.utcInfo(now, Time.FORMAT_SHORT);
        now                 = new Time.Moment(Gregorian.moment({    :year   =>  nowUTC.year,
                                                                    :month  =>  nowUTC.month,
                                                                    :day    =>  nowUTC.day,
                                                                    :hour   =>  0,
                                                                    :min    =>  0,
                                                                    :sec    =>  0                 
                                                                }).value());
        currentDOW          = nowUTC.day_of_week;                           // 1=Sunday, 7=Saturday
        nextMondayMoment    = new Time.Moment(now.value() - ((currentDOW + 5) % 7) * 86400 + 86400*7); // shift to next Monday if today is Monday
    }


    function weeksAgo(activityDate as Time.Moment, currentMonday as Time.Moment) as Number {
        // Find Monday of the activity week
        var activityUTC     = Gregorian.utcInfo(activityDate, Time.FORMAT_SHORT);
        var activityDOW     = activityUTC.day_of_week; // 1=Sunday, 7=Saturday
        var daysSinceMonday = (activityDOW + 5) % 7; // Monday=0, Sunday=6
        var activityMonday  = new Time.Moment(activityDate.value() - (daysSinceMonday * 86400));

        // Calculate full weeks difference
        var diffSeconds     = currentMonday.value() - activityMonday.value();
        var weeksAgo        = (diffSeconds / (7 * 86400)).toNumber();

        return weeksAgo;
    }


    // Retrieve weekly totals for running, cycling, and swimming
    function getWeeklies() as Void {
        var userActivityIterator = UserProfile.getUserActivityHistory();
        var sample               = userActivityIterator.next();                        // get the user activity data


        // Iterate through the activity samples
        while (sample != null) {
            var activitySport   = sample.type;
            var activityDate    = sample.startTime;
            var weekKey         = weeksAgo(activityDate, nextMondayMoment);

        
            // Skip activities that are not running, cycling, or swimming
            if (   activitySport != Activity.SPORT_RUNNING
                && activitySport != Activity.SPORT_CYCLING
                && activitySport != Activity.SPORT_SWIMMING ) {

                sample = userActivityIterator.next(); 
                continue;
            }

            // Ensure the activity has a valid date
            if (activityDate == null) {
                sample = userActivityIterator.next(); 
                continue;
            }

            // Accumulate distance for activities within the time window
            // if ( (currentDate.value() - activityDate.value()) <= timeWeeksToKeep) { 
            if ( weekKey <= numWeeksToKeep) { 
                if (sample.distance > 0) {
                    if (activitySport == Activity.SPORT_RUNNING) {
                        totals["Run"]["Dist"][weekKey] += sample.distance;
                        totals["Run"]["Time"][weekKey] += sample.duration.value();
                    }
                    else if (activitySport == Activity.SPORT_CYCLING) {
                        totals["Bike"]["Dist"][weekKey] += sample.distance;
                        totals["Bike"]["Time"][weekKey] += sample.duration.value();
                    }
                    else if (activitySport == Activity.SPORT_SWIMMING) {
                        totals["Swim"]["Dist"][weekKey] += sample.distance;
                        totals["Swim"]["Time"][weekKey] += sample.duration.value();
                    }
                }
            }
            sample = userActivityIterator.next(); // get the next sample
        }

        convTotDist2km(); // convert total distances to km
        convTotTime2h();  // convert total time to hours
    }

        // Populate the totals dictionary with synthetic sample data for the last 10 weeks
    function populateSampleData() as Void {
        // For each sport and each metric, assign sample data for each weekKey
        for (var i = 0; i < sports_size; i += 1) {
            var sport = sports[i];
            for (var k = 0; k <= numWeeksToKeep; k += 1) {
                // Use different scaling for each sport so they are distinguishable
                if (sport.equals("Run")) {
                    // Distance in meters, time in seconds
                    totals["Run"]["Dist"][k] = 10000 * (numWeeksToKeep -k) * 0.7; // 10km, 20km, ... in meters
                    totals["Run"]["Time"][k] = 3600 * (numWeeksToKeep -k) * 0.7;  // 1h, 2h, ... in seconds
                } else if (sport.equals("Bike")) {
                    totals["Bike"]["Dist"][k] = 25000 * (numWeeksToKeep -k) * 0.7; // 25km, 50km, ... in meters
                    totals["Bike"]["Time"][k] = 5400 * (numWeeksToKeep -k) * 0.7;  // 1.5h, 3h, ... in seconds
                } else if (sport.equals("Swim")) {
                    totals["Swim"]["Dist"][k] = 2000 * (numWeeksToKeep -k) * 0.7;  // 2km, 4km, ... in meters
                    totals["Swim"]["Time"][k] = 1800 * (numWeeksToKeep -k) * 0.7;  // 0.5h, 1h, ... in seconds
                }
            }
        }
        // Convert units to km and hours for consistency
        convTotDist2km();
        convTotTime2h();
    }

}


function getApp() as WeeklyApp {
    return Application.getApp() as WeeklyApp;
}
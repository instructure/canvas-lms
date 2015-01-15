# Notifications

This guide gets you up to speed on how to display notifications to the user when something that needs their attention happens. Currently, we have support for "stateful" notifications that are spawned based on application state.

I'll use a concrete example to explain the APIs. We'll talk about the process of generating CSV quiz reports and displaying notifications when that process fails.

## Notification watchers

Traditionally, the responsibility of displaying notifications regarding a certain process was directly or indirectly laid on the same piece of logic that does the processing, like in our case the QuizReport store. Using "watchers", we try to do things differently.

A notification watcher is a simple function that gets run anytime something interesting happens, like starting a quiz report generation process, or receiving an update about its completion status.

For our purposes, what we'll do is define a watcher that watches that store for its "change" event and then look for all reports that had *failed* and spawn a notification for each one.

Before we start implementing our watcher, however, we must assign our notification a unique *code* in `constants.js` that other components can 
use to identify the type of notifications we'll be spawning, like the view
for example. We'll choose `NOTIFICATION_REPORT_GENERATION_FAILED` - the 
value of this key is any integer that's not occupied by another 
notification code which you can see in the list.

```javascript
/** src/js/constants.js */
define({
    // ...
    NOTIFICATION_REPORT_GENERATION_FAILED: 123,
    // ...
});
```

Now we're ready to write our watcher. We'll create a new file in `notifications/report_generation_failed.js` and get cooking.

```javascript
/** src/js/notifications/report_generation_failed.js */
// omitting r.js and irrelevant shizzle for brevity

var K = require('constants');
var ReportStore = require('stores/reports');

var watchForReportGenerationFailures = function() {
    // 1. find all reports that are being generated and have failed:
    var failedReports = reportStore.getAll().filter(function(report) {
        return report.get('isGenerating') &&
               report.get('progress').workflowState === 'failed';
    });

    // 2. spawn a notification for every one that did:
    return failedReports.map(function(report) {
        var notification = new Notification();

        // stamp the notification with the code we defined earlier:
        notification.code = K.NOTIFICATION_REPORT_GENERATION_FAILED;

        // we must generate a unique *id* for this notification instance
        // so that we can do funny things with it, like dismissing it
        //
        // the id will make use of the report's id and we'll prefix it
        // with a relatively unique string as to not clash with other
        // notifications
        notification.id = 'report_generation_failures_' + report.id;

        // finally, we'll also attach some context so that our view can
        // present a nice message
        notification.context = {
            reportId: report.id, // more on this later
            reportType: report.reportType
        };

        return notification;
    });
}
```

Phew! Done with that.

Now we need to wire things up with the notification store now to get our watcher registered. We do that by listing our file as a dependency of the notification bundle in `bundles/notifications.js` but that file is generated automatically when you run the grunt task `generate_notification_bundle` or just `grunt`.

### Notification views

[TBD]
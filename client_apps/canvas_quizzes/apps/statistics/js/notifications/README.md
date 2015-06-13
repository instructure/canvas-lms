## Notification watchers

Modules in this directory are expected to watch targets for anything
worth notifying the user of. Refer to the notification guide for more
info.

A watcher is a simple function that gets run anytime it says it should[1]
and generates any number of notifications when it does. The return value
must be an array of zero or more Notification objects.

What you do inside the watcher is your own business, the only requirement is
the return value and the function should probably be re-entrant because it
will be run many times.

[1] A watcher can specify targets to watch, like stores for their "change"
event.

### Example

Here's a sample implementation of watching the user store for any person
slipping on a street off of a banana and generating notifications anytime
it happens.

```javascript
var UserStore = require('stores/users');
var Notification = require('models/notification');
var K = require('constants');

function watchForPeopleSlippingOffOfBananas() {
    var peopleWhoSlipped = UserStore.findPeopleWhoSlipped();

    return peopleWhoSlipped.map(function(user) {
        return new Notification({
            id: [ 'someone_slipped_off_of_a_banana', user.id ].join('_'),

            // this should be defined in constants.js with a key like:
            // NOTIFICATION_SOMEONE_SLIPPED_OFF_OF_A_BANANA
            code: K.NOTIFICATION_SOMEONE_SLIPPED_OFF_OF_A_BANANA,

            // You can specify any additional context that the view can make
            // use of, like the name of the street the person slipped on:
            context: {
                streetName: "strönd"
            }
        });
    });
}

watchForPeopleSlippingOffOfBananas.watchTargets = [
  UserStore
];

return watchForPeopleSlippingOffOfBananas;
```

Finally, make sure you register your notification watcher in `bundles/notifications.js`.
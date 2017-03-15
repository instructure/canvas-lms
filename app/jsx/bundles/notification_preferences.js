require [
  'jquery'
  'INST'
  'compiled/notifications/NotificationPreferences'
  'compiled/notifications/privacyNotice'
  'compiled/profile/confirmEmail'
], ($, INST, NotificationPreferences, initPrivacyNotice) ->
  new NotificationPreferences(ENV.NOTIFICATION_PREFERENCES_OPTIONS)

  $ ->
    initPrivacyNotice()


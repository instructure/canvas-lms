require [
  'INST'
  'compiled/notifications/NotificationPreferences'
  'compiled/notifications/privacyNotice'
  'compiled/profile/confirmEmail'
], (INST, NotificationPreferences, initPrivacyNotice) ->
  ENV.NOTIFICATION_PREFERENCES_OPTIONS.touch = INST.browser.touch
  new NotificationPreferences(ENV.NOTIFICATION_PREFERENCES_OPTIONS)

  $ ->
    initPrivacyNotice()


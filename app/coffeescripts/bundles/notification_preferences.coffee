require [
  'INST'
  'ENV'
  'compiled/notifications/NotificationPreferences'
  'compiled/profile/confirmEmail'
], (INST, ENV, NotificationPreferences) ->
  ENV.NOTIFICATION_PREFERENCES_OPTIONS.touch = INST.browser.touch
  new NotificationPreferences(ENV.NOTIFICATION_PREFERENCES_OPTIONS)

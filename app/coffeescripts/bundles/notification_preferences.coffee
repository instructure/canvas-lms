require [
  'INST'
  'ENV'
  'compiled/notifications/NotificationPreferences'
], (INST, ENV, NotificationPreferences) ->
  ENV.NOTIFICATION_PREFERENCES_OPTIONS.touch = INST.browser.touch
  new NotificationPreferences(ENV.NOTIFICATION_PREFERENCES_OPTIONS)

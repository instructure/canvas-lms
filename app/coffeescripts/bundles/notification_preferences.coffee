require [
  'INST'
  'compiled/notifications/NotificationPreferences'
  'compiled/profile/confirmEmail'
], (INST, NotificationPreferences) ->
  ENV.NOTIFICATION_PREFERENCES_OPTIONS.touch = INST.browser.touch
  new NotificationPreferences(ENV.NOTIFICATION_PREFERENCES_OPTIONS)

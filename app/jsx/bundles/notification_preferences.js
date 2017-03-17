import $ from 'jquery'
import NotificationPreferences from 'compiled/notifications/NotificationPreferences'
import initPrivacyNotice from 'compiled/notifications/privacyNotice'
import 'compiled/profile/confirmEmail'

new NotificationPreferences(ENV.NOTIFICATION_PREFERENCES_OPTIONS)

$(() => initPrivacyNotice())

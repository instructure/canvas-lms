
// Sets up moment to use the right locale
const moment = require('moment')
// we already put a <script> tag for the locale corresponding ENV.MOMENT_LOCALE
// on the page from rails, so this should not cause a new network request.
moment().locale(ENV.MOMENT_LOCALE)


// These timezones and locales should already be put on the page as <script>
// tags from rails. this block should not create any network requests.
const tz = require('timezone_core')

if (typeof ENV !== 'undefined') {
  if (ENV.TIMEZONE) tz.changeZone(ENV.TIMEZONE)
  if (ENV.CONTEXT_TIMEZONE) tz.preload(ENV.CONTEXT_TIMEZONE)
  if (ENV.BIGEASY_LOCALE) tz.changeLocale(ENV.BIGEASY_LOCALE, ENV.MOMENT_LOCALE)
}

require('./fakeRequireJSFallback')

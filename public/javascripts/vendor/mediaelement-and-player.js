import 'jquery'

import 'mediaelement'
import 'mediaelement/src/js/mep-header'
import 'mediaelement/src/js/mep-library'
import 'mediaelement/src/js/mep-player'
import 'mediaelement/src/js/mep-feature-playpause'
import 'mediaelement/src/js/mep-feature-stop'
import 'mediaelement/src/js/mep-feature-progress'
import 'mediaelement/src/js/mep-feature-time'
import 'mediaelement/src/js/mep-feature-volume'
import 'mediaelement/src/js/mep-feature-fullscreen'
import '../mediaelement/mep-feature-tracks-instructure'
import '../mediaelement/mep-feature-speed-instructure'
import '../mediaelement/mep-feature-sourcechooser-instructure'
import 'mediaelement/src/js/mep-feature-googleanalytics'

// Import stylesheet and override
import 'mediaelement/build/mediaelementplayer.min.css'
import '../../../app/stylesheets/base/_custom_mediaelementplayer.css'


// Tell mediaelementJS to use strings for the user's locale.
// when we start doing locale-specific webpack builds,
// change window.ENV.LOCALE to process.env.BUILD_LOCALE
let strings
try {
  strings = require(`mediaelement/build/lang/me-i18n-locale-${window.ENV.LOCALE}`)
} catch (error) {
  // medialementjs doesn't have strings for this locale
}
if (strings) window.mejs.i18n.locale.language = window.ENV.LOCALE


export default window.mejs

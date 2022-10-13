/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

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
import 'mediaelement/src/js/mep-feature-speed'
import 'mediaelement/src/js/mep-feature-sourcechooser'

// Import stylesheet and override
import 'mediaelement/build/mediaelementplayer.min.css'
import '../../../app/stylesheets/base/_custom_mediaelementplayer.css'

// Our custom monkeypatches to MediaElement plguins:

import './mep-feature-tracks-instructure'

// only show the source chooser for <video>s, not for <audio>.
const orginalBuildsourcechooser = window.MediaElementPlayer.prototype.buildsourcechooser
window.MediaElementPlayer.prototype.buildsourcechooser = function (
  player,
  _controls,
  _layers,
  _media
) {
  if (!player.isVideo) return
  return orginalBuildsourcechooser.apply(this, arguments)
}

// INSTRUCTURE CUSTOMIZATION: add 0.50x playback speed option
window.mejs.MepDefaults.speeds.push('0.50')

// Tell mediaelementJS to use strings for the user's locale.
// when we start doing locale-specific webpack builds,
// change window.ENV.LOCALE to process.env.BUILD_LOCALE
import(`mediaelement/build/lang/me-i18n-locale-${window.ENV.LOCALE}`)
  .then(strings => {
    if (strings) window.mejs.i18n.locale.language = window.ENV.LOCALE
  })
  .catch(() => {
    // medialementjs doesn't have strings for this locale
  })

export default window.mejs

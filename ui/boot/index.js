/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {
  canvas as canvasBaseTheme,
  canvasHighContrast as canvasHighContrastTheme,
} from '@instructure/ui-themes'
import filterUselessConsoleMessages from '../../packages/filter-console-messages'
import moment from 'moment'
import './initializers/fakeRequireJSFallback'
import './initializers/ujsLinks'
import './initializers/initMutexes'
import {up as configureDateTimeMomentParser} from '@canvas/datetime/configureDateTimeMomentParser'
import {up as configureDateTime} from '@canvas/datetime/configureDateTime'
import {initSentry} from './initializers/initSentry'
import {up as renderRailsFlashNotifications} from './initializers/renderRailsFlashNotifications'
import {up as installNodeDecorations} from './initializers/installNodeDecorations'
import {up as activateCourseMenuToggler} from '@canvas/common/activateCourseMenuToggler'

// Import is required, workaround for ARC-8398
// eslint-disable-next-line import/no-nodejs-modules
import {Buffer} from 'buffer'
import {loadCareerTheme} from '@canvas/instui-bindings/react/career-theme-loader'

window.Buffer = Buffer

try {
  initSentry()
} catch (e) {
  console.error('Failed to init Sentry, errors will not be captured', e)
}

// add our custom method(s) to DOM classes if necessary
installNodeDecorations()

// we already put a <script> tag for the locale corresponding ENV.MOMENT_LOCALE
// on the page from rails, so this should not cause a new network request.
moment().locale(ENV.MOMENT_LOCALE)

let runOnceAfterLocaleFiles = () => {
  configureDateTimeMomentParser()
  configureDateTime()
  renderRailsFlashNotifications()
  activateCourseMenuToggler()
  import('@canvas/enhanced-user-content')
    .then(({enhanceTheEntireUniverse}) => enhanceTheEntireUniverse())
    .catch(e => {
      console.error('Failed to init @canvas/enhanced-user-content', e)
    })
}

window.addEventListener('canvasReadyStateChange', function ({detail}) {
  if (detail === 'capabilities' || window.canvasReadyState === 'complete') {
    runOnceAfterLocaleFiles()
    runOnceAfterLocaleFiles = () => {}
  }
})

// In non-prod environments only, arrange for filtering of "useless" console
// messages, and if deprecation reporting is enabled, arrange to inject and
// set up Sentry for it.
if (process.env.NODE_ENV !== 'production') {
  const setupConsoleMessageFilter = () => {
    try {
      filterUselessConsoleMessages(console)
    } catch (e) {
      console.error(`ERROR: could not set up console log filtering: ${e.message}`)
    }
  }

  setupConsoleMessageFilter()
}

// Set up the default InstUI theme
// Override the fontFamily to include "Lato Extended", which we prefer
// to load over plain Lato (see LS-1559)
const typography = {
  fontFamily: 'LatoWeb, "Lato Extended", Lato, "Helvetica Neue", Helvetica, Arial, sans-serif',
}

if (ENV.use_dyslexic_font) {
  typography.fontFamily = `OpenDyslexic, ${typography.fontFamily}`
}

// Check for high contrast mode from either ENV variable or URL query parameter
const urlParams = new URLSearchParams(window.location.search)
const hasHighContrastQueryParam = urlParams.get('instui_theme') === 'canvas_high_contrast'
const hasCareerQueryParam = urlParams.get('instui_theme') === 'career'

if (ENV.use_high_contrast || hasHighContrastQueryParam) {
  canvasHighContrastTheme.use({overrides: {typography}})
} else {
  const brandvars = window.CANVAS_ACTIVE_BRAND_VARIABLES || {}

  // Set CSS transitions to 0ms in Selenium and JS tests
  let transitionOverride = {}
  if (process.env.NODE_ENV === 'test' || window.INST.environment === 'test') {
    transitionOverride = {
      transitions: {
        duration: '0ms',
      },
    }
  }

  canvasBaseTheme.use({overrides: {...transitionOverride, ...brandvars, typography}})
}

if (hasCareerQueryParam) {
  const baseTheme =
    window.ENV.use_high_contrast || hasHighContrastQueryParam
      ? canvasHighContrastTheme
      : canvasBaseTheme
  loadCareerTheme().then(careerTheme => {
    if (careerTheme !== null) {
      baseTheme.use({overrides: careerTheme})
    }
  })
}

/* #__PURE__ */ if (process.env.NODE_ENV === 'test' || window.INST.environment === 'test') {
  // This is for the `wait_for_ajax_requests` method in selenium
  window.__CANVAS_IN_FLIGHT_XHR_REQUESTS__ = 0
  const send = XMLHttpRequest.prototype.send
  XMLHttpRequest.prototype.send = function () {
    window.__CANVAS_IN_FLIGHT_XHR_REQUESTS__++
    // 'loadend' gets fired after both successful and errored requests
    this.addEventListener('loadend', () => {
      window.__CANVAS_IN_FLIGHT_XHR_REQUESTS__--
    })
    return send.apply(this, arguments)
  }

  // and this so it also tracks `fetch` requests
  const fetch = window.fetch
  window.fetch = function () {
    window.__CANVAS_IN_FLIGHT_XHR_REQUESTS__++
    const promise = fetch.apply(this, arguments)

    promise.finally(() => {
      window.__CANVAS_IN_FLIGHT_XHR_REQUESTS__--
    })
    return promise
  }
}

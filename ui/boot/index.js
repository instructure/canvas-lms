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

import canvasBaseTheme from '@instructure/canvas-theme'
import canvasHighContrastTheme from '@instructure/canvas-high-contrast-theme'
import moment from 'moment'
import './initializers/fakeRequireJSFallback'
import {up as configureDateTimeMomentParser} from './initializers/configureDateTimeMomentParser'
import {up as configureDateTime} from './initializers/configureDateTime'
import {up as enableDTNPI} from './initializers/enableDTNPI'
import {initSentry} from './initializers/initSentry'

try {
  initSentry()
} catch (e) {
  // eslint-disable-next-line no-console
  console.error('Failed to init Sentry, errors will not be captured', e)
}

// we already put a <script> tag for the locale corresponding ENV.MOMENT_LOCALE
// on the page from rails, so this should not cause a new network request.
moment().locale(ENV.MOMENT_LOCALE)

configureDateTimeMomentParser()
configureDateTime()
enableDTNPI()

async function setupSentry() {
  const Raven = await import('raven-js')
  Raven.config(process.env.DEPRECATION_SENTRY_DSN, {
    release: process.env.GIT_COMMIT
  }).install()

  try {
    const {default: setup} = await import('./initializers/setupRavenConsoleLoggingPlugin')
    setup(Raven, {loggerName: 'console'})
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(`ERROR: could not set up Raven console logging: ${e.message}`)
  }
}

async function setupConsoleMessageFilter() {
  const {filterUselessConsoleMessages} = await import(
    '@instructure/js-utils/es/filterUselessConsoleMessages'
  )

  try {
    filterUselessConsoleMessages(console)
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(`ERROR: could not set up console log filtering: ${e.message}`)
  }
}

// In non-prod environments only, arrange for filtering of "useless" console
// messages, and if deprecation reporting is enabled, arrange to inject and
// set up Sentry for it.
if (process.env.NODE_ENV !== 'production') {
  setupConsoleMessageFilter()
  if (process.env.DEPRECATION_SENTRY_DSN) setupSentry()
}

// setup the inst-ui default theme
// override the fontFamily to include "Lato Extended", which we prefer
// to load over plain Lato (see LS-1559)
if (ENV.use_high_contrast) {
  canvasHighContrastTheme.use({
    overrides: {
      typography: {
        fontFamily: 'LatoWeb, "Lato Extended", Lato, "Helvetica Neue", Helvetica, Arial, sans-serif'
      }
    }
  })
} else {
  const brandvars = window.CANVAS_ACTIVE_BRAND_VARIABLES || {}

  // Set CSS transitions to 0ms in Selenium and JS tests
  let transitionOverride = {}
  if (process.env.NODE_ENV === 'test' || window.INST.environment === 'test') {
    transitionOverride = {
      transitions: {
        duration: '0ms'
      }
    }
  }

  canvasBaseTheme.use({
    overrides: {
      ...transitionOverride,
      ...brandvars,
      typography: {
        fontFamily: 'LatoWeb, "Lato Extended", Lato, "Helvetica Neue", Helvetica, Arial, sans-serif'
      }
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
      window.dispatchEvent(new CustomEvent('canvasXHRComplete'))
    })
    return send.apply(this, arguments)
  }

  // and this so it also tracks `fetch` requests
  const fetch = window.fetch
  window.fetch = function () {
    window.__CANVAS_IN_FLIGHT_XHR_REQUESTS__++
    const promise = fetch.apply(this, arguments)
    // eslint-disable-next-line promise/catch-or-return
    promise.finally(() => {
      window.__CANVAS_IN_FLIGHT_XHR_REQUESTS__--
      window.dispatchEvent(new CustomEvent('canvasXHRComplete'))
    })
    return promise
  }
}

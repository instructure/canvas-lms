/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import Enzyme from 'enzyme'
import Adapter from 'enzyme-adapter-react-16'
import {canvas} from '@instructure/ui-themes'
import en_US from 'timezone/en_US'
import './jsx/spec-support/specProtection'
import setupRavenConsoleLoggingPlugin from '../../ui/boot/initializers/setupRavenConsoleLoggingPlugin.js'
import {filterUselessConsoleMessages} from '@instructure/js-utils'

filterUselessConsoleMessages(console)

Enzyme.configure({adapter: new Adapter()})

if (process.env.SENTRY_DSN) {
  // This should allow us to capture more errors rather than just
  // "Script error"
  const Raven = require('raven-js')
  Raven.config(process.env.SENTRY_DSN, {
    ignoreErrors: ['renderIntoDiv', 'renderSidebarIntoDiv'], // silence the `Cannot read property 'renderIntoDiv' of null` errors we get from the pre- rce_enhancements old rce code
    release: process.env.GIT_COMMIT
  }).install()

  let deprecationsReporter = null

  if (process.env.DEPRECATION_SENTRY_DSN) {
    // We'll use this to collect deprecation warnings
    // Doing this like this isn't exactly... documented per se, but there is a
    // nice comment in the code about it here:
    // https://github.com/getsentry/sentry-javascript/blob/master/packages/raven-js/src/singleton.js#L33
    deprecationsReporter = new Raven.Client()
    deprecationsReporter.config(process.env.DEPRECATION_SENTRY_DSN, {
      ignoreErrors: ['renderIntoDiv', 'renderSidebarIntoDiv'], // silence the `Cannot read property 'renderIntoDiv' of null` errors we get from the pre- rce_enhancements old rce code
      release: process.env.GIT_COMMIT
    })

    setupRavenConsoleLoggingPlugin(deprecationsReporter, {loggerName: 'console-qunit'})
  }

  // QUnit is assumed global
  QUnit.testStart(({module, name}) => {
    Raven.setExtraContext() // Clear all extra data from the context.

    const context = {
      spec: `${module}: ${name}`
    }
    Raven.setExtraContext(context)

    if (deprecationsReporter) {
      deprecationsReporter.setExtraContext()
      deprecationsReporter.setExtraContext(context)
    }
  })
}

// Handle making sure we load in timezone data to prevent errors.
;(window.__PRELOADED_TIMEZONE_DATA__ || (window.__PRELOADED_TIMEZONE_DATA__ = {})).en_US = en_US

document.dir = 'ltr'
const fixturesDiv = document.createElement('div')
fixturesDiv.id = 'fixtures'
document.body.appendChild(fixturesDiv)

if (!window.ENV) window.ENV = {}

// setup the inst-ui default theme
canvas.use({
  overrides: {
    transitions: {
      duration: '0ms'
    }
  }
})

const requireAll = context => {
  const keys = context.keys()

  if (process.env.JSPEC_VERBOSE === '1') {
    console.log(`webpack_spec_index: running ${keys.length} files in ${process.env.JSPEC_PATH}`)
  }

  keys.map(context)
}

if (process.env.JSPEC_PATH) {
  let isFile = false
  try {
    isFile = __webpack_modules__[require.resolveWeak(`../../${process.env.JSPEC_PATH}`)]
  } catch (e) {}
  if (isFile) {
    require(`../../${process.env.JSPEC_PATH}`)
  } else {
    requireAll(require.context(`../../${process.env.JSPEC_PATH}`, process.env.JSPEC_RECURSE !== '0', /\.js$/))
  }
} else {
  requireAll(require.context(CONTEXT_COFFEESCRIPT_SPEC, process.env.JSPEC_RECURSE !== '0', RESOURCE_COFFEESCRIPT_SPEC))
  requireAll(require.context(CONTEXT_EMBER_GRADEBOOK_SPEC, process.env.JSPEC_RECURSE !== '0', RESOURCE_EMBER_GRADEBOOK_SPEC))
  requireAll(require.context(CONTEXT_JSX_SPEC, process.env.JSPEC_RECURSE !== '0', RESOURCE_JSX_SPEC))
}

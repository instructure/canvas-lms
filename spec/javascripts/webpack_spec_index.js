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

/* eslint-disable no-undef */
/* because the undefined constants are defined in webpack.test.config */

import Enzyme from 'enzyme'
import Adapter from 'enzyme-adapter-react-16'
import {canvas} from '@instructure/ui-themes'
import en_US from 'timezone/en_US'
import './jsx/spec-support/specProtection'
import filterUselessConsoleMessages from '@instructure/filter-console-messages'
import './jsx/spec-support/timezoneBackwardsCompatLayer'
import {up as configureDateTime} from 'ui/boot/initializers/configureDateTime'
import {up as configureDateTimeMomentParser} from 'ui/boot/initializers/configureDateTimeMomentParser'
import {useTranslations} from '@canvas/i18n'
import CoreTranslations from 'translations/en.json'

useTranslations('en', CoreTranslations)

filterUselessConsoleMessages(console)
configureDateTime()
configureDateTimeMomentParser()

Enzyme.configure({adapter: new Adapter()})

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
      duration: '0ms',
    },
  },
})

const requireAll = context => {
  const keys = context.keys()

  if (process.env.JSPEC_VERBOSE === '1') {
    // eslint-disable-next-line no-console
    console.log(`webpack_spec_index: running ${keys.length} files in ${process.env.JSPEC_PATH}`)
  }

  keys.map(context)
}

if (!process.env.JSPEC_PATH) {
  requireAll(
    require.context(
      CONTEXT_COFFEESCRIPT_SPEC,
      process.env.JSPEC_RECURSE !== '0',
      RESOURCE_COFFEESCRIPT_SPEC
    )
  )
  requireAll(
    require.context(
      CONTEXT_EMBER_GRADEBOOK_SPEC,
      process.env.JSPEC_RECURSE !== '0',
      RESOURCE_EMBER_GRADEBOOK_SPEC
    )
  )

  requireAll(
    require.context(CONTEXT_JSX_SPEC, process.env.JSPEC_RECURSE !== '0', RESOURCE_JSX_SPEC)
  )

  // eslint-disable-next-line import/no-dynamic-require
  require(WEBPACK_PLUGIN_SPECS)
}

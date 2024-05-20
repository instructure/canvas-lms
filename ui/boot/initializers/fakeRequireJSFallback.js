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

/*
  This shim is to try to not break code of our customers that use RequireJS-style
  `require`s in their Custom JS files from ThemeEditor. It is not meant to be comprehensive.
  There will be some customers that need to change their code, but there was a lot that
  just used require to load jquery or just load an external script. this should handle
  both of those cases.

  eg:

  require([
    'jquery',
    'https://code.jquery.com/color/jquery.color.js'
  ], function(_, $) {
    console.log('got', $, _, $.Color.names)
  })
  should log: jquery and the colors
*/
import $ from 'jquery'
import {captureException} from '@sentry/browser'

if (!('require' in window)) {
  const getDefaultExport = m => m.default

  const thingsWeStillAllowThemToRequire = {
    jquery: () => $,
    // load these asynchronously so they are not downloaded unless asked for
    i18nObj: () =>
      import(/* webpackChunkName: "[request]" */ '@canvas/i18n').then(getDefaultExport),

    'jsx/course_wizard/ListItems': () =>
      import('../../features/course_wizard/react/ListItems').then(getDefaultExport),
  }

  const getModule = module => {
    if (module in thingsWeStillAllowThemToRequire) {
      return thingsWeStillAllowThemToRequire[module]()
    } else if (/^(https?:)?\/\//.test(module)) {
      // starts with 'http://', 'https://' or '//'
      return $.getScript(module)
    } else {
      throw new Error(
        `Cannot load ${module}, use your own RequireJS or something else to load this script`
      )
    }
  }

  window.require = function fakeRequire(deps, callback) {
    console.warn(
      '`require`-ing internal Canvas modules comes with no warranty, ' +
        'things can change in any release and you are responsible for making sure your custom ' +
        'JavaScript that uses it continues to work.'
    )
    if (deps.includes('jquery')) {
      console.error("Support for require('jquery') is deprecated and will be removed.")
      captureException(new Error('require("jquery")'))
    }
    Promise.all(deps.map(getModule)).then(modules => {
      if (callback) callback(...modules)
    })
  }
}

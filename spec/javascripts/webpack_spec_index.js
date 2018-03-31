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

import { canvas } from '@instructure/ui-themes/lib'
import './support/sinon/sinon-qunit-1.0.0'

const fixturesDiv = document.createElement('div')
fixturesDiv.id = 'fixtures'
document.body.appendChild(fixturesDiv)

if (!window.ENV) window.ENV = {}

// setup the inst-ui default theme
canvas.use()

const requireAll = context => context.keys().map(context)

if (process.env.JSPEC_PATH) {
  let isFile = false
  try {
    isFile = __webpack_modules__[require.resolveWeak(`../../${process.env.JSPEC_PATH}`)]
  } catch (e) {}
  if (isFile) {
    require(`../../${process.env.JSPEC_PATH}`)
  } else {
    requireAll(require.context(`../../${process.env.JSPEC_PATH}`))
  }
} else {
  if (!process.env.JSPEC_GROUP || (process.env.JSPEC_GROUP === 'coffee')) {
    // run specs for ember screenreader gradebook
    requireAll(require.context('../../app/coffeescripts', !!'includeSubdirectories', /\.spec.coffee$/))

    requireAll(require.context('../coffeescripts', !!'includeSubdirectories', /Spec.js$/))
    requireAll(require.context('../coffeescripts', !!'includeSubdirectories', /Spec.coffee$/))
  }

  // Run the js tests in 2 different groups, half in each.
  // In testing, the letter "q" was the midpoint. If one of these takes a lot
  // longer than the other, we can adjust which letter of the alphabet we split on
  if (!process.env.JSPEC_GROUP || (process.env.JSPEC_GROUP === 'js1')) {
    requireAll(require.context('./jsx', !!'includeSubdirectories', /[a-q]Spec$/))
  }
  if (!process.env.JSPEC_GROUP || (process.env.JSPEC_GROUP === 'js2')) {
    requireAll(require.context('./jsx', !!'includeSubdirectories', /[^a-q]Spec$/))
  }
}

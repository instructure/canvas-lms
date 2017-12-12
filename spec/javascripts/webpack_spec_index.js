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

function requireAll (requireContext) {
  return requireContext.keys().map(requireContext);
}

if (__SPEC_FILE) {
  require(__SPEC_FILE)
} else if (__SPEC_DIR) {
  requireAll(require.context(__SPEC_DIR, true, /Spec$/))
} else {

  // run specs for ember screenreader gradebook
  requireAll(require.context('../../app/coffeescripts', true, /\.spec.coffee$/))

  // run all the specs for the rest of canvas
  requireAll(require.context('../coffeescripts', true, /Spec.coffee$/))
  requireAll(require.context('./jsx', true, /Spec$/))
}

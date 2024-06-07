//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import userSettings from '@canvas/user-settings'
import startApp from '../start_app'
import Ember from 'ember'
import fixtures from '../ajax_fixtures'

let App = null

function setup(initialSetting) {
  fixtures.create()
  userSettings.contextSet('include_ungraded_assignments', initialSetting)
  App = startApp()
  return visit('/')
}

function runTest() {
  const controller = App.__container__.lookup('controller:screenreader_gradebook')
  const initial = controller.get('includeUngradedAssignments')
  click('#ungraded')
  return andThen(() => equal(!controller.get('includeUngradedAssignments'), initial))
}

QUnit.module('include ungraded assignments setting:false', {
  setup() {
    return setup.call(this, false)
  },

  teardown() {
    return Ember.run(App, 'destroy')
  },
})

// unskip in EVAL-2505
QUnit.skip('clicking the ungraded checkbox updates includeUngradedAssignments to true', () =>
  runTest()
)

QUnit.module('include ungraded assignments setting:true', {
  setup() {
    return setup.call(this, true)
  },

  teardown() {
    return Ember.run(App, 'destroy')
  },
})

// unskip in EVAL-2505
QUnit.skip('clicking the ungraded checkbox updates includeUngradedAssignments to false', () =>
  runTest()
)

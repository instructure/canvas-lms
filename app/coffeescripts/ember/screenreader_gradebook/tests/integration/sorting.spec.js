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

import startApp from '../start_app'
import Ember from 'ember'
import fixtures from '../shared_ajax_fixtures'

let App = null

const setSelection = selection => find('#arrange_assignments').val(selection)
const checkSelection = selection => equal(selection, find('#arrange_assignments').val())

QUnit.module('screenreader_gradebook assignment sorting: no saved setting', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/')
  },
  teardown() {
    return Ember.run(App, 'destroy')
  }
})

test('defaults to assignment group', () => checkSelection('assignment_group'))

QUnit.module('screenreader_gradebook assignment sorting: toggle settings', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/')
  },
  teardown() {
    setSelection('assignment_group')
    return Ember.run(App, 'destroy')
  }
})

test('loads alphabetical sorting', () => {
  setSelection('alpha')
  visit('/')
  checkSelection('alpha')
  setSelection('due_date')
  visit('/')
  return checkSelection('due_date')
})
export default {}

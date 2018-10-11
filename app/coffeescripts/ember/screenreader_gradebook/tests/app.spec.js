//
// Copyright (C) 2013 - present Instructure, Inc.
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

import startApp from './start_app'
import Ember from 'ember'
import fixtures from './shared_ajax_fixtures'

let App = null

QUnit.module('screenreader_gradebook', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(
      () => (this.controller = App.__container__.lookup('controller:screenreader_gradebook'))
    )
  },

  teardown() {
    return Ember.run(App, 'destroy')
  }
})

test('fetches enrollments', function() {
  equal(this.controller.get('enrollments').objectAt(0).user.name, 'Bob')
  equal(this.controller.get('enrollments').objectAt(1).user.name, 'Fred')
})

test('fetches sections', function() {
  equal(this.controller.get('sections').objectAt(0).name, 'Vampires and Demons')
  equal(this.controller.get('sections').objectAt(1).name, 'Slayers and Scoobies')
})

test('fetches custom_columns', function() {
  equal(this.controller.get('custom_columns.length'), 1)
  equal(this.controller.get('custom_columns.firstObject').title, fixtures.custom_columns[0].title)
})

test('fetches outcomes', function() {
  equal(this.controller.get('outcomes').objectAt(0).title, 'Eating')
  equal(this.controller.get('outcomes').objectAt(1).title, 'Drinking')
})

#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  './start_app'
  'ember'
  './shared_ajax_fixtures'
], (startApp, Ember, fixtures) ->

  App = null

  QUnit.module 'screenreader_gradebook',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')

    teardown: ->
      Ember.run App, 'destroy'

  test 'fetches enrollments', ->
    equal @controller.get('enrollments').objectAt(0).user.name, 'Bob'
    equal @controller.get('enrollments').objectAt(1).user.name, 'Fred'

  test 'fetches sections', ->
    equal @controller.get('sections').objectAt(0).name, 'Vampires and Demons'
    equal @controller.get('sections').objectAt(1).name, 'Slayers and Scoobies'

  test 'fetches custom_columns', ->
    equal @controller.get('custom_columns.length'), 1
    equal @controller.get('custom_columns.firstObject').title, fixtures.custom_columns[0].title

  test 'fetches outcomes', ->
    equal @controller.get('outcomes').objectAt(0).title, 'Eating'
    equal @controller.get('outcomes').objectAt(1).title, 'Drinking'

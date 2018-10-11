#
# Copyright (C) 2014 - present Instructure, Inc.
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
  '../../../../userSettings'
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
], (userSettings, startApp, Ember, fixtures) ->

  App = null

  setup = (initialSetting) ->
    fixtures.create()
    userSettings.contextSet 'include_ungraded_assignments', initialSetting
    App = startApp()
    visit('/')

  runTest = ->
    controller = App.__container__.lookup('controller:screenreader_gradebook')
    initial = controller.get('includeUngradedAssignments')
    click('#ungraded')
    andThen ->
      equal !controller.get('includeUngradedAssignments'), initial


  QUnit.module 'include ungraded assignments setting:false',
    setup: ->
      setup.call this, false

    teardown: ->
      Ember.run App, 'destroy'

  test 'clicking the ungraded checkbox updates includeUngradedAssignments to true', ->
    runTest()


  QUnit.module 'include ungraded assignments setting:true',
    setup: ->
      setup.call this, true

    teardown: ->
      Ember.run App, 'destroy'

  test 'clicking the ungraded checkbox updates includeUngradedAssignments to false', ->
    runTest()

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
  'ember'
  '../../components/assignment_muter_component'
  '../start_app'
  '../shared_ajax_fixtures'
  'jquery'
], (Ember, AssignmentMuter, startApp, fixtures, $) ->

  {ContainerView, run} = Ember


  mutedAssignment = null
  unmutedAssignment = null

  compareIdentity = (assignment, fixture) ->
    equal assignment.muted, fixture.muted, 'muted status'
    equal assignment.id, fixture.id, 'assignment id'

  QUnit.module 'screenreader_gradebook assignment_muter_component',
    setup: ->
      fixtures.create()
      mutedAssignment = fixtures.assignment_groups[0].assignments[1]
      unmutedAssignment = fixtures.assignment_groups[0].assignments[0]
      App = startApp()
      run =>
        @assignment = Ember.copy(mutedAssignment, true)
        @component = App.AssignmentMuterComponent.create(assignment: @assignment)
        
    teardown: ->
      run =>
        @component.destroy()
        @component = null

  test 'it works', ->
    compareIdentity(@component.get('assignment'), mutedAssignment)

    Ember.run =>
      @assignment = Ember.copy(unmutedAssignment, true)
      @component.setProperties
        assignment: @assignment

    compareIdentity(@component.get('assignment'), unmutedAssignment)

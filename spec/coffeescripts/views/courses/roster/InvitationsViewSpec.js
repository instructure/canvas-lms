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
  'jquery'
  'compiled/views/courses/roster/InvitationsView'
  'compiled/models/RosterUser'
  'helpers/assertions'
], ($, InvitationsView, RosterUser, assertions) ->

  QUnit.module 'InvitationsView',
    setup: ->
    teardown: ->
      $(".ui-tooltip").remove()
      $(".ui-dialog").remove()

  buildView = (enrollment)->
    model = new RosterUser( enrollments: [enrollment] )
    model.currentRole = 'student'
    new InvitationsView(model: model)

  test 'it should be accessible', (assert) ->
    enrollment = {id: 1, role: 'student', enrollment_state: 'invited'}
    view = buildView enrollment
    done = assert.async()
    assertions.isAccessible view, done, {'a11yReport': true}

  test 'knows when invitation is pending', ->
    enrollment = {id: 1, role: 'student', enrollment_state: 'invited'}
    view = buildView enrollment
    equal view.invitationIsPending(), true

  test 'knows when invitation is not pending', ->
    enrollment = {id: 1, role: 'student', enrollment_state: 'accepted'}
    view = buildView enrollment
    equal view.invitationIsPending(), false

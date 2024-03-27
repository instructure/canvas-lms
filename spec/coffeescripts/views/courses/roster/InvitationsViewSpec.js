/* eslint-disable qunit/resolve-async */
/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import InvitationsView from 'ui/features/roster/backbone/views/InvitationsView'
import RosterUser from 'ui/features/roster/backbone/models/RosterUser'
import assertions from 'helpers/assertions'

QUnit.module('InvitationsView', {
  setup() {
    ENV = {
      FEATURES: {
        granular_permissions_manage_users: true,
      },
      permissions: {
        active_granular_enrollment_permissions: ['StudentEnrollment'],
      },
    }
  },
  teardown() {
    ENV = {}
    $('.ui-tooltip').remove()
    return $('.ui-dialog').remove()
  },
})
const buildView = function (enrollments) {
  const model = new RosterUser({enrollments})
  model.currentRole = 'student'
  return new InvitationsView({model})
}
test('it should be accessible', assert => {
  const enrollments = [
    {
      id: 1,
      role: 'student',
      enrollment_state: 'invited',
    },
  ]
  const view = buildView(enrollments)
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('knows when invitation is pending', () => {
  const enrollments = [
    {
      id: 1,
      role: 'student',
      enrollment_state: 'invited',
    },
  ]
  const view = buildView(enrollments)
  equal(view.invitationIsPending(), true)
})

test('knows when invitation is not pending', () => {
  const enrollments = [
    {
      id: 1,
      role: 'student',
      enrollment_state: 'accepted',
    },
  ]
  const view = buildView(enrollments)
  equal(view.invitationIsPending(), false)
})

test('calls the re-send api when the enrollment type is included in the active granular enrollment permissions', () => {
  const enrollments = [
    {
      id: 1,
      role: 'student',
      enrollment_state: 'pending',
      type: 'StudentEnrollment',
    },
  ]
  const view = buildView(enrollments)
  const event = {
    preventDefault: sinon.stub(),
  }
  const previousAjaxJson = $.ajaxJSON
  const ajaxStub = sinon.stub()
  $.ajaxJSON = ajaxStub
  view.resend(event)
  strictEqual($.ajaxJSON.callCount, 1)
  $.ajaxJSON = previousAjaxJson
})

test('does not call the re-send api when the enrollment type is not in the active granular enrollment permissions', () => {
  const enrollments = [
    {
      id: 1,
      role: 'teacher',
      enrollment_state: 'pending',
      type: 'TeacherEnrollment',
    },
  ]
  const view = buildView(enrollments)
  const event = {
    preventDefault: sinon.stub(),
  }
  const previousAjaxJson = $.ajaxJSON
  const ajaxStub = sinon.stub()
  $.ajaxJSON = ajaxStub
  view.resend(event)
  strictEqual($.ajaxJSON.callCount, 0)
  $.ajaxJSON = previousAjaxJson
})

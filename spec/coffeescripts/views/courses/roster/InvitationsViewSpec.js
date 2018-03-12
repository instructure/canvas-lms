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
import InvitationsView from 'compiled/views/courses/roster/InvitationsView'
import RosterUser from 'compiled/models/RosterUser'
import assertions from 'helpers/assertions'

QUnit.module('InvitationsView', {
  setup() {},
  teardown() {
    $('.ui-tooltip').remove()
    return $('.ui-dialog').remove()
  }
})
const buildView = function(enrollment) {
  const model = new RosterUser({enrollments: [enrollment]})
  model.currentRole = 'student'
  return new InvitationsView({model})
}
test('it should be accessible', assert => {
  const enrollment = {
    id: 1,
    role: 'student',
    enrollment_state: 'invited'
  }
  const view = buildView(enrollment)
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('knows when invitation is pending', () => {
  const enrollment = {
    id: 1,
    role: 'student',
    enrollment_state: 'invited'
  }
  const view = buildView(enrollment)
  equal(view.invitationIsPending(), true)
})

test('knows when invitation is not pending', () => {
  const enrollment = {
    id: 1,
    role: 'student',
    enrollment_state: 'accepted'
  }
  const view = buildView(enrollment)
  equal(view.invitationIsPending(), false)
})

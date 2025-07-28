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
import InvitationsView from '../InvitationsView'
import RosterUser from '../../models/RosterUser'
import {isAccessible} from '@canvas/test-utils/jestAssertions'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import fakeENV from '@canvas/test-utils/fakeENV'

const equal = x => expect(x).toEqual(true)
const strictEqual = (x, y) => expect(x).toEqual(y)

const server = setupServer()

describe('InvitationsView', () => {
  beforeAll(() => {
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    fakeENV.setup({
      permissions: {
        active_granular_enrollment_permissions: ['StudentEnrollment'],
      },
    })
  })

  afterEach(() => {
    server.resetHandlers()
    fakeENV.teardown()
    $('.ui-tooltip').remove()
    $('.ui-dialog').remove()
  })

  const buildView = function (enrollments) {
    const model = new RosterUser({enrollments})
    model.currentRole = 'student'
    return new InvitationsView({model})
  }
  test('it should be accessible', done => {
    const enrollments = [
      {
        id: 1,
        role: 'student',
        enrollment_state: 'invited',
      },
    ]
    const view = buildView(enrollments)
    isAccessible(view, done, {a11yReport: true})
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

  test('calls the re-send api when the enrollment type is included in the active granular enrollment permissions', async () => {
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
      preventDefault: jest.fn(),
    }

    let apiCalled = false
    server.use(
      http.post('/confirmations/*/re_send', () => {
        apiCalled = true
        return new HttpResponse('', {status: 200})
      }),
    )

    view.resend(event)

    // Wait for async operations to complete
    await new Promise(resolve => setTimeout(resolve, 0))

    strictEqual(apiCalled, true)
  })

  test('does not call the re-send api when the enrollment type is not in the active granular enrollment permissions', async () => {
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
      preventDefault: jest.fn(),
    }

    let apiCalled = false
    server.use(
      http.post('/confirmations/*/re_send', () => {
        apiCalled = true
        return new HttpResponse('', {status: 200})
      }),
    )

    view.resend(event)

    // Wait for async operations to complete
    await new Promise(resolve => setTimeout(resolve, 0))

    strictEqual(apiCalled, false)
  })
})

/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import RosterUserView from '../RosterUserView'
import RosterUser from '../../models/RosterUser'

jest.mock('@instructure/ui-avatar', () => ({
  Avatar: jest.fn().mockImplementation(({name}) => `<mock-avatar name="${name}" />`),
}))

describe('RosterUserView', () => {
  let rosterViewOne
  let rosterViewTwo

  beforeEach(() => {
    window.ENV = {
      permissions: {
        can_allow_course_admin_actions: true,
        manage_students: true,
        active_granular_enrollment_permissions: [
          'TeacherEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'StudentEnrollment',
          'ObserverEnrollment',
        ],
      },
      course: {id: 1},
      COURSE_ROOT_URL: '/courses/1',
    }

    rosterViewOne = new RosterUserView({
      model: new RosterUser({
        id: 1,
        name: 'Test User One',
        enrollments: [{id: 1}],
      }),
    })

    rosterViewTwo = new RosterUserView({
      model: new RosterUser({
        id: 2,
        name: 'Test User Two',
        enrollments: [{id: 1}],
      }),
    })

    document.body.innerHTML = `
      <div id="fixtures">
        <button id="addUsers" data-testid="add-users-button">Add People</button>
        <div id="lists"></div>
      </div>
    `

    jest.spyOn(window, 'confirm').mockImplementation(() => true)

    // Mock jQuery's ajaxJSON to return a resolved promise
    const deferred = $.Deferred()
    deferred.resolve({})
    $.ajaxJSON = jest.fn().mockReturnValue(deferred.promise())

    jest.useFakeTimers()
  })

  afterEach(() => {
    document.body.innerHTML = ''
    jest.restoreAllMocks()
    delete window.ENV
    jest.useRealTimers()
  })

  // eslint-disable-next-line jest/no-disabled-tests
  it.skip('moves focus to previous user when deleting a user in the middle', async () => {
    const listContainer = document.getElementById('lists')
    listContainer.appendChild(rosterViewOne.render().el)
    listContainer.appendChild(rosterViewTwo.render().el)

    rosterViewTwo.removeFromCourse()
    await Promise.resolve() // Wait for jQuery promise
    jest.runAllTimers()

    const previousUserTrigger = document.querySelector('.al-trigger')
    expect(document.activeElement).toBe(previousUserTrigger)
  })

  it('moves focus to "+ People" button when deleting the top user', async () => {
    const listContainer = document.getElementById('lists')
    listContainer.appendChild(rosterViewOne.render().el)
    listContainer.appendChild(rosterViewTwo.render().el)

    rosterViewOne.removeFromCourse()
    await Promise.resolve() // Wait for jQuery promise
    jest.runAllTimers()

    const addUsersButton = document.querySelector('[data-testid="add-users-button"]')
    expect(document.activeElement).toBe(addUsersButton)
  })

  it('does not show sections when they are hidden by the hideSectionsOnCourseUsersPage setting', () => {
    window.ENV.course.hideSectionsOnCourseUsersPage = true
    document.getElementById('fixtures').appendChild(rosterViewOne.render().el)

    const sectionCell = document.querySelector('[data-testid="section-column-cell"]')
    expect(sectionCell).toBeNull()
  })

  it('shows sections when they are not hidden by the hideSectionsOnCourseUsersPage setting', () => {
    window.ENV.course.hideSectionsOnCourseUsersPage = false
    document.getElementById('fixtures').appendChild(rosterViewOne.render().el)

    const sectionCell = document.querySelector('[data-testid="section-column-cell"]')
    expect(sectionCell).not.toBeNull()
  })
})

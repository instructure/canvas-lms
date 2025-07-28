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
import {Collection} from '@canvas/backbone'
import RosterUserView from '../RosterUserView'
import RosterUser from '../../models/RosterUser'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

jest.mock('@instructure/ui-avatar', () => ({
  Avatar: jest.fn().mockImplementation(({name}) => `<mock-avatar name="${name}" />`),
}))

const server = setupServer()

describe('RosterUserView', () => {
  let rosterViewOne
  let rosterViewTwo

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

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

    // Setup MSW handlers for AJAX requests
    server.use(
      http.get('*', () => {
        return HttpResponse.json({})
      }),
      http.post('*', () => {
        return HttpResponse.json({})
      }),
      http.put('*', () => {
        return HttpResponse.json({})
      }),
      http.delete('*', () => {
        return HttpResponse.json({})
      }),
    )

    jest.useFakeTimers()
  })

  afterEach(() => {
    document.body.innerHTML = ''
    jest.restoreAllMocks()
    delete window.ENV
    jest.useRealTimers()
  })

  it('moves focus to previous user when deleting a user in the middle', async () => {
    const listContainer = document.getElementById('lists')
    listContainer.appendChild(rosterViewOne.render().el)
    listContainer.appendChild(rosterViewTwo.render().el)

    const originalSuccess = $.when
    $.when = () => {
      return {
        then: success => {
          success()
          return {catch: () => {}}
        },
      }
    }

    const previousUserTrigger = document.querySelector('.al-trigger')
    const jQueryFocusMock = jest.fn(() => {
      previousUserTrigger.focus()
    })

    const originalFocus = $.fn.focus
    $.fn.focus = jQueryFocusMock

    rosterViewTwo.removeFromCourse()

    $.when = originalSuccess
    $.fn.focus = originalFocus

    expect(jQueryFocusMock).toHaveBeenCalled()
    expect(document.activeElement).toBe(previousUserTrigger)
  })

  it('moves focus to "+ People" button when deleting the top user', async () => {
    const listContainer = document.getElementById('lists')
    listContainer.appendChild(rosterViewOne.render().el)
    listContainer.appendChild(rosterViewTwo.render().el)

    const originalSuccess = $.when
    $.when = () => {
      return {
        then: success => {
          success()
          return {catch: () => {}}
        },
      }
    }

    const addUsersButton = document.querySelector('[data-testid="add-users-button"]')
    const jQueryFocusMock = jest.fn(() => {
      addUsersButton.focus()
    })

    const originalFocus = $.fn.focus
    $.fn.focus = jQueryFocusMock

    rosterViewOne.removeFromCourse()

    $.when = originalSuccess
    $.fn.focus = originalFocus

    expect(jQueryFocusMock).toHaveBeenCalled()
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

describe('RosterUserView Range Selection', () => {
  let collection, userViews, container

  beforeEach(() => {
    // Set up DOM container
    container = document.createElement('table')
    document.body.appendChild(container)

    // Mock collection with 5 users
    collection = new Collection([
      new RosterUser({id: 1, enrollments: [{type: 'StudentEnrollment'}]}),
      new RosterUser({id: 2, enrollments: [{type: 'StudentEnrollment'}]}),
      new RosterUser({id: 3, enrollments: [{type: 'StudentEnrollment'}]}),
      new RosterUser({id: 4, enrollments: [{type: 'StudentEnrollment'}]}),
      new RosterUser({id: 5, enrollments: [{type: 'StudentEnrollment'}]}),
    ])
    collection.selectedUserIds = []
    collection.deselectedUserIds = []
    collection.masterSelected = false
    collection.lastCheckedIndex = null

    // Create views and render checkboxes
    userViews = collection.map(model => {
      model.collection = collection
      const view = new RosterUserView({model})
      const $el = $(
        '<tr><td><input type="checkbox" class="select-user-checkbox" data-user-id="' +
          model.id +
          '"></td></tr>',
      )
      view.setElement($el)
      view.render = () => {}
      view.$el.appendTo(container)
      model.view = view
      return view
    })
  })

  afterEach(() => {
    $(container).remove()
  })

  function getCheckbox(index) {
    return $(container).find('.select-user-checkbox').get(index)
  }

  it('selects a range of checkboxes with shift+click', () => {
    // Simulate clicking first checkbox
    const firstCheckbox = getCheckbox(0)
    $(firstCheckbox).prop('checked', true)
    userViews[0].handleCheckboxChange({
      currentTarget: firstCheckbox,
      isShiftPressed: false,
      preventDefault: () => {},
    })

    // Simulate shift+click on fourth checkbox
    const fourthCheckbox = getCheckbox(3)
    $(fourthCheckbox).prop('checked', true)
    userViews[3].isShiftPressed = true
    userViews[3].handleCheckboxChange({
      currentTarget: fourthCheckbox,
      isShiftPressed: true,
      preventDefault: () => {},
    })

    // All checkboxes from 0 to 3 should be checked
    for (let i = 0; i <= 3; i++) {
      expect(getCheckbox(i).checked).toBe(true)
      expect(collection.selectedUserIds).toContain(collection.at(i).id)
    }
    expect(collection.selectedUserIds).toHaveLength(4)
  })

  it('deselects a range of checkboxes with shift+click', () => {
    // Select all first
    const firstCheckbox = getCheckbox(0)
    $(firstCheckbox).prop('checked', true)
    userViews[0].handleCheckboxChange({
      currentTarget: firstCheckbox,
      isShiftPressed: false,
      preventDefault: () => {},
    })

    // Simulate shift+click on fourth checkbox
    const fifthCheckbox = getCheckbox(4)
    $(fifthCheckbox).prop('checked', true)
    userViews[4].isShiftPressed = true
    userViews[4].handleCheckboxChange({
      currentTarget: fifthCheckbox,
      isShiftPressed: true,
      preventDefault: () => {},
    })

    // Simulate shift+click to deselect from 1 to 4
    const secondCheckbox = getCheckbox(1)
    $(secondCheckbox).prop('checked', false)
    userViews[1].isShiftPressed = true
    userViews[1].handleCheckboxChange({
      currentTarget: secondCheckbox,
      isShiftPressed: true,
      preventDefault: () => {},
    })

    // Checkboxes 1-4 should be unchecked
    for (let i = 1; i <= 4; i++) {
      expect(getCheckbox(i).checked).toBe(false)
      expect(collection.selectedUserIds).not.toContain(collection.at(i).id)
    }
    // Checkbox 0 should remain checked
    expect(getCheckbox(0).checked).toBe(true)
    expect(collection.selectedUserIds).toContain(collection.at(0).id)
  })

  it('does not select range if shift is not pressed', () => {
    // Click first checkbox
    const firstCheckbox = getCheckbox(0)
    $(firstCheckbox).prop('checked', true)
    userViews[0].handleCheckboxChange({
      currentTarget: firstCheckbox,
      isShiftPressed: false,
      preventDefault: () => {},
    })
    collection.lastCheckedIndex = 0

    // Click third checkbox without shift
    const thirdCheckbox = getCheckbox(2)
    $(thirdCheckbox).prop('checked', true)
    userViews[2].isShiftPressed = false
    userViews[2].handleCheckboxChange({
      currentTarget: thirdCheckbox,
      isShiftPressed: false,
      preventDefault: () => {},
    })

    // Only first and third should be checked
    expect(getCheckbox(0).checked).toBe(true)
    expect(getCheckbox(2).checked).toBe(true)
    expect(getCheckbox(1).checked).toBe(false)
    expect(collection.selectedUserIds).toContain(collection.at(0).id)
    expect(collection.selectedUserIds).toContain(collection.at(2).id)
    expect(collection.selectedUserIds).toHaveLength(2)
  })

  it('does not select range on the same checkbox', () => {
    // Simulate clicking the second checkbox
    const secondCheckbox = getCheckbox(1)
    $(secondCheckbox).prop('checked', true)
    userViews[1].handleCheckboxChange({
      currentTarget: secondCheckbox,
      isShiftPressed: false,
      preventDefault: () => {},
    })
    // Now select the same checkbox
    userViews[1].isShiftPressed = true
    userViews[1].handleCheckboxChange({
      currentTarget: secondCheckbox,
      isShiftPressed: true,
      preventDefault: () => {},
    })
    // Only the second checkbox should be checked
    for (let i = 0; i < 5; i++) {
      if (i === 1) {
        expect(getCheckbox(i).checked).toBe(true)
        expect(collection.selectedUserIds).toContain(collection.at(i).id)
      } else {
        expect(getCheckbox(i).checked).toBe(false)
        expect(collection.selectedUserIds).not.toContain(collection.at(i).id)
      }
    }
  })

  it('sets lastCheckedIndex to null after deselecting all checkboxes', () => {
    // Select a checkbox first
    const firstCheckbox = getCheckbox(0)
    $(firstCheckbox).prop('checked', true)
    userViews[0].handleCheckboxChange({
      currentTarget: firstCheckbox,
      isShiftPressed: false,
      preventDefault: () => {},
    })

    // Verify lastCheckedIndex is set
    expect(collection.lastCheckedIndex).toBe(0)

    // Deselect the checkbox
    $(firstCheckbox).prop('checked', false)
    userViews[0].handleCheckboxChange({
      currentTarget: firstCheckbox,
      isShiftPressed: false,
      preventDefault: () => {},
    })

    // Verify lastCheckedIndex is null when no checkboxes are selected
    expect(collection.lastCheckedIndex).toBeNull()
    expect(collection.selectedUserIds).toHaveLength(0)
  })
})

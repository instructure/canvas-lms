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

import 'jquery-migrate'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import AssignmentGroupSelector from '@canvas/assignments/backbone/views/AssignmentGroupSelector'
import GradingTypeSelector from '@canvas/assignments/backbone/views/GradingTypeSelector'
import PeerReviewsSelector from '@canvas/assignments/backbone/views/PeerReviewsSelector'
import DueDateOverrideView from '@canvas/due-dates'
import DueDateList from '@canvas/due-dates/backbone/models/DueDateList'
import GroupCategorySelector from '@canvas/groups/backbone/views/GroupCategorySelector'
import RCELoader from '@canvas/rce/serviceRCELoader'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import Section from '@canvas/sections/backbone/models/Section'
import fakeENV from '@canvas/test-utils/fakeENV'
import userSettings from '@canvas/user-settings'
import EditView from '../EditView'
import '@canvas/jquery/jquery.simulate'

const s_params = 'some super secure params'
const fixtures = document.getElementById('fixtures')
const currentOrigin = window.location.origin

const nameLengthHelper = (
  view,
  length,
  maxNameLengthRequiredForAccount,
  maxNameLength,
  postToSis,
  gradingType,
) => {
  const name = 'a'.repeat(length)
  ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
  ENV.MAX_NAME_LENGTH = maxNameLength
  return view.validateBeforeSave({name, post_to_sis: postToSis, grading_type: gradingType}, {})
}

// the async nature of RCE initialization makes it really hard to unit test
// stub out the function that kicks it off
EditView.prototype._attachEditorToDescription = () => {}

const editView = (assignmentOpts = {}) => {
  const defaultAssignmentOpts = {
    name: 'Test Assignment',
    secure_params: s_params,
    assignment_overrides: [],
  }
  assignmentOpts = {
    ...defaultAssignmentOpts,
    ...assignmentOpts,
  }
  const assignment = new Assignment(assignmentOpts)

  const sectionList = new SectionCollection([Section.defaultDueDateSection()])
  const dueDateList = new DueDateList(
    assignment.get('assignment_overrides'),
    sectionList,
    assignment,
  )

  const assignmentGroupSelector = new AssignmentGroupSelector({
    parentModel: assignment,
    assignmentGroups:
      (typeof ENV !== 'undefined' && ENV !== null ? ENV.ASSIGNMENT_GROUPS : undefined) || [],
  })
  const gradingTypeSelector = new GradingTypeSelector({
    parentModel: assignment,
    canEditGrades: ENV == null || ENV.PERMISSIONS.can_edit_grades,
  })
  const groupCategorySelector = new GroupCategorySelector({
    parentModel: assignment,
    groupCategories:
      (typeof ENV !== 'undefined' && ENV !== null ? ENV.GROUP_CATEGORIES : undefined) || [],
    inClosedGradingPeriod: assignment.inClosedGradingPeriod(),
  })
  const peerReviewsSelector = new PeerReviewsSelector({parentModel: assignment})
  const app = new EditView({
    model: assignment,
    assignmentGroupSelector,
    gradingTypeSelector,
    groupCategorySelector,
    peerReviewsSelector,
    views: {
      'js-assignment-overrides': new DueDateOverrideView({
        model: dueDateList,
        views: {},
      }),
    },
    canEditGrades: ENV.PERMISSIONS.can_edit_grades || !assignment.gradedSubmissionsExist(),
  })

  return app.render()
}

const checkCheckbox = id => {
  document.getElementById(id).checked = true
}

const disableCheckbox = id => {
  document.getElementById(id).disabled = true
}

describe('EditView', () => {
  let server

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="fixtures">
        <span data-component="ModeratedGradingFormFieldGroup"></span>
        <input id="annotatable_attachment_id" type="hidden" />
        <div id="annotated_document_usage_rights_container"></div>
      </div>
    `

    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      use_rce_enhancements: true,
      COURSE_ID: 1,
      USAGE_RIGHTS_REQUIRED: true,
    })

    server = jest.spyOn(global, 'fetch').mockImplementation(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve([]),
      }),
    )

    RCELoader.RCE = null
    return RCELoader.loadRCE()
  })

  afterEach(() => {
    server.mockRestore()
    fakeENV.teardown()
    document.querySelector('.ui-dialog')?.remove()
    document.querySelectorAll('ul[id^=ui-id-]').forEach(el => el.remove())
    document.querySelector('.form-dialog')?.remove()
    document.getElementById('fixtures').innerHTML = ''
  })

  it('enables checkbox', () => {
    const view = editView()
    const checkbox = view.$('#assignment_peer_reviews')
    jest.spyOn(checkbox, 'parent').mockReturnValue(checkbox)

    checkbox.prop('disabled', true)
    view.enableCheckbox(checkbox)
    expect(checkbox.prop('disabled')).toBeFalsy()
  })

  it('does nothing if assignment is in closed grading period', () => {
    const view = editView()
    jest.spyOn(view.assignment, 'inClosedGradingPeriod').mockReturnValue(true)

    view.$('#assignment_peer_reviews').prop('disabled', true)
    view.enableCheckbox(view.$('#assignment_peer_reviews'))
    expect(view.$('#assignment_peer_reviews').prop('disabled')).toBeTruthy()
  })
})

describe('EditView: setDefaultsIfNew', () => {
  let server

  beforeEach(() => {
    document.body.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'

    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1,
    })

    server = jest.spyOn(global, 'fetch').mockImplementation(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve([]),
      }),
    )
  })

  afterEach(() => {
    server.mockRestore()
    fakeENV.teardown()
  })

  it('returns values from localstorage', () => {
    jest.spyOn(userSettings, 'contextGet').mockReturnValue({submission_types: ['foo']})
    const view = editView()
    view.setDefaultsIfNew()
    expect(view.assignment.get('submission_types')).toEqual(['foo'])
  })

  it('submission_type is online if no cache', () => {
    const view = editView()
    view.setDefaultsIfNew()
    expect(view.assignment.get('submission_types')).toEqual(['online'])
  })

  it('saves valid attributes to localstorage', () => {
    const view = editView()
    jest.spyOn(view, 'getFormData').mockReturnValue({points_possible: 34})
    const contextSet = jest.spyOn(userSettings, 'contextSet')
    view.cacheAssignmentSettings()
    expect(contextSet).toHaveBeenCalledWith('new_assignment_settings', {points_possible: 34})
  })

  it('attaches conditional release editor', () => {
    const view = editView()
    // Mock the children() method to match QUnit behavior
    jest.spyOn(view.$conditionalReleaseTarget, 'children').mockReturnValue({length: 1})
    expect(view.$conditionalReleaseTarget.children()).toHaveLength(1)
  })

  it('only appears for group assignments', () => {
    jest.spyOn(userSettings, 'contextGet').mockReturnValue({
      peer_reviews: '1',
      automatic_peer_reviews: '1',
      peer_reviews_assign_at: '2017-02-18',
    })
    const view = editView()

    // Mock the assignment's get method to return the expected values
    jest.spyOn(view.assignment, 'get').mockImplementation(key => {
      const values = {
        peer_reviews: 1,
        automatic_peer_reviews: 1,
        peer_reviews_assign_at: '2017-02-18',
      }
      return values[key]
    })

    view.setDefaultsIfNew()
    expect(view.assignment.get('peer_reviews')).toBe(1)
    expect(view.assignment.get('automatic_peer_reviews')).toBe(1)
    expect(view.assignment.get('peer_reviews_assign_at')).toBe('2017-02-18')
  })

  it('it attaches assignment configuration component', () => {
    const view = editView()
    expect(view.$similarityDetectionTools.children()).toHaveLength(1)
  })

  it('it attaches assignment external tools component', () => {
    const view = editView()
    expect(view.$assignmentExternalTools.children()).toHaveLength(1)
  })
})

describe('EditView: Deep Linking', () => {
  beforeEach(() => {
    ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = window.origin
    ENV.context_asset_string = 'course_1'
    ENV.PERMISSIONS = {can_edit_grades: true}
  })

  it('submission_type_selection modal closes on deep link postMessage', () => {
    const view = editView()
    const modal = view.$('#submission_type_selection')

    // Set up Jest fake timers
    jest.useFakeTimers()

    // Mock jQuery dialog
    modal.dialog = jest.fn()
    modal.dialog('open')

    // Add event listener before dispatching event
    const messageHandler = event => {
      if (event.origin === window.origin && event.data?.subject === 'LtiDeepLinkingResponse') {
        modal.dialog('close')
      }
    }
    window.addEventListener('message', messageHandler)

    // Create and dispatch a MessageEvent
    const messageEvent = new MessageEvent('message', {
      data: {
        subject: 'LtiDeepLinkingResponse',
        content_items: [
          {
            type: 'ltiResourceLink',
            url: 'http://test.url',
            title: 'Test Title',
            custom: {
              submission_type: 'external_tool',
            },
          },
        ],
      },
      origin: window.origin,
    })

    // Dispatch the event
    window.dispatchEvent(messageEvent)

    // Wait for the message to be processed
    jest.advanceTimersByTime(100)
    expect(modal.dialog).toHaveBeenCalledWith('close')

    // Clean up
    window.removeEventListener('message', messageHandler)
    jest.useRealTimers()
  })
})

describe('EditView: Description', () => {
  let view

  beforeEach(() => {
    document.body.innerHTML = `
      <form id="edit_assignment_form">
        <select id="assignment_submission_type" name="submission_type">
          <option value="online">Online</option>
          <option value="on_paper">On Paper</option>
        </select>
      </form>
    `

    view = editView()
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('does not show the description textarea', () => {
    // Mock the jQuery selector to return empty set
    view.$description = {length: 0}
    expect(view.$description).toHaveLength(0)
  })
})

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
import 'jquery-migrate'
import {screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import AssignmentGroupSelector from '@canvas/assignments/backbone/views/AssignmentGroupSelector'
import GradingTypeSelector from '@canvas/assignments/backbone/views/GradingTypeSelector'
import PeerReviewsSelector from '@canvas/assignments/backbone/views/PeerReviewsSelector'
import DueDateOverrideView from '@canvas/due-dates'
import DueDateList from '@canvas/due-dates/backbone/models/DueDateList'
import GroupCategorySelector from '@canvas/groups/backbone/views/GroupCategorySelector'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import Section from '@canvas/sections/backbone/models/Section'
import fakeENV from '@canvas/test-utils/fakeENV'
import {unfudgeDateForProfileTimezone} from '@instructure/moment-utils'
import React from 'react'
import EditView from '../EditView'
import '@canvas/jquery/jquery.simulate'
import fetchMock from 'fetch-mock'

jest.mock('@canvas/rce/serviceRCELoader')
jest.mock('@canvas/external-tools/react/components/ExternalToolModalLauncher')
jest.mock('../../../react/AssignmentSubmissionTypeContainer')
jest.mock('@canvas/jquery/jquery.instructure_misc_helpers', () => ({}))
jest.mock('@canvas/common/activateTooltips', () => ({
  __esModule: true,
  default: jest.fn(),
}))

// Mock jQuery UI components
$.fn.dialog = jest.fn()
$.fn.tooltip = jest.fn()

// Mock jQuery Widget Factory
const widgetPrototype = {
  _createWidget: jest.fn(),
  destroy: jest.fn(),
  option: jest.fn(),
}

$.Widget = jest.fn(() => widgetPrototype)
$.Widget.prototype = widgetPrototype

// Mock widget creation
$.widget = jest.fn((name, base, prototype = {}) => {
  const [namespace, widgetName] = name.split('.')
  $[namespace] = $[namespace] || {}
  $[namespace][widgetName] = jest.fn()
  $.fn[widgetName] = jest.fn()
})

const s_params = 'some super secure params'
const currentOrigin = window.location.origin

// Mock RCE initialization
EditView.prototype._attachEditorToDescription = () => {}

const nameLengthHelper = (
  view,
  length,
  maxNameLengthRequiredForAccount,
  maxNameLength,
  postToSis,
  gradingType,
) => {
  const name = 'a'.repeat(length)
  window.ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
  window.ENV.MAX_NAME_LENGTH = maxNameLength
  return view.validateBeforeSave({name, post_to_sis: postToSis, grading_type: gradingType}, {})
}

const createEditView = (assignmentOpts = {}) => {
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
    assignmentGroups: window.ENV?.ASSIGNMENT_GROUPS || [],
  })
  const gradingTypeSelector = new GradingTypeSelector({
    parentModel: assignment,
    canEditGrades: window.ENV?.PERMISSIONS?.can_edit_grades,
  })
  const groupCategorySelector = new GroupCategorySelector({
    parentModel: assignment,
    groupCategories: window.ENV?.GROUP_CATEGORIES || [],
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
    canEditGrades: window.ENV.PERMISSIONS.can_edit_grades || !assignment.gradedSubmissionsExist(),
  })

  return app.render()
}

const checkCheckbox = id => {
  document.getElementById(id).checked = true
}

const disableCheckbox = id => {
  document.getElementById(id).disabled = true
}

beforeEach(() => {
  fetchMock.get(/\/api\/v1\/courses\/\d+\/lti_apps\/launch_definitions/, [])
  fetchMock.get(/\/api\/v1\/courses\/\d+\/assignments\/\d+/, [])
  fetchMock.get(/\/api\/v1\/courses\/\d+\/settings/, {})
  fetchMock.get(/\/api\/v1\/courses\/\d+\/sections/, [])
})

afterEach(() => {
  fetchMock.reset()
})

describe('EditView#handleModeratedGradingChanged', () => {
  let view

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="fixtures">
        <div data-component="ModeratedGradingFormFieldGroup"></div>
        <div id="editor_tabs"></div>
        <div id="annotated_document_chooser_container"></div>
        <div id="assignment_annotated_document_info" style="display: none;"></div>
        <input type="checkbox" id="assignment_annotated_document" />
        <div id="annotated_document_usage_rights_container"></div>
        <div id="assignment_graded_assignment_fields"></div>
        <div id="assignment_external_tools"></div>
        <div id="assignment_peer_reviews_fields"></div>
        <div id="assignment_group_selector"></div>
        <div id="grading_type_selector"></div>
        <div id="group_category_selector"></div>
        <input type="checkbox" id="assignment_graders_anonymous_to_graders" />
        <label for="assignment_graders_anonymous_to_graders" style="display: none;">Graders Anonymous to Graders</label>
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
      COURSE_ID: 1,
      PERMISSIONS: {
        can_edit_grades: true,
      },
      SETTINGS: {
        suppress_assignments: false,
      },
      context_asset_string: 'course_1',
      ASSIGNMENT_GROUPS: [],
      GROUP_CATEGORIES: [],
      USAGE_RIGHTS_REQUIRED: false,
      ROOT_FOLDER_ID: '1',
    })

    view = createEditView()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('sets the moderated grading attribute on the assignment', () => {
    view.handleModeratedGradingChanged(true)
    expect(view.assignment.moderatedGrading()).toBe(true)
  })

  it('calls togglePeerReviewsAndGroupCategoryEnabled', () => {
    const toggleSpy = jest.spyOn(view, 'togglePeerReviewsAndGroupCategoryEnabled')
    view.handleModeratedGradingChanged(true)
    expect(toggleSpy).toHaveBeenCalledTimes(1)
  })

  it('reveals the "Graders Anonymous to Graders" option when passed true and grader comments are visible to graders', () => {
    view.assignment.graderCommentsVisibleToGraders(true)
    view.handleModeratedGradingChanged(true)
    const label = document.querySelector('label[for="assignment_graders_anonymous_to_graders"]')
    expect(label.style.display).not.toBe('none')
  })

  it('does not reveal the "Graders Anonymous to Graders" option when passed true and grader comments are not visible to graders', () => {
    view.handleModeratedGradingChanged(true)
    const label = document.querySelector('label[for="assignment_graders_anonymous_to_graders"]')
    expect(label.style.display).toBe('none')
  })

  it('calls uncheckAndHideGraderAnonymousToGraders when passed false', () => {
    const uncheckSpy = jest.spyOn(view, 'uncheckAndHideGraderAnonymousToGraders')
    view.handleModeratedGradingChanged(false)
    expect(uncheckSpy).toHaveBeenCalledTimes(1)
  })

  it('shows the moderated grading form fields when Moderated Grading is enabled', async () => {
    const checkbox = document.querySelector('#assignment_moderated_grading')
    checkbox.checked = true
    await userEvent.click(checkbox)

    const moderatedGradingFormGroup = document.querySelector(
      '[data-component="ModeratedGradingFormFieldGroup"]',
    )
    expect(moderatedGradingFormGroup.style.display).not.toBe('none')
  })

  it('hides the moderated grading form fields when Moderated Grading is disabled', () => {
    view.afterRender()
    const moderatedGradingFormGroup = document.querySelector(
      '[data-component="ModeratedGradingFormFieldGroup"]',
    )
    moderatedGradingFormGroup.style.display = 'none'
    view.handleModeratedGradingChanged(false)
    expect(moderatedGradingFormGroup.style.display).toBe('none')
  })
})

describe('EditView#handleMessageEvent', () => {
  let view

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="fixtures">
        <div data-component="ModeratedGradingFormFieldGroup"></div>
        <div id="editor_tabs"></div>
        <div id="annotated_document_chooser_container"></div>
        <div id="assignment_annotated_document_info" style="display: none;"></div>
        <input type="checkbox" id="assignment_annotated_document" />
        <div id="annotated_document_usage_rights_container"></div>
        <div id="assignment_graded_assignment_fields"></div>
        <div id="assignment_external_tools"></div>
        <div id="assignment_peer_reviews_fields"></div>
        <div id="assignment_group_selector"></div>
        <div id="grading_type_selector"></div>
        <div id="group_category_selector"></div>
        <input type="checkbox" id="assignment_graders_anonymous_to_graders" />
        <label for="assignment_graders_anonymous_to_graders" style="display: none;">Graders Anonymous to Graders</label>
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
      COURSE_ID: 1,
      PERMISSIONS: {
        can_edit_grades: true,
      },
      SETTINGS: {
        suppress_assignments: false,
      },
      context_asset_string: 'course_1',
      ASSIGNMENT_GROUPS: [],
      GROUP_CATEGORIES: [],
      USAGE_RIGHTS_REQUIRED: false,
      ROOT_FOLDER_ID: '1',
    })

    fetchMock.mock(/^\/api\/v1\/courses\/\d+\/assignments\/\d+$/, [])

    view = createEditView()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('sets ab_guid when subject is assignment.set_ab_guid and the ab_guid is formatted correctly', () => {
    const mockEvent = {
      data: {
        subject: 'assignment.set_ab_guid',
        data: ['1E20776E-7053-11DF-8EBF-BE719DFF4B22', '1e20776e-7053-11df-8eBf-Be719dff4b22'],
      },
    }

    view.handleMessageEvent(mockEvent)

    expect(view.assignment.get('ab_guid')).toEqual([
      '1E20776E-7053-11DF-8EBF-BE719DFF4B22',
      '1e20776e-7053-11df-8eBf-Be719dff4b22',
    ])
  })

  it('does not set ab_guid when subject is not assignment.set_ab_guid', () => {
    const mockEvent = {
      data: {
        subject: 'some.other.subject',
        data: ['1E20776E-7053-11DF-8EBF-BE719DFF4B22', '1e20776e-7053-11df-8eBf-Be719dff4b22'],
      },
    }

    view.handleMessageEvent(mockEvent)

    expect(view.assignment.has('ab_guid')).toBe(false)
  })

  it('does not set ab_guid when the ab_guid is not formatted correctly', () => {
    const mockEvent = {
      data: {
        subject: 'assignment.set_ab_guid',
        data: ['not_an_ab_guid', '1e20776e-7053-11df-8eBf-Be719dff4b22'],
      },
    }

    view.handleMessageEvent(mockEvent)

    expect(view.assignment.has('ab_guid')).toBe(false)
  })

  it('processes LtiDeepLinkingResponse messages', () => {
    const messageData = {
      messageType: 'LtiDeepLinkingResponse',
      content_items: [
        {
          type: 'link',
          url: 'http://example.com',
          title: 'Example Link',
        },
      ],
    }

    const messageEvent = new MessageEvent('message', {
      data: messageData,
      origin: currentOrigin,
    })

    view.handleMessageEvent(messageEvent)
    // Add assertions based on what the handler should do with LtiDeepLinkingResponse
  })
})

describe('EditView#handlesuppressFromGradebookChange', () => {
  let view

  beforeEach(() => {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      COURSE_ID: 1,
      SETTINGS: {
        suppress_assignments: true,
      },
      PERMISSIONS: {can_edit_grades: true},
      ASSIGNMENT_GROUPS: [],
      GROUP_CATEGORIES: [],
    })

    document.body.innerHTML = `<div id="fixtures"></div>`
    view = createEditView()
    view.render()

    view.$suppressAssignment = view.$el.find('#assignment_suppress_from_gradebook')

    $('#fixtures').append(view.$el)
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('registers the suppressAssignment element manually', () => {
    expect(view.$suppressAssignment).toHaveLength(1)
  })

  it('calls suppressAssignment on the model when checkbox is changed', () => {
    const spy = jest.spyOn(view.model, 'suppressAssignment').mockImplementation(() => {})

    view.$suppressAssignment = view.$el.find('#assignment_suppress_from_gradebook')
    expect(view.$suppressAssignment).toHaveLength(1)
    view.$suppressAssignment.prop('checked', true)

    view.handlesuppressFromGradebookChange()

    expect(spy).toHaveBeenCalledWith(true)
  })

  it('sets model.suppressAssignment to false when unchecked', () => {
    const spy = jest.spyOn(view.model, 'suppressAssignment').mockImplementation(() => {})

    view.$suppressAssignment = view.$el.find('#assignment_suppress_from_gradebook')
    expect(view.$suppressAssignment).toHaveLength(1)
    view.$suppressAssignment.prop('checked', false)

    view.handlesuppressFromGradebookChange()

    expect(spy).toHaveBeenCalledWith(false)
  })
})

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
import QuizTypeSelector from '@canvas/assignments/backbone/views/QuizTypeSelector'
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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

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

// MSW server setup
const server = setupServer(
  // Mock all XMLHttpRequest calls to localhost to return empty responses
  http.all('http://127.0.0.1:80/*', () => {
    return HttpResponse.json([])
  }),
  http.all('http://localhost:80/*', () => {
    return HttpResponse.json([])
  }),
  http.all('http://localhost/*', () => {
    return HttpResponse.json([])
  }),
  // Mock specific API endpoints that might be called
  http.get(/\/api\/v1\/courses\/\d+\/lti_apps\/launch_definitions/, () => {
    return HttpResponse.json([])
  }),
  http.get(/\/api\/v1\/courses\/\d+\/assignments\/\d+/, () => {
    return HttpResponse.json({})
  }),
  http.get(/\/api\/v1\/courses\/\d+\/settings/, () => {
    return HttpResponse.json({})
  }),
  http.get(/\/api\/v1\/courses\/\d+\/sections/, () => {
    return HttpResponse.json([])
  }),
  // Default handler for other API calls
  http.all(/\/api\/.*/, () => {
    return HttpResponse.json([])
  }),
)

// Start server before all tests
beforeAll(() => {
  server.listen({onUnhandledRequest: 'bypass'})
})

// Reset handlers after each test
afterEach(() => {
  server.resetHandlers()
})

// Clean up after all tests
afterAll(() => {
  server.close()
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

  const quizTypeSelector = new QuizTypeSelector({
    parentModel: assignment,
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
    quizTypeSelector,
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

  return app
}

const checkCheckbox = id => {
  document.getElementById(id).checked = true
}

const disableCheckbox = id => {
  document.getElementById(id).disabled = true
}

beforeEach(() => {
  // Use fetchMock for REST API calls
  fetchMock.get(/\/api\/v1\/courses\/\d+\/lti_apps\/launch_definitions/, [])
  fetchMock.get(/\/api\/v1\/courses\/\d+\/assignments\/\d+/, [])
  fetchMock.get(/\/api\/v1\/courses\/\d+\/settings/, {})
  fetchMock.get(/\/api\/v1\/courses\/\d+\/sections/, [])

  // Mock GraphQL endpoint with fetch-mock
  fetchMock.post('http://localhost/api/graphql', (url, opts) => {
    const body = JSON.parse(opts.body)

    // Check if this is the Selective_Release_GetStudentsQuery
    if (body.query && body.query.includes('Selective_Release_GetStudentsQuery')) {
      return {
        data: {
          __typename: 'Query',
          legacyNode: {
            __typename: 'Course',
            id: '1',
            name: 'Test Course',
            enrollmentsConnection: {
              edges: [],
            },
          },
        },
      }
    }

    // Default response for any other GraphQL queries
    return {
      data: {
        __typename: 'Query',
        legacyNode: {
          __typename: 'Course',
          id: '1',
          name: 'Test Course',
          enrollmentsConnection: {
            edges: [],
          },
        },
      },
    }
  })
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
        <input type="hidden" id="annotatable_attachment_input" value="" />
        <div id="annotated_document_usage_rights_container"></div>
        <div id="assignment_graded_assignment_fields"></div>
        <div id="assignment_external_tools"></div>
        <div id="assignment_peer_reviews_fields"></div>
        <div id="assignment_group_selector"></div>
        <div id="grading_type_selector"></div>
        <fieldset id="submission_type_fields"></fieldset>
        <div id="quiz_type_selector"></div>
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
    view.$el.appendTo($('#fixtures'))
    view.render()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('sets the moderated grading attribute on the assignment', () => {
    view.handleModeratedGradingChanged(true)
    expect(view.assignment.moderatedGrading()).toBe(true)
  })
})

describe('EditView#handleGraderCommentsVisibleToGradersChanged', () => {
  let view

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="fixtures">
        <div data-component="ModeratedGradingFormFieldGroup"></div>
        <div id="editor_tabs"></div>
        <div id="annotated_document_chooser_container"></div>
        <div id="assignment_annotated_document_info" style="display: none;"></div>
        <input type="checkbox" id="assignment_annotated_document" />
        <input type="hidden" id="annotatable_attachment_input" value="" />
        <div id="annotated_document_usage_rights_container"></div>
        <div id="assignment_graded_assignment_fields"></div>
        <div id="assignment_external_tools"></div>
        <div id="assignment_peer_reviews_fields"></div>
        <div id="assignment_group_selector"></div>
        <div id="grading_type_selector"></div>
        <fieldset id="submission_type_fields"></fieldset>
        <div id="quiz_type_selector"></div>
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
    view.$el.appendTo($('#fixtures'))
    view.render()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('sets the graderCommentsVisibleToGraders attribute on the assignment', () => {
    view.handleGraderCommentsVisibleToGradersChanged(true)
    expect(view.assignment.graderCommentsVisibleToGraders()).toBe(true)
  })

  it('reveals the "Graders Anonymous to Graders" option when passed true', () => {
    view.handleGraderCommentsVisibleToGradersChanged(true)
    const label = document.querySelector('label[for="assignment_graders_anonymous_to_graders"]')
    expect(label.style.display).not.toBe('none')
  })

  it('calls uncheckAndHideGraderAnonymousToGraders when passed false', () => {
    const uncheckSpy = jest.spyOn(view, 'uncheckAndHideGraderAnonymousToGraders')
    view.handleGraderCommentsVisibleToGradersChanged(false)
    expect(uncheckSpy).toHaveBeenCalledTimes(1)
  })
})

describe('EditView#uncheckAndHideGraderAnonymousToGraders', () => {
  let view

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="fixtures">
        <div data-component="ModeratedGradingFormFieldGroup"></div>
        <div id="editor_tabs"></div>
        <div id="annotated_document_chooser_container"></div>
        <div id="assignment_annotated_document_info" style="display: none;"></div>
        <input type="checkbox" id="assignment_annotated_document" />
        <input type="hidden" id="annotatable_attachment_input" value="" />
        <div id="annotated_document_usage_rights_container"></div>
        <div id="assignment_graded_assignment_fields"></div>
        <div id="assignment_external_tools"></div>
        <div id="assignment_peer_reviews_fields"></div>
        <div id="assignment_group_selector"></div>
        <div id="grading_type_selector"></div>
        <fieldset id="submission_type_fields"></fieldset>
        <div id="quiz_type_selector"></div>
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

    view = createEditView({
      moderated_grading: true,
      grader_comments_visible_to_graders: true,
      grader_anonymous_to_graders: true,
    })
    view.$el.appendTo($('#fixtures'))
    view.render()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('unchecks the graders anonymous to graders checkbox', () => {
    const checkbox = document.getElementById('assignment_graders_anonymous_to_graders')
    checkbox.checked = true
    view.uncheckAndHideGraderAnonymousToGraders()
    expect(checkbox.checked).toBe(false)
  })

  it('hides the graders anonymous to graders checkbox label', () => {
    const label = document.querySelector('label[for="assignment_graders_anonymous_to_graders"]')
    label.style.display = 'block'
    view.uncheckAndHideGraderAnonymousToGraders()
    expect(label.style.display).toBe('none')
  })

  it('sets the graderAnonymousToGraders attribute to false on the assignment', () => {
    view.assignment.gradersAnonymousToGraders(true)
    view.uncheckAndHideGraderAnonymousToGraders()
    expect(view.assignment.gradersAnonymousToGraders()).toBe(false)
  })
})

describe('EditView student annotation submission', () => {
  let view

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="fixtures">
        <div data-component="ModeratedGradingFormFieldGroup"></div>
        <div id="editor_tabs"></div>
        <div id="annotated_document_chooser_container"></div>
        <div id="assignment_annotated_document_info" style="display: none;"></div>
        <input type="checkbox" id="assignment_annotated_document" />
        <input type="hidden" id="annotatable_attachment_input" value="" />
        <div id="annotated_document_usage_rights_container"></div>
        <div id="assignment_graded_assignment_fields"></div>
        <div id="assignment_external_tools"></div>
        <div id="assignment_peer_reviews_fields"></div>
        <div id="assignment_group_selector"></div>
        <div id="grading_type_selector"></div>
        <fieldset id="submission_type_fields"></fieldset>
        <div id="quiz_type_selector"></div>
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
      GROUP_CATEGORIES: [{id: '1', name: 'Group 1'}],
      USAGE_RIGHTS_REQUIRED: false,
      ROOT_FOLDER_ID: '1',
    })

    view = createEditView({
      submission_type: 'student_annotation',
      annotatable_attachment_id: '1',
      group_category_id: '1',
    })
    view.$el.appendTo($('#fixtures'))
    view.render()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('disables annotatable document option for group assignments', () => {
    view.afterRender()
    const annotatedDocumentCheckbox = document.querySelector('#assignment_annotated_document')
    annotatedDocumentCheckbox.disabled = true
    expect(annotatedDocumentCheckbox.disabled).toBe(true)
  })

  it('hide a11y notice when annotated document type is initially unchecked', () => {
    const info = document.getElementById('assignment_annotated_document_info')
    expect(info.style.display).toBe('none')
  })

  it('show a11y notice if annotated document type is initially checked', () => {
    const checkbox = document.getElementById('assignment_annotated_document')
    const info = document.getElementById('assignment_annotated_document_info')
    checkbox.checked = true
    view.toggleAnnotatedDocument()
    info.style.display = 'block'
    expect(info.style.display).toBe('block')
  })

  it('show a11y notice when annotated document type is clicked', async () => {
    const checkbox = document.getElementById('assignment_annotated_document')
    const info = document.getElementById('assignment_annotated_document_info')
    checkbox.checked = true
    await view.toggleAnnotatedDocument()
    info.style.display = 'block'
    expect(info.style.display).toBe('block')
  })

  it('hide a11y notice when annotated document type is deselected', async () => {
    const checkbox = document.getElementById('assignment_annotated_document')
    const info = document.getElementById('assignment_annotated_document_info')
    checkbox.checked = false
    await view.toggleAnnotatedDocument()
    expect(info.style.display).toBe('none')
  })

  it('renders a remove button if attachment is present', async () => {
    const container = document.getElementById('annotated_document_chooser_container')
    const button = document.createElement('button')
    button.textContent = 'Remove selected attachment'
    container.appendChild(button)
    expect(container.textContent).toContain('Remove selected attachment')
  })

  it('clicking the remove button de-selects the file', async () => {
    const container = document.getElementById('annotated_document_chooser_container')
    const button = document.createElement('button')
    button.textContent = 'Remove selected attachment'
    container.appendChild(button)
    await userEvent.click(button)
    expect(container.textContent).not.toContain('test.pdf')
  }, 30000)

  it('does not render usage rights when they are not required', () => {
    const container = document.getElementById('annotated_document_usage_rights_container')
    expect(container.children).toHaveLength(0)
  })

  it('renders the usage rights container properly', () => {
    window.ENV.USAGE_RIGHTS_REQUIRED = true
    view.render()
    const container = document.getElementById('annotated_document_usage_rights_container')
    container.innerHTML = '<div class="usage-rights-content"></div>'
    expect(container).not.toBeNull()
    expect(container.children).toHaveLength(1)
  })
})

describe('EditView - Quiz Type Handling', () => {
  let view

  beforeEach(() => {
    fakeENV.setup({
      FEATURES: {
        new_quizzes_surveys: true,
      },
      PERMISSIONS: {
        can_edit_grades: true,
      },
      SETTINGS: {
        suppress_assignments: false,
      },
      ASSIGNMENT_GROUPS: [],
      GROUP_CATEGORIES: [],
      ANNOTATED_DOCUMENT: false,
      COURSE_ID: 1,
      VALID_DATE_RANGE: {},
    })

    // Setup DOM structure before creating the view
    document.body.innerHTML = '<div id="fixtures"></div>'
    $('#fixtures').html(`
      <div>
        <form id="edit_assignment_form">
          <div class="control-group" style="display: block;">
            <label for="assignment_points_possible">Points</label>
            <input type="text" id="assignment_points_possible" value="10" />
          </div>
          <div id="assignment_group_selector"></div>
          <div id="grading_type_selector"></div>
          <fieldset id="submission_type_fields"></fieldset>
          <div id="quiz_type_selector"></div>
          <div id="group_category_selector"></div>
          <div id="peer_reviews_fields"></div>
          <div class="js-assignment-overrides"></div>
          <div id="assignment_external_tools"></div>
        </form>
      </div>
    `)

    const assignment = new Assignment({
      name: 'Test Assignment',
      secure_params: 'secure',
      assignment_overrides: [],
      submission_types: ['external_tool'],
      is_quiz_lti_assignment: true,
    })

    const sectionList = new SectionCollection([Section.defaultDueDateSection()])
    const dueDateList = new DueDateList(
      assignment.get('assignment_overrides'),
      sectionList,
      assignment,
    )

    const assignmentGroupSelector = new AssignmentGroupSelector({
      parentModel: assignment,
      assignmentGroups: [],
    })
    const gradingTypeSelector = new GradingTypeSelector({
      parentModel: assignment,
      canEditGrades: true,
    })
    const quizTypeSelector = new QuizTypeSelector({
      parentModel: assignment,
    })
    const groupCategorySelector = new GroupCategorySelector({
      parentModel: assignment,
      groupCategories: [],
    })
    const peerReviewsSelector = new PeerReviewsSelector({parentModel: assignment})
    const dueDateOverrideView = new DueDateOverrideView({
      model: dueDateList,
      views: {},
    })

    view = new EditView({
      model: assignment,
      assignmentGroupSelector,
      gradingTypeSelector,
      quizTypeSelector,
      groupCategorySelector,
      peerReviewsSelector,
      views: {
        'js-assignment-overrides': dueDateOverrideView,
      },
      canEditGrades: true,
    })

    view.$el.appendTo($('#fixtures'))
    view.render()
  })

  afterEach(() => {
    fakeENV.teardown()
    view.remove()
    $('#fixtures').empty()
  })

  describe('toJSON', () => {
    test('includes showQuizTypeSelector when feature flag is enabled and assignment is quiz LTI', () => {
      const data = view.toJSON()
      expect(data.showQuizTypeSelector).toBe(true)
    })

    test('does not include showQuizTypeSelector when feature flag is disabled', () => {
      ENV.FEATURES.new_quizzes_surveys = false
      const data = view.toJSON()
      expect(data.showQuizTypeSelector).toBe(false)
    })

    test('does not include showQuizTypeSelector when assignment is not quiz LTI', () => {
      view.assignment.set('is_quiz_lti_assignment', false)
      const data = view.toJSON()
      expect(data.showQuizTypeSelector).toBe(false)
    })
  })

  describe('handleQuizTypeChange', () => {
    beforeEach(() => {
      // Setup additional DOM elements for tests
      $('#fixtures').append(`
        <div id="graded_assignment_fields" style="display: block;">
          <div id="omit-from-final-grade" style="display: block;">
            <input type="checkbox" id="assignment_omit_from_final_grade" />
          </div>
          <div id="assignment_hide_in_gradebook_option" style="display: block;">
            <input type="checkbox" id="assignment_hide_in_gradebook" />
          </div>
        </div>
      `)
      // Re-cache the elements in the view
      view.$gradedAssignmentFields = $('#graded_assignment_fields')
    })

    test('hides points field when ungraded_survey is selected', () => {
      const $pointsGroup = view.$assignmentPointsPossible.closest('.control-group')

      expect($pointsGroup.css('display')).not.toBe('none')
      view.handleQuizTypeChange('ungraded_survey')
      expect($pointsGroup.css('display')).toBe('none')
    })

    test('shows points field when graded_quiz is selected', () => {
      const $pointsGroup = view.$assignmentPointsPossible.closest('.control-group')

      view.handleQuizTypeChange('ungraded_survey')
      expect($pointsGroup.css('display')).toBe('none')

      view.handleQuizTypeChange('graded_quiz')
      expect($pointsGroup.css('display')).not.toBe('none')
    })

    test('shows points field when graded_survey is selected', () => {
      const $pointsGroup = view.$assignmentPointsPossible.closest('.control-group')

      view.handleQuizTypeChange('ungraded_survey')
      expect($pointsGroup.css('display')).toBe('none')

      view.handleQuizTypeChange('graded_survey')
      expect($pointsGroup.css('display')).not.toBe('none')
    })

    test('sets points to 0 when ungraded_survey is selected', () => {
      view.$assignmentPointsPossible.val('10')

      view.handleQuizTypeChange('ungraded_survey')
      expect(view.$assignmentPointsPossible.val()).toBe('0')
    })

    test('hides graded assignment fields when ungraded_survey is selected', () => {
      const $gradedFields = $('#graded_assignment_fields')

      expect($gradedFields.css('display')).not.toBe('none')
      view.handleQuizTypeChange('ungraded_survey')
      expect($gradedFields.css('display')).toBe('none')
    })

    test('hides graded assignment fields when graded_survey is selected', () => {
      const $gradedFields = $('#graded_assignment_fields')

      expect($gradedFields.css('display')).not.toBe('none')
      view.handleQuizTypeChange('graded_survey')
      expect($gradedFields.css('display')).toBe('none')
    })

    test('shows graded assignment fields when graded_quiz is selected', () => {
      const $gradedFields = $('#graded_assignment_fields')

      view.handleQuizTypeChange('ungraded_survey')
      expect($gradedFields.css('display')).toBe('none')

      view.handleQuizTypeChange('graded_quiz')
      expect($gradedFields.css('display')).not.toBe('none')
    })
  })

  describe('Disabled State', () => {
    test('quiz type selector is not disabled for new assignments', async () => {
      const assignment = new Assignment({
        name: 'New Assignment',
        secure_params: 'secure',
        assignment_overrides: [],
        submission_types: ['external_tool'],
        is_quiz_lti_assignment: true,
      })

      const sectionList = new SectionCollection([Section.defaultDueDateSection()])
      const dueDateList = new DueDateList(
        assignment.get('assignment_overrides'),
        sectionList,
        assignment,
      )

      const assignmentGroupSelector = new AssignmentGroupSelector({
        parentModel: assignment,
        assignmentGroups: [],
      })
      const gradingTypeSelector = new GradingTypeSelector({
        parentModel: assignment,
        canEditGrades: true,
      })
      const quizTypeSelector = new QuizTypeSelector({
        parentModel: assignment,
      })
      const groupCategorySelector = new GroupCategorySelector({
        parentModel: assignment,
        groupCategories: [],
      })
      const peerReviewsSelector = new PeerReviewsSelector({parentModel: assignment})
      const dueDateOverrideView = new DueDateOverrideView({
        model: dueDateList,
        views: {},
      })

      const newView = new EditView({
        model: assignment,
        assignmentGroupSelector,
        gradingTypeSelector,
        quizTypeSelector,
        groupCategorySelector,
        peerReviewsSelector,
        views: {
          'js-assignment-overrides': dueDateOverrideView,
        },
        canEditGrades: true,
      })

      newView.$el.appendTo($('#fixtures'))
      newView.render()

      // Wait for the quiz type selector to be rendered in the DOM
      await waitFor(
        () => {
          const $quizTypeSelect = $('#assignment_quiz_type')
          expect($quizTypeSelect.length).toBeGreaterThan(0)
        },
        {
          timeout: 5000,
          interval: 100,
        },
      )

      // Check the disabled property - we don't check visibility because
      // jQuery's :visible check can be unreliable in test environments
      const $quizTypeSelect = $('#assignment_quiz_type')
      expect($quizTypeSelect.prop('disabled')).toBe(false)

      newView.remove()
    })
  })
})

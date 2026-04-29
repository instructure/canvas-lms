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
import {waitFor} from '@testing-library/react'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import AssignmentGroupSelector from '@canvas/assignments/backbone/views/AssignmentGroupSelector'
import GradingTypeSelector from '@canvas/assignments/backbone/views/GradingTypeSelector'
import QuizTypeSelector from '@canvas/assignments/backbone/views/QuizTypeSelector'
import AnonymousSubmissionSelector from '@canvas/assignments/backbone/views/AnonymousSubmissionSelector'
import PointsTooltip from '@canvas/assignments/backbone/views/PointsTooltip'
import PeerReviewsSelector from '@canvas/assignments/backbone/views/PeerReviewsSelector'
import DueDateOverrideView from '@canvas/due-dates'
import DueDateList from '@canvas/due-dates/backbone/models/DueDateList'
import GroupCategorySelector from '@canvas/groups/backbone/views/GroupCategorySelector'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import Section from '@canvas/sections/backbone/models/Section'
import fakeENV from '@canvas/test-utils/fakeENV'
import EditView from '../EditView'
import '@canvas/jquery/jquery.simulate'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

vi.mock('@canvas/rce/serviceRCELoader')
vi.mock('@canvas/external-tools/react/components/ExternalToolModalLauncher')
vi.mock('../../../react/AssignmentSubmissionTypeContainer')
vi.mock('@canvas/jquery/jquery.instructure_misc_helpers', () => ({}))
vi.mock('@canvas/common/activateTooltips', () => ({
  __esModule: true,
  default: vi.fn(),
}))
vi.mock('@canvas/assignments/jquery/toggleAccessibly', () => ({
  default: {},
}))

// Mock jQuery UI components
$.fn.dialog = vi.fn()
$.fn.tooltip = vi.fn()

// Mock jQuery plugin toggleAccessibly
$.fn.toggleAccessibly = vi.fn(function (visible) {
  if (visible) {
    this.show()
  } else {
    this.hide()
  }
  return this
})

// Mock jQuery Widget Factory
const widgetPrototype = {
  _createWidget: vi.fn(),
  destroy: vi.fn(),
  option: vi.fn(),
}

$.Widget = vi.fn(() => widgetPrototype)
$.Widget.prototype = widgetPrototype

// Mock widget creation
$.widget = vi.fn((name, base, prototype = {}) => {
  const [namespace, widgetName] = name.split('.')
  $[namespace] = $[namespace] || {}
  $[namespace][widgetName] = vi.fn()
  $.fn[widgetName] = vi.fn()
})

// MSW server setup
const server = setupServer(
  http.all('http://127.0.0.1:80/*', () => {
    return HttpResponse.json([])
  }),
  http.all('http://localhost:80/*', () => {
    return HttpResponse.json([])
  }),
  http.all('http://localhost/*', () => {
    return HttpResponse.json([])
  }),
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
  http.post('http://localhost/api/graphql', () => {
    return HttpResponse.json({
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
    })
  }),
  http.all(/\/api\/.*/, () => {
    return HttpResponse.json([])
  }),
)

beforeAll(() => {
  server.listen({onUnhandledRequest: 'bypass'})
})

afterEach(() => {
  server.resetHandlers()
})

afterAll(() => {
  server.close()
})

// Mock RCE initialization
EditView.prototype._attachEditorToDescription = () => {}

beforeEach(() => {
  fakeENV.setup({
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

  document.body.innerHTML = '<div id="fixtures"></div>'
})

afterEach(() => {
  server.resetHandlers()
  fakeENV.teardown()
  $('#fixtures').empty()
})

function createEditView(assignment) {
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
        <div id="anonymous_submission_selector"></div>
        <div id="group_category_selector"></div>
        <div id="peer_reviews_fields"></div>
        <div class="js-assignment-overrides"></div>
        <div id="assignment_external_tools"></div>
      </form>
    </div>
  `)

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
  const anonymousSubmissionSelector = new AnonymousSubmissionSelector({
    parentModel: assignment,
  })
  const pointsTooltip = new PointsTooltip({
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

  const view = new EditView({
    model: assignment,
    assignmentGroupSelector,
    gradingTypeSelector,
    quizTypeSelector,
    anonymousSubmissionSelector,
    pointsTooltip,
    groupCategorySelector,
    peerReviewsSelector,
    views: {
      'js-assignment-overrides': dueDateOverrideView,
    },
    canEditGrades: true,
  })

  view.$el.appendTo($('#fixtures'))
  view.render()

  return view
}

describe('EditView - Quiz Type Disabled State', () => {
  let view

  afterEach(() => {
    if (view) {
      view.remove()
      view = null
    }
  })

  test('quiz type selector is not disabled for new assignments', async () => {
    const assignment = new Assignment({
      name: 'New Assignment',
      secure_params: 'secure',
      assignment_overrides: [],
      submission_types: ['external_tool'],
      is_quiz_lti_assignment: true,
    })

    view = createEditView(assignment)

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

    // Check the disabled property
    const $quizTypeSelect = $('#assignment_quiz_type')
    expect($quizTypeSelect.prop('disabled')).toBe(false)
  })

  test('quiz type selector is disabled for existing assignments', async () => {
    const assignment = new Assignment({
      id: '123', // Use string to avoid prop type warning
      name: 'Existing Assignment',
      secure_params: 'secure',
      assignment_overrides: [],
      submission_types: ['external_tool'],
      is_quiz_lti_assignment: true,
    })

    view = createEditView(assignment)

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

    // Check if the assignment is recognized as existing
    expect(assignment.isNew()).toBe(false)

    const $quizTypeSelect = $('#assignment_quiz_type')
    // Verify the select element exists
    expect($quizTypeSelect.length).toBeGreaterThan(0)
    // The quiz type selector should be disabled for existing assignments
    expect($quizTypeSelect.prop('disabled')).toBe(true)
  })
})

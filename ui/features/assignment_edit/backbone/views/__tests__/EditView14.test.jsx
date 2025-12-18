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
import {waitFor, act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
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
import fetchMock from 'fetch-mock'
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
  fetchMock.get(/\/api\/v1\/courses\/\d+\/lti_apps\/launch_definitions/, [])
  fetchMock.get(/\/api\/v1\/courses\/\d+\/assignments\/\d+/, [])
  fetchMock.get(/\/api\/v1\/courses\/\d+\/settings/, {})
  fetchMock.get(/\/api\/v1\/courses\/\d+\/sections/, [])

  fetchMock.post('http://localhost/api/graphql', (url, opts) => {
    const body = JSON.parse(opts.body)

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

describe('EditView - Points Tooltip', () => {
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
          <div id="anonymous_submission_selector"></div>
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

    view = new EditView({
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
  })

  afterEach(() => {
    fakeENV.teardown()
    view.remove()
    $('#fixtures').empty()
  })

  test('shows tooltip for graded_survey', async () => {
    await act(async () => {
      view.handleQuizTypeChange('graded_survey')
    })

    await waitFor(() => {
      const tooltipWrapper = document.querySelector('#points_tooltip span')
      expect(tooltipWrapper).toBeTruthy()
      expect(tooltipWrapper.style.display).toBe('inline-block')
    })
  })

  test('hides tooltip for graded_quiz', async () => {
    await act(async () => {
      view.handleQuizTypeChange('graded_quiz')
    })

    await waitFor(() => {
      const tooltipWrapper = document.querySelector('#points_tooltip span')
      expect(tooltipWrapper).toBeTruthy()
      expect(tooltipWrapper.style.display).toBe('none')
    })
  })

  test('hides tooltip for ungraded_survey', async () => {
    await act(async () => {
      view.handleQuizTypeChange('ungraded_survey')
    })

    await waitFor(() => {
      const tooltipWrapper = document.querySelector('#points_tooltip span')
      expect(tooltipWrapper).toBeTruthy()
      expect(tooltipWrapper.style.display).toBe('none')
    })
  })

  test('displays correct tooltip text on hover', async () => {
    const user = userEvent.setup()
    await act(async () => {
      view.handleQuizTypeChange('graded_survey')
    })

    // Wait for the tooltip to be visible
    await waitFor(() => {
      const tooltipWrapper = document.querySelector('#points_tooltip span')
      expect(tooltipWrapper).toBeTruthy()
      expect(tooltipWrapper.style.display).toBe('inline-block')
    })

    const icon = document.querySelector('#points_tooltip svg')
    await user.hover(icon)

    await waitFor(() => {
      // Find the tooltip connected to our specific icon via data-position attributes
      const positionTarget = icon.getAttribute('data-position-target')
      const tooltipContent = document.querySelector(`[data-position-content="${positionTarget}"]`)
      expect(tooltipContent).toBeTruthy()
      expect(tooltipContent.textContent).toContain(
        'Points earned here reflect participation and effort.',
      )
      expect(tooltipContent.textContent).toContain('Responses will not be graded for accuracy.')
    })
  })

  test('updates tooltip visibility when quiz type changes', async () => {
    // Start with graded_quiz (tooltip hidden)
    await act(async () => {
      view.handleQuizTypeChange('graded_quiz')
    })

    await waitFor(() => {
      const tooltipWrapper = document.querySelector('#points_tooltip span')
      expect(tooltipWrapper.style.display).toBe('none')
    })

    // Change to graded_survey (tooltip should be visible)
    await act(async () => {
      view.handleQuizTypeChange('graded_survey')
    })

    await waitFor(() => {
      const tooltipWrapper = document.querySelector('#points_tooltip span')
      expect(tooltipWrapper.style.display).toBe('inline-block')
    })

    // Change back to graded_quiz (tooltip should be hidden again)
    await act(async () => {
      view.handleQuizTypeChange('graded_quiz')
    })

    await waitFor(() => {
      const tooltipWrapper = document.querySelector('#points_tooltip span')
      expect(tooltipWrapper.style.display).toBe('none')
    })
  })
})

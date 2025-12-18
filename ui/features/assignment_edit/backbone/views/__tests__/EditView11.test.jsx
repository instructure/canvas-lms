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
import {act} from '@testing-library/react'
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

// Skipped: Tests cause "window is not defined" and "Should not already be working" errors in CI
// due to @instructure/ui-position debounced operations and React scheduler tasks firing after
// test environment is torn down. The vi.runAllTimers() fix works locally but not reliably in CI.
describe.skip('EditView - Anonymous Submission Handling', () => {
  let view

  beforeEach(() => {
    // Use fake timers to prevent "window is not defined" errors from
    // @instructure/ui-position debounced operations firing after test teardown
    vi.useFakeTimers()

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

    // Setup DOM structure
    document.body.innerHTML = '<div id="fixtures"></div>'
    $('#fixtures').html(`
      <div>
        <form id="edit_assignment_form">
          <div class="control-group" style="display: block;">
            <label for="assignment_points_possible">Points</label>
            <input type="text" id="assignment_points_possible" value="10" />
            <div id="points_tooltip"></div>
          </div>
          <div id="assignment_group_selector"></div>
          <div id="grading_type_selector"></div>
          <fieldset id="submission_type_fields"></fieldset>
          <div id="quiz_type_selector"></div>
          <div id="anonymous_submission_selector" class="control-group" style="display: none;"></div>
          <div id="group_category_selector"></div>
          <div id="peer_reviews_fields"></div>
          <div class="js-assignment-overrides"></div>
          <div id="assignment_external_tools"></div>
        </form>
      </div>
    `)
  })

  afterEach(async () => {
    // Flush all pending timers (like @instructure/ui-position debounce) while still
    // in fake timer mode, then restore real timers to prevent "window is not defined"
    vi.runAllTimers()
    vi.useRealTimers()

    fakeENV.teardown()
    if (view) {
      view.remove()
    }
    $('#fixtures').empty()
  })

  test('anonymous submission selector is rendered for survey assignments', () => {
    const assignment = new Assignment({
      name: 'Survey Assignment',
      secure_params: 'secure',
      assignment_overrides: [],
      submission_types: ['external_tool'],
      is_quiz_lti_assignment: true,
      settings: {
        new_quizzes: {
          quiz_type: 'ungraded_survey',
        },
      },
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

    // Verify anonymous submission selector exists in the view
    expect(view.anonymousSubmissionSelector).toBeDefined()
    expect(view.anonymousSubmissionSelector.$el).toBeTruthy()
  })

  test('handleAnonymousSubmissionChange updates assignment model', () => {
    const assignment = new Assignment({
      name: 'Survey Assignment',
      secure_params: 'secure',
      assignment_overrides: [],
      submission_types: ['external_tool'],
      is_quiz_lti_assignment: true,
      settings: {
        new_quizzes: {
          quiz_type: 'ungraded_survey',
        },
      },
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

    // Initially false
    expect(view.assignment.newQuizzesAnonymousSubmission()).toBe(false)

    // Trigger change to true
    view.handleAnonymousSubmissionChange(true)
    expect(view.assignment.newQuizzesAnonymousSubmission()).toBe(true)

    // Trigger change to false
    view.handleAnonymousSubmissionChange(false)
    expect(view.assignment.newQuizzesAnonymousSubmission()).toBe(false)
  })

  test('anonymous submission selector shows when quiz type is a survey', () => {
    const assignment = new Assignment({
      name: 'Survey Assignment',
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

    const $anonymousSelector = view.anonymousSubmissionSelector.$el.closest('.control-group')

    // Initially hidden
    expect($anonymousSelector.css('display')).toBe('none')

    // Change to ungraded_survey - should be visible
    view.handleQuizTypeChange('ungraded_survey')
    expect($anonymousSelector.css('display')).not.toBe('none')

    // Change to graded_survey - should be visible
    view.handleQuizTypeChange('graded_survey')
    expect($anonymousSelector.css('display')).not.toBe('none')

    // Change to graded_quiz - should be hidden
    view.handleQuizTypeChange('graded_quiz')
    expect($anonymousSelector.css('display')).toBe('none')
  })

  test('anonymous submission selector is hidden when quiz type is not a survey', () => {
    const assignment = new Assignment({
      name: 'Quiz Assignment',
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

    const $anonymousSelector = view.anonymousSubmissionSelector.$el.closest('.control-group')

    // Test with graded_quiz - should be hidden
    view.handleQuizTypeChange('graded_quiz')
    expect($anonymousSelector.css('display')).toBe('none')
  })

  test('toJSON includes showAnonymousSubmissionSelector for surveys', () => {
    const assignment = new Assignment({
      name: 'Survey Assignment',
      secure_params: 'secure',
      assignment_overrides: [],
      submission_types: ['external_tool'],
      is_quiz_lti_assignment: true,
    })

    // Set the quiz type properly through the model method
    assignment.newQuizzesType('ungraded_survey')

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

    const data = view.toJSON()
    expect(data.showAnonymousSubmissionSelector).toBe(true)
  })

  test('toJSON does not include showAnonymousSubmissionSelector for non-surveys', () => {
    const assignment = new Assignment({
      name: 'Quiz Assignment',
      secure_params: 'secure',
      assignment_overrides: [],
      submission_types: ['external_tool'],
      is_quiz_lti_assignment: true,
      settings: {
        new_quizzes: {
          quiz_type: 'graded_quiz',
        },
      },
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

    const data = view.toJSON()
    expect(data.showAnonymousSubmissionSelector).toBe(false)
  })

  test('assignment model stores anonymous submission state', () => {
    const assignment = new Assignment({
      name: 'Survey Assignment',
      secure_params: 'secure',
      assignment_overrides: [],
    })

    // Initially false
    expect(assignment.newQuizzesAnonymousSubmission()).toBe(false)

    // Set to true
    assignment.newQuizzesAnonymousSubmission(true)
    expect(assignment.newQuizzesAnonymousSubmission()).toBe(true)

    // Verify it's stored in settings
    const settings = assignment.get('settings')
    expect(settings.new_quizzes.anonymous_participants).toBe(true)

    // Set to false
    assignment.newQuizzesAnonymousSubmission(false)
    expect(assignment.newQuizzesAnonymousSubmission()).toBe(false)
  })

  test('anonymous submission persists across quiz type changes', () => {
    const assignment = new Assignment({
      name: 'Survey Assignment',
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

    // Set anonymous submission to true
    view.handleAnonymousSubmissionChange(true)
    expect(view.assignment.newQuizzesAnonymousSubmission()).toBe(true)

    // Change quiz type
    view.handleQuizTypeChange('ungraded_survey')

    // Anonymous submission should still be true
    expect(view.assignment.newQuizzesAnonymousSubmission()).toBe(true)

    // Change to graded_survey
    view.handleQuizTypeChange('graded_survey')

    // Anonymous submission should still be true
    expect(view.assignment.newQuizzesAnonymousSubmission()).toBe(true)
  })
})

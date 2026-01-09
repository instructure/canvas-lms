/*
 * Copyright (C) 2025 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// IMPORTANT: Mock must be hoisted before other imports
import {vi} from 'vitest'

// Mock the RCE loader to prevent dynamic import timeouts during tests
// The RCE preloadRemoteModule() is called at the module level when EditView is imported,
// causing Vitest worker timeouts if not mocked
vi.mock('@canvas/rce/serviceRCELoader')

import $ from 'jquery'
import 'jquery-migrate'

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
import EditView from '../EditView'
import '@canvas/jquery/jquery.simulate'

const s_params = 'some super secure params'

EditView.prototype._attachEditorToDescription = () => {}

const editView = (assignmentOpts = {}) => {
  const defaultAssignmentOpts = {
    name: 'Test Assignment',
    secure_params: s_params,
    assignment_overrides: [],
    group_category_id: null,
    allowed_extensions: [],
    submission_types: ['none'],
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
    assignmentGroups: ENV?.ASSIGNMENT_GROUPS || [],
  })
  const gradingTypeSelector = new GradingTypeSelector({
    parentModel: assignment,
    canEditGrades: ENV?.PERMISSIONS?.can_edit_grades,
  })
  const groupCategorySelector = new GroupCategorySelector({
    parentModel: assignment,
    groupCategories: ENV?.GROUP_CATEGORIES || [],
    inClosedGradingPeriod: assignment.inClosedGradingPeriod(),
    showNewErrors: true,
  })
  const peerReviewsSelector = new PeerReviewsSelector({parentModel: assignment})
  const dueDateOverrideView = new DueDateOverrideView({
    model: dueDateList,
    views: {'js-assignment-overrides': {}},
  })

  const app = new EditView({
    model: assignment,
    assignmentGroupSelector,
    gradingTypeSelector,
    groupCategorySelector,
    peerReviewsSelector,
    dueDateList,
    views: {'js-assignment-overrides': dueDateOverrideView},
  })

  const $fixtures = $('#fixtures')
  $fixtures.html(`
    <div>
      <form id="edit_assignment_form" role="form">
        <input type="hidden" id="secure_params" value="${s_params}" />
        <div id="annotatable_attachment_input"></div>
        <label for="submission_type">Submission Type</label>
        <select id="assignment_submission_type" aria-label="Submission Type">
          <option value="none">None</option>
          <option value="online_text_entry">Text Entry</option>
          <option value="online_url">URL</option>
          <option value="online_upload">File Upload</option>
          <option value="external_tool">External Tool</option>
        </select>
        <div id="point_change_warning" role="alert"></div>
        <label for="assignment_points_possible">Points Possible</label>
        <input type="text" id="assignment_points_possible" aria-label="Points Possible" />
        <label for="assignment_name">Assignment Name</label>
        <input type="text" id="assignment_name" aria-label="Assignment Name" />
        <label for="assignment_description">Description</label>
        <textarea id="assignment_description" aria-label="Assignment Description"></textarea>
        <div id="similarity_detection_tools"></div>
        <div id="hide_zero_point_quiz_box"></div>
        <div id="assignment_external_tools"></div>
        <div id="assignment_group_selector"></div>
        <div id="grading_type_selector"></div>
        <div id="group_category_selector"></div>
        <div id="peer_reviews_selector"></div>
        <div class="js-assignment-overrides"></div>
        <input type="checkbox" id="assignment_peer_reviews_checkbox" />
        <div id="peer_reviews_allocation_and_grading_details"></div>
      </form>
    </div>
  `)

  app.$el.appendTo($fixtures)
  app.render()

  app.$submissionType = app.$('#assignment_submission_type')
  app.$assignmentPointsPossible = app.$('#assignment_points_possible')
  app.$description = app.$('#assignment_description')
  app.$hideZeroPointQuizzesBox = app.$('#hide_zero_point_quiz_box')
  app.$secureParams = app.$('#secure_params')
  app.$similarityDetectionTools = app.$('#similarity_detection_tools')

  return app
}

describe('EditView - Peer Review Integration - validateBeforeSave', () => {
  let view

  beforeEach(() => {
    // Use fake timers to prevent "window is not defined" errors from
    // React scheduler tasks and debounced operations firing after test teardown
    vi.useFakeTimers()

    // Clear any existing fixtures
    document.body.innerHTML = '<div id="fixtures"></div>'

    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1,
      ASSIGNMENT_GROUPS: [{id: 1, name: 'assignment group 1'}],
      PERMISSIONS: {
        can_edit_grades: true,
      },
      SETTINGS: {
        suppress_assignments: false,
      },
      GROUP_CATEGORIES: [],
      PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED: true,
    })

    view = editView()
  })

  afterEach(() => {
    // Flush all pending timers while still in fake timer mode, then restore
    // real timers to prevent "window is not defined" errors from React
    // scheduler tasks firing after test environment is torn down
    vi.runAllTimers()
    vi.useRealTimers()

    // Clean up view and all child views
    if (view) {
      view.remove()
      view = null
    }

    // Clean up any jQuery event handlers
    $(document).off()
    $(window).off()

    // Clean up DOM
    const fixtures = document.getElementById('fixtures')
    if (fixtures) {
      fixtures.innerHTML = ''
    }
    document.body.innerHTML = ''

    fakeENV.teardown()
    vi.clearAllMocks()
  })

  it('calls validatePeerReviewDetails when peer reviews are enabled', () => {
    const peerReviewCheckbox = document.getElementById('assignment_peer_reviews_checkbox')
    peerReviewCheckbox.checked = true

    const peerReviewDetailsEl = document.getElementById(
      'peer_reviews_allocation_and_grading_details',
    )
    const mockValidate = vi.fn().mockReturnValue(true)
    peerReviewDetailsEl.validatePeerReviewDetails = mockValidate

    const errors = view.validateBeforeSave({}, {})

    expect(mockValidate).toHaveBeenCalledTimes(1)
    expect(errors.peer_review_details).toBeUndefined()
  })

  it('adds error when validatePeerReviewDetails returns false', () => {
    const peerReviewCheckbox = document.getElementById('assignment_peer_reviews_checkbox')
    peerReviewCheckbox.checked = true

    const peerReviewDetailsEl = document.getElementById(
      'peer_reviews_allocation_and_grading_details',
    )
    const mockValidate = vi.fn().mockReturnValue(false)
    peerReviewDetailsEl.validatePeerReviewDetails = mockValidate

    const errors = view.validateBeforeSave({}, {})

    expect(mockValidate).toHaveBeenCalledTimes(1)
    expect(errors.peer_review_details).toBe(true)
  })

  it('does not call validatePeerReviewDetails when peer reviews are disabled', () => {
    const peerReviewCheckbox = document.getElementById('assignment_peer_reviews_checkbox')
    peerReviewCheckbox.checked = false

    const peerReviewDetailsEl = document.getElementById(
      'peer_reviews_allocation_and_grading_details',
    )
    const mockValidate = vi.fn()
    peerReviewDetailsEl.validatePeerReviewDetails = mockValidate

    const errors = view.validateBeforeSave({}, {})

    expect(mockValidate).not.toHaveBeenCalled()
    expect(errors.peer_review_details).toBeUndefined()
  })

  it('does not call validatePeerReviewDetails when feature flag is disabled', () => {
    // Temporarily disable the feature flag
    const originalValue = ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED
    ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = false

    const peerReviewCheckbox = document.getElementById('assignment_peer_reviews_checkbox')
    peerReviewCheckbox.checked = true

    const peerReviewDetailsEl = document.getElementById(
      'peer_reviews_allocation_and_grading_details',
    )
    const mockValidate = vi.fn()
    peerReviewDetailsEl.validatePeerReviewDetails = mockValidate

    const errors = view.validateBeforeSave({}, {})

    expect(mockValidate).not.toHaveBeenCalled()
    expect(errors.peer_review_details).toBeUndefined()

    // Restore original value
    ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = originalValue
  })

  it('does not error when validatePeerReviewDetails function is not defined', () => {
    const peerReviewCheckbox = document.getElementById('assignment_peer_reviews_checkbox')
    peerReviewCheckbox.checked = true

    const peerReviewDetailsEl = document.getElementById(
      'peer_reviews_allocation_and_grading_details',
    )
    delete peerReviewDetailsEl.validatePeerReviewDetails

    const errors = view.validateBeforeSave({}, {})

    expect(errors.peer_review_details).toBeUndefined()
  })

  it('does not error when peer review element does not exist', () => {
    const peerReviewCheckbox = document.getElementById('assignment_peer_reviews_checkbox')
    peerReviewCheckbox.checked = true

    const peerReviewDetailsEl = document.getElementById(
      'peer_reviews_allocation_and_grading_details',
    )
    peerReviewDetailsEl.remove()

    const errors = view.validateBeforeSave({}, {})

    expect(errors.peer_review_details).toBeUndefined()
  })
})

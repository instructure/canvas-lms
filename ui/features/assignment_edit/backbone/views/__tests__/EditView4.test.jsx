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
import $ from 'jquery'
import EditView from '../EditView'
import '@canvas/jquery/jquery.simulate'
import fetchMock from 'jest-fetch-mock'

const s_params = 'some super secure params'
const fixtures = document.createElement('div')
fixtures.id = 'fixtures'
document.body.appendChild(fixtures)
const currentOrigin = window.location.origin

// Helper functions
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

// Mock RCE initialization
EditView.prototype._attachEditorToDescription = () => {}

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
    canEditGrades: ENV?.PERMISSIONS?.can_edit_grades || !assignment.gradedSubmissionsExist(),
  })
  return app
}

describe('EditView', () => {
  let view

  beforeEach(() => {
    fetchMock.resetMocks()
    fetchMock.mockResponse(JSON.stringify({}))

    fixtures.innerHTML = `
      <div id="fixtures">
        <span id="editor_tabs"></span>
        <span data-component="ModeratedGradingFormFieldGroup"></span>
        <form id="edit_assignment_form">
          <input id="assignment_name" />
          <input id="assignment_points_possible" />
          <input id="assignment_peer_reviews" type="checkbox" />
          <div id="assignment_peer_reviews_fields"></div>
          <input id="has_group_category" type="checkbox" />
          <input id="assignment_group_category_id" />
          <input id="assignment_grading_type" />
          <input id="assignment_grader_count" value="" />
          <div id="grader_count_fields"></div>
          <input id="assignment_anonymous_grading" type="checkbox" />
          <input id="assignment_grader_comments_visible_to_graders" type="checkbox" />
          <input id="assignment_graders_anonymous_to_graders" type="checkbox" />
          <input id="assignment_anonymous_instructor_annotations" type="checkbox" />
          <input id="assignment_moderated_grading" type="checkbox" />
          <input id="assignment_final_grader_id" />
          <div id="similarity_detection_tools"></div>
          <div id="assignment_external_tools"></div>
          <input type="hidden" name="secure_params" id="secure_params" value="test" />
        </form>
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
      ANONYMOUS_GRADING_ENABLED: true,
      MODERATED_GRADING_GRADER_LIMIT: 10,
    })

    view = createEditView()
    view.$el.appendTo($('#fixtures'))
    view.render()
    view.afterRender()

    // Initialize jQuery elements
    view.$assignment_grader_count = view.$('#assignment_grader_count')
    view.$assignment_moderated_grading = view.$('#assignment_moderated_grading')
    view.$groupCategoryBox = view.$('#has_group_category')
    view.$anonymousGradingBox = view.$('#assignment_anonymous_grading')
    view.$graderCommentsVisibleToGradersBox = view.$(
      '#assignment_grader_comments_visible_to_graders',
    )
    view.$gradersAnonymousToGradersBox = view.$('#assignment_graders_anonymous_to_graders')
    view.$similarityDetectionTools = view.$('#similarity_detection_tools')
    view.$assignmentExternalTools = view.$('#assignment_external_tools')
    view.$secureParams = view.$('#secure_params')
  })

  afterEach(() => {
    fakeENV.teardown()
    view?.$el.remove()
    fixtures.innerHTML = ''
  })

  describe('anonymous grading', () => {
    beforeEach(() => {
      view.assignment.set('anonymous_grading', true)
      view.render()
      view.afterRender()
      view.handleAnonymousGradingChange()
    })

    it('disables grader comments visible to graders when anonymous grading is enabled', () => {
      const $checkbox = $('#assignment_grader_comments_visible_to_graders')
      view.disableCheckbox($checkbox)
      expect($checkbox.prop('disabled')).toBe(true)
    })

    it('unchecks grader comments visible to graders when anonymous grading is enabled', () => {
      const checkbox = document.getElementById('assignment_grader_comments_visible_to_graders')
      expect(checkbox.checked).toBe(false)
    })

    it('disables graders anonymous to graders when anonymous grading is enabled', () => {
      const $checkbox = $('#assignment_graders_anonymous_to_graders')
      view.disableCheckbox($checkbox)
      expect($checkbox.prop('disabled')).toBe(true)
    })

    it('unchecks graders anonymous to graders when anonymous grading is enabled', () => {
      const checkbox = document.getElementById('assignment_graders_anonymous_to_graders')
      expect(checkbox.checked).toBe(false)
    })

    it('does not show the checkbox when environment is not set', () => {
      ENV.ANONYMOUS_GRADING_ENABLED = false
      view = createEditView()
      view.render()
      expect(view.toJSON().anonymousGradingEnabled).toBe(false)
      expect(view.$el.find('input#assignment_anonymous_grading')).toHaveLength(0)
    })

    it('does not show the checkbox when environment set to false', () => {
      ENV.ANONYMOUS_GRADING_ENABLED = false
      view = createEditView()
      view.render()
      expect(view.toJSON().anonymousGradingEnabled).toBe(false)
      expect(view.$el.find('input#assignment_anonymous_grading')).toHaveLength(0)
    })

    it('shows the checkbox when environment is set to true', () => {
      ENV.ANONYMOUS_GRADING_ENABLED = true
      view = createEditView()
      view.render()
      expect(view.toJSON().anonymousGradingEnabled).toBe(true)
      expect(view.$el.find('input#assignment_anonymous_grading')).toHaveLength(1)
    })

    it('is disabled when group assignment is enabled', () => {
      ENV.NEW_QUIZZES_ANONYMOUS_GRADING_ENABLED = true
      ENV.ANONYMOUS_GRADING_ENABLED = true
      ENV.GROUP_CATEGORIES = [{id: '1', name: 'Group Category #1'}]
      view = createEditView({group_category_id: '1'})
      view.$el.appendTo($('#fixtures'))
      view.render()
      view.afterRender()
      const $anonymousGradingCheckbox = $('#assignment_anonymous_grading')
      view.disableCheckbox($anonymousGradingCheckbox)
      expect($anonymousGradingCheckbox.prop('disabled')).toBe(true)
    })
  })

  describe('validateGraderCount', () => {
    it('returns no errors if moderated grading is turned off', () => {
      const errors = view.validateGraderCount({moderated_grading: 'off'})
      expect(Object.keys(errors)).toHaveLength(0)
    })

    it('returns an error when grader count is blank and moderated grading is enabled', () => {
      const errors = view.validateGraderCount({moderated_grading: 'on', grader_count: ''})
      expect(errors.grader_count[0].message).toBe('Grader count is required')
    })

    it('returns an error when grader count is 0 and moderated grading is enabled', () => {
      const errors = view.validateGraderCount({moderated_grading: 'on', grader_count: '0'})
      expect(errors.grader_count[0].message).toBe('Grader count cannot be 0')
    })

    it('returns no error when grader count is valid and moderated grading is enabled', () => {
      const errors = view.validateGraderCount({moderated_grading: 'on', grader_count: '1'})
      expect(errors).toEqual({})
    })
  })
})

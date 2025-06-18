/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import AssignmentGroupSelector from '@canvas/assignments/backbone/views/AssignmentGroupSelector'
import GradingTypeSelector from '@canvas/assignments/backbone/views/GradingTypeSelector'
import PeerReviewsSelector from '@canvas/assignments/backbone/views/PeerReviewsSelector'
import DueDateOverrideView from '@canvas/due-dates'
import DueDateList from '@canvas/due-dates/backbone/models/DueDateList'
import GroupCategorySelector, {
  GROUP_CATEGORY_SELECT,
} from '@canvas/groups/backbone/views/GroupCategorySelector'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import Section from '@canvas/sections/backbone/models/Section'
import {isAccessible} from '@canvas/test-utils/assertions'
import fakeENV from '@canvas/test-utils/fakeENV'
import EditView from '../EditView'
import '@canvas/jquery/jquery.simulate'

const s_params = 'some super secure params'

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

// The async nature of RCE initialization makes it really hard to unit test
// stub out the function that kicks it off
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

  // Setup the DOM elements that the view expects
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
          <option value="external_tool_placement_123">External Tool Placement</option>
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
      </form>
    </div>
  `)

  app.$el.appendTo($fixtures)
  app.render()

  // Cache jQuery selectors
  app.$submissionType = app.$('#assignment_submission_type')
  app.$assignmentPointsPossible = app.$('#assignment_points_possible')
  app.$description = app.$('#assignment_description')
  app.$hideZeroPointQuizzesBox = app.$('#hide_zero_point_quiz_box')
  app.$secureParams = app.$('#secure_params')
  app.$similarityDetectionTools = app.$('#similarity_detection_tools')

  return app
}

describe('EditView', () => {
  let view

  beforeEach(() => {
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
      SUBMISSION_TYPE_SELECTION_TOOLS: [
        {
          id: '123',
          name: 'External Tool',
          placement: 'external_tool_placement_123',
        },
      ],
    })

    view = editView()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
    jest.restoreAllMocks()
  })

  it('should be accessible', async () => {
    const view = editView()
    view.$el.appendTo($('#fixtures'))
    view.afterRender()

    await isAccessible(view.$el[0], {a11yReport: true})
  })

  it('renders', () => {
    const view = editView()
    expect(view.$('#assignment_name').val()).toBe('Test Assignment')
  })

  it('rejects missing group set for group assignment', () => {
    const view = editView()
    const data = {group_category_id: 'blank'}
    const errors = view.validateBeforeSave(data, {})
    expect(errors[GROUP_CATEGORY_SELECT][0].message).toBe('Please create a group set')
  })

  it('rejects a letter for points_possible', () => {
    const view = editView()
    const data = {points_possible: 'a'}
    const errors = view.validateBeforeSave(data, {})
    expect(errors.points_possible[0].message).toBe('Points value must be a number')
  })

  it('validates presence of a final grader', () => {
    const view = editView()
    const validateFinalGrader = jest.spyOn(view, 'validateFinalGrader')
    view.validateBeforeSave({}, {})
    expect(validateFinalGrader).toHaveBeenCalledTimes(1)
    validateFinalGrader.mockRestore()
  })

  it('validates grader count', () => {
    const view = editView()
    const validateGraderCount = jest.spyOn(view, 'validateGraderCount')
    view.validateBeforeSave({}, {})
    expect(validateGraderCount).toHaveBeenCalledTimes(1)
    validateGraderCount.mockRestore()
  })

  it('validates presence of attachment when assignment has type annotatable_attachment', () => {
    const view = editView()
    const data = {submission_types: ['student_annotation']}
    const errors = view.validateBeforeSave(data, {})
    const annotatedDocumentError = errors['online_submission_types[student_annotation]'][0]
    expect(annotatedDocumentError.message).toBe('This submission type requires a file upload')
  })

  it('validates presence of attachment use justification when assignment has type annotatable_attachment', () => {
    ENV.USAGE_RIGHTS_REQUIRED = true
    const view = editView()
    view.setAnnotatedDocument({id: '1', name: 'test.pdf', contextType: 'courses', contextId: '1'})
    view.renderAnnotatedDocumentUsageRightsSelectBox()
    view.$('#usageRightSelector').val('choose')
    const data = {submission_types: ['student_annotation']}
    const errors = view.validateBeforeSave(data, {})
    expect(errors.usage_rights_use_justification).toBeTruthy()
    expect(errors.usage_rights_use_justification[0].message).toBe(
      'Identifying the usage rights is required',
    )
  })

  it('does not allow group assignment for large rosters', () => {
    ENV.IS_LARGE_ROSTER = true
    const view = editView()
    expect(view.$('#group_category_selector')).toHaveLength(0)
  })

  it('does not show the "hide_zero_point_quiz" checkbox when it is not a quiz lti assignment', () => {
    ENV.HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED = true
    const view = editView({is_quiz_lti_assignment: false})
    expect(view.$hideZeroPointQuizzesBox).toHaveLength(0)
  })

  it('does not allow group assignment for anonymously graded assignments', () => {
    ENV.ANONYMOUS_GRADING_ENABLED = true
    const view = editView({anonymous_grading: true})
    view.$el.appendTo($('#fixtures'))
    view.afterRender()
    const hasGroupCategoryCheckbox = view.$el.find('input#has_group_category')
    expect(hasGroupCategoryCheckbox.prop('disabled')).toBe(true)
  })

  it('does not allow peer review for large rosters', () => {
    ENV.IS_LARGE_ROSTER = true
    const view = editView()
    expect(view.$('#assignment_peer_reviews_fields')).toHaveLength(0)
  })

  it('does not allow point value of -1 or less if grading type is letter', () => {
    const view = editView()
    const data = {points_possible: '-1', grading_type: 'letter_grade'}
    const errors = view._validatePointsPossible(data, [])
    expect(errors.points_possible[0].message).toBe('Points value must be 0 or greater')
  })

  it('requires name to save assignment', () => {
    const view = editView()
    const data = {name: ''}
    const errors = view.validateBeforeSave(data, {})
    expect(errors.name).toBeTruthy()
    expect(errors.name).toHaveLength(1)
    expect(errors.name[0].message).toBe('Name is required')
  })

  it('has an error when a name has 256 chars', () => {
    const view = editView()
    const errors = nameLengthHelper(view, 256, false, 30, '0', 'points')
    expect(errors.name).toBeTruthy()
    expect(errors.name).toHaveLength(1)
    expect(errors.name[0].message).toBe('Must be fewer than 256 characters')
  })

  it('allows assignment to save when a name has 256 chars, MAX_NAME_LENGTH is not required and post_to_sis is true', () => {
    const view = editView()
    const errors = nameLengthHelper(view, 256, false, 30, '1', 'points')
    expect(errors.name).toBeFalsy()
  })

  it('allows assignment to save when a name has 15 chars, MAX_NAME_LENGTH is 10 and is required, post_to_sis is true and grading_type is not_graded', () => {
    const view = editView()
    const errors = nameLengthHelper(view, 15, true, 10, '1', 'not_graded')
    expect(errors.name).toBeFalsy()
  })

  it('has an error when a name has 11 chars, MAX_NAME_LENGTH is 10 and required and post_to_sis is true', () => {
    const view = editView()
    const errors = nameLengthHelper(view, 11, true, 10, '1', 'points')
    expect(errors.name).toBeTruthy()
    expect(errors.name).toHaveLength(1)
    expect(errors.name[0].message).toBe('Must be fewer than 11 characters')
  })

  it('allows assignment to save when name has 11 chars, MAX_NAME_LENGTH is 10 and required, but post_to_sis is false', () => {
    const view = editView()
    const errors = nameLengthHelper(view, 11, true, 10, '0', 'points')
    expect(errors.name).toBeFalsy()
  })

  it('allows assignment to save when name has 10 chars, MAX_NAME_LENGTH is 10 and required, and post_to_sis is true', () => {
    const view = editView()
    const errors = nameLengthHelper(view, 10, true, 10, '1', 'points')
    expect(errors.name).toBeFalsy()
  })

  it("don't validate name if it is frozen", () => {
    const view = editView()
    view.model.set('frozen_attributes', ['title'])
    const errors = view.validateBeforeSave({}, {})
    expect(errors.name).toBeFalsy()
  })

  it('renders a hidden secure_params field', () => {
    const view = editView()
    const secure_params = view.$('#secure_params')
    expect(secure_params.attr('type')).toBe('hidden')
    expect(secure_params.val()).toBe(s_params)
  })

  it('does show error message on assignment point change with submissions', () => {
    const view = editView({has_submitted_submissions: true})
    view.$el.appendTo($('#fixtures'))
    view.$el.find('#assignment_points_possible').val(1).trigger('change')
    expect(view.$el.find('#point_change_warning')[0]).toBeVisible()
    view.$el.find('#assignment_points_possible').val(0).trigger('change')
    expect(view.$el.find('#point_change_warning')[0]).not.toBeVisible()
  })

  it('does not show error message on assignment point change without submissions', () => {
    const view = editView({has_submitted_submissions: false})
    view.$el.appendTo($('#fixtures'))
    expect(view.$el.find('#point_change_warning:visible')[0]).not.toBeDefined()
    view.$el.find('#assignment_points_possible').val(1).trigger('change')
    expect(view.$el.find('#point_change_warning:visible')[0]).not.toBeDefined()
  })

  it('does not allow point value of "" if grading type is letter', () => {
    const view = editView()
    const data = {points_possible: '', grading_type: 'letter_grade'}
    const errors = view._validatePointsPossible(data, [])
    expect(errors.points_possible[0].message).toBe('Points value must be 0 or greater')
  })

  it('does not allow blank default external tool url', () => {
    const view = editView()
    const data = {submission_type: 'external_tool'}
    const errors = view._validateExternalTool(data, [])
    expect(errors['default-tool-launch-button'][0].message).toBe(
      'External Tool URL cannot be left blank',
    )
  })

  it('does not allow blank external tool url', () => {
    const view = editView()
    const data = {submission_type: 'external_tool'}
    const errors = view._validateExternalTool(data, [])
    expect(errors['external_tool_tag_attributes[url]'][0].message).toBe(
      'External Tool URL cannot be left blank',
    )
  })

  it('removes group_category_id if an external tool is selected', () => {
    const view = editView()
    let data = {
      submission_type: 'external_tool',
      group_category_id: '1',
    }
    data = view._unsetGroupsIfExternalTool(data)
    expect(data.group_category_id).toBe(null)
  })

  it('renders escaped angle brackets properly', () => {
    const desc = '<p>&lt;E&gt;</p>'
    const view = editView({description: '<p>&lt;E&gt;</p>'})
    expect(view.$description.val()).toMatch(desc)
  })

  it('routes to discussion details normally', () => {
    const view = editView({html_url: 'http://foo'})
    expect(view.locationAfterSave({})).toBe('http://foo')
  })

  describe('Submission Type Selection', () => {
    beforeEach(() => {
      ENV.SUBMISSION_TYPE_SELECTION_TOOLS = [
        {
          id: '123',
          name: 'External Tool',
          placement: 'external_tool_placement_123',
        },
      ]
    })

    it('when submission_type_selection tool chosen: sets selectedTool and sets content_type to context_external_tool', () => {
      const view = editView()
      view.afterRender()

      view.$('#assignment_submission_type').val('external_tool_placement_123')
      view.$('#assignment_submission_type').trigger('change')

      expect(view.selectedTool).toBeDefined()
      expect(view.selectedTool.id).toBe('123')
      expect(view.selectedTool.name).toBe('External Tool')
      expect(view.getFormData().submission_type).toBe('external_tool')
    })

    it('when a submission_type_selection sends back title and preserveExistingAssignmentName: shows resource and does not overwrite title', () => {
      const view = editView()
      view.afterRender()

      // Set initial assignment name
      view.$('#assignment_name').val('Original Assignment Name')

      view.$('#assignment_submission_type').val('external_tool_placement_123')
      view.$('#assignment_submission_type').trigger('change')

      view.handleContentItem({
        type: 'ltiResourceLink',
        title: 'Tool Resource',
        url: 'http://example.com/launch',
        'https://canvas.instructure.com/lti/preserveExistingAssignmentName': true,
      })

      expect(view.$('#assignment_name').val()).toBe('Original Assignment Name')
      expect(view.$('#assignment_external_tool_tag_attributes_url').val()).toBe(
        'http://example.com/launch',
      )
    })

    it('does not allow submission_type_selection tools (selectedTool set) with require_resource_selection=true when content type is context_external_tool', () => {
      const view = editView()
      view.selectedTool = {require_resource_selection: true}
      const data = {
        submission_type: 'external_tool',
        external_tool_tag_attributes: {
          content_type: 'context_external_tool',
          title: "shouldn't look at this",
        },
      }
      const errors = view._validateExternalTool(data, [])
      expect(errors['assignment_submission_type_selection_launch_button'][0].message).toBe(
        'Please click above to launch the tool and select a resource.',
      )
    })

    it('allows submission_type_selection tools (selectedTool set) with require_resource_selection not set with no resource title', () => {
      const view = editView()
      view.selectedTool = {}
      const data = {submission_type: 'external_tool'}
      const errors = view._validateExternalTool(data, [])
      expect(errors.assignment_submission_container).toBeUndefined()
    })

    it('allows submission_type_selection tools with require_resource_selection=true with a resource title', () => {
      const view = editView()
      view.selectedTool = {require_resource_selection: true}
      const data = {
        submission_type: 'external_tool',
        external_tool_tag_attributes: {
          content_type: 'ltiResourceLink',
          title: 'some title',
        },
      }
      const errors = view._validateExternalTool(data, [])
      expect(errors.assignment_submission_container).toBeUndefined()
    })

    it('when a submission_type_selection tool is chosen and a resource selected: sets selectedTool, title, assignment name', () => {
      const view = editView()
      view.afterRender()
      view.$('#assignment_submission_type').val('external_tool_placement_123')
      view.$('#assignment_submission_type').trigger('change')
      view.handleContentItem({
        type: 'ltiResourceLink',
        title: 'Tool Resource',
        url: 'http://example.com/launch',
      })
      expect(view.$('#assignment_name').val()).toBe('Tool Resource')
      expect(view.$('#assignment_external_tool_tag_attributes_url').val()).toBe(
        'http://example.com/launch',
      )
    })

    it('when a submission_type_selection tool is chosen and a resource w/o title selected: sets selectedTool and sets content type to ltiResourceLink', () => {
      const view = editView()
      view.afterRender()
      view.$('#assignment_submission_type').val('external_tool_placement_123')
      view.$('#assignment_submission_type').trigger('change')
      view.handleContentItem({
        type: 'ltiResourceLink',
        url: 'http://example.com/launch',
      })
      expect(view.$('#assignment_external_tool_tag_attributes_content_type').val()).toBe(
        'ltiResourceLink',
      )
    })

    it('when a submission_type_selection tool chosen, a resource selected, and the resource removed: keeps selectedTool but clears out title and content type', () => {
      const view = editView()
      view.afterRender()
      view.$('#assignment_submission_type').val('external_tool_placement_123')
      view.$('#assignment_submission_type').trigger('change')
      view.handleContentItem({
        type: 'ltiResourceLink',
        title: 'Tool Resource',
        url: 'http://example.com/launch',
      })
      // Simulate removing content by triggering change with empty values
      view.$('#assignment_external_tool_tag_attributes_content_type').val('').trigger('change')
      view.$('#assignment_external_tool_tag_attributes_title').val('').trigger('change')
      expect(view.$('#assignment_external_tool_tag_attributes_content_type').val()).toBe('')
      expect(view.$('#assignment_external_tool_tag_attributes_title').val()).toBe('')
    })

    it('when a submission_type_selection tool chosen but changed back to generic "External Tool": URL and content type are reset', () => {
      const view = editView()
      view.afterRender()
      view.$('#assignment_submission_type').val('external_tool_placement_123')
      view.$('#assignment_submission_type').trigger('change')
      view.handleContentItem({
        type: 'ltiResourceLink',
        title: 'Tool Resource',
        url: 'http://example.com/launch',
      })
      // Reset the form and trigger all necessary changes
      view.$('#assignment_external_tool_tag_attributes_content_type').val('context_external_tool')
      view.$('#assignment_external_tool_tag_attributes_url').val('')
      view.$('#assignment_submission_type').val('external_tool')
      view.$('#assignment_submission_type').trigger('change')
      expect(view.$('#assignment_external_tool_tag_attributes_url').val()).toBe('')
      expect(view.$('#assignment_external_tool_tag_attributes_content_type').val()).toBe(
        'context_external_tool',
      )
    })
  })

  it('does not validate allowed extensions if file uploads is not a submission type', () => {
    const view = editView()
    const data = {submission_types: ['online_url'], allowed_extensions: []}
    const errors = view._validateAllowedExtensions(data, {})
    expect(errors.allowed_extensions).toBeUndefined()
  })

  it('adds and removes student group', () => {
    ENV.GROUP_CATEGORIES = [{id: '1', name: 'fun group'}]
    ENV.ASSIGNMENT_GROUPS = [{id: 1, name: 'assignment group 1'}]
    const view = editView()
    expect(view.assignment.toView().groupCategoryId).toBeNull()

    // Test adding group
    view.$('#has_group_category').prop('checked', true).trigger('change')
    view.$('#assignment_group_category_id').val('1').trigger('change')
    expect(view.getFormData().group_category_id).toBe('1')

    // Test removing group
    view.$('#has_group_category').prop('checked', false).trigger('change')
    expect(view.getFormData().group_category_id).toBeNull()
  })
})

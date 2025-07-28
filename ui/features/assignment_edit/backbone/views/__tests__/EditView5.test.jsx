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
import userSettings from '@canvas/user-settings'
import React from 'react'
import ReactDOM from 'react-dom'
import EditView from '../EditView'
import '@canvas/jquery/jquery.simulate'

// Mock RCE and related modules
jest.mock('@canvas/rce/serviceRCELoader', () => ({
  loadRCE: jest.fn().mockResolvedValue({}),
  preload: jest.fn().mockResolvedValue({}),
  RCE: null,
}))

jest.mock('@canvas/rce/RichContentEditor', () => ({
  preloadRemoteModule: jest.fn().mockResolvedValue({}),
  loadNewEditor: jest.fn().mockResolvedValue({}),
  destroyRCE: jest.fn(),
  RichContentEditor: {
    preloadRemoteModule: jest.fn().mockResolvedValue({}),
    loadNewEditor: jest.fn().mockResolvedValue({}),
    destroyRCE: jest.fn(),
  },
}))

// Mock the external tool launcher
jest.mock('@canvas/external-tools/react/components/ExternalToolModalLauncher', () => ({
  __esModule: true,
  default: () => <div />,
}))

// Mock the submission type container
jest.mock('../../../react/AssignmentSubmissionTypeContainer', () => ({
  AssignmentSubmissionTypeContainer: () => <div />,
}))

const s_params = 'some super secure params'
let fixtures

// Helper function to set up fake environment
const setupFakeEnv = (envOptions = {}) => {
  const defaultEnvOptions = {
    AVAILABLE_MODERATORS: [],
    current_user_roles: ['teacher'],
    HAS_GRADED_SUBMISSIONS: false,
    LOCALE: 'en',
    MODERATED_GRADING_ENABLED: true,
    MODERATED_GRADING_GRADER_LIMIT: 2,
    MODERATED_GRADING_MAX_GRADER_COUNT: 4,
    VALID_DATE_RANGE: {},
    COURSE_ID: 1,
    PERMISSIONS: {
      can_edit_grades: true,
    },
    RICH_CONTENT_APP_HOST: 'http://localhost',
    RICH_CONTENT_CAN_UPLOAD_FILES: true,
    RICH_CONTENT_FILES_TAB_DISABLED: false,
    RICH_CONTENT_INST_RECORD_TAB_DISABLED: false,
    GROUP_CATEGORIES: [{id: '1', name: 'Group Category #1'}],
    ANONYMOUS_GRADING_ENABLED: false,
    NEW_QUIZZES_ANONYMOUS_GRADING_ENABLED: true,
    SETTINGS: {
      suppress_assignments: false,
    },
  }
  fakeENV.setup({...defaultEnvOptions, ...envOptions})
}

// Helper function to create EditView instance
const createEditView = (assignmentOpts = {}) => {
  const defaultAssignmentOpts = {
    name: 'Test Assignment',
    secure_params: s_params,
    assignment_overrides: [],
    moderated_grading: false,
    final_grader_id: null,
    grader_count: 0,
    grader_comments_visible_to_graders: false,
    grader_names_visible_to_final_grader: false,
    peer_reviews: false,
    group_category_id: null,
  }
  const assignment = new Assignment({...defaultAssignmentOpts, ...assignmentOpts})

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
    canEditGrades: ENV.PERMISSIONS?.can_edit_grades || !assignment.gradedSubmissionsExist(),
  })

  // Stub out RCE initialization
  app._attachEditorToDescription = () => {}

  return app.render()
}

describe('EditView: anonymous grading', () => {
  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    setupFakeEnv()
  })

  afterEach(() => {
    fakeENV.teardown()
    fixtures.remove()
    jest.clearAllMocks()
  })

  it('does not show the checkbox when environment is not set', () => {
    const view = createEditView()
    const $anonymousGradingBox = view.$el.find('input#assignment_anonymous_grading')
    expect($anonymousGradingBox).toHaveLength(0)
  })

  it('does not show the checkbox when environment set to false', () => {
    setupFakeEnv({ANONYMOUS_GRADING_ENABLED: false})
    const view = createEditView()
    const $anonymousGradingBox = view.$el.find('input#assignment_anonymous_grading')
    expect($anonymousGradingBox).toHaveLength(0)
  })

  it('shows the checkbox when environment is set to true', () => {
    setupFakeEnv({ANONYMOUS_GRADING_ENABLED: true})
    const view = createEditView()
    const $anonymousGradingBox = view.$el.find('input#assignment_anonymous_grading')
    expect($anonymousGradingBox).toHaveLength(1)
  })

  it('is disabled when group assignment is enabled', () => {
    setupFakeEnv({ANONYMOUS_GRADING_ENABLED: true})
    const view = createEditView({group_category_id: '1'})
    view.$el.appendTo($('#fixtures'))
    view.afterRender()
    const $anonymousGradingBox = view.$el.find('input#assignment_anonymous_grading')
    expect($anonymousGradingBox.prop('disabled')).toBe(true)
  })

  it('is still enabled when editing a quiz lti assignment with anonymous grading turned on', () => {
    setupFakeEnv({ANONYMOUS_GRADING_ENABLED: true})
    const view = createEditView({
      is_quiz_lti_assignment: true,
      anonymous_grading: true,
      id: '1',
    })
    view.$el.appendTo($('#fixtures'))
    view.afterRender()
    const $anonymousGradingBox = view.$el.find('input#assignment_anonymous_grading')
    expect($anonymousGradingBox.prop('disabled')).toBe(false)
  })

  it('is enabled when creating a quiz lti assignment with anonymous grading turned on', () => {
    setupFakeEnv({ANONYMOUS_GRADING_ENABLED: true})
    const view = createEditView({
      is_quiz_lti_assignment: true,
      anonymous_grading: true,
      id: null,
    })
    view.$el.appendTo($('#fixtures'))
    view.afterRender()
    const $anonymousGradingBox = view.$el.find('input#assignment_anonymous_grading')
    expect($anonymousGradingBox.prop('disabled')).toBe(false)
  })
})

describe('EditView: Anonymous Instructor Annotations', () => {
  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    setupFakeEnv()
  })

  afterEach(() => {
    fakeENV.teardown()
    fixtures.remove()
    jest.clearAllMocks()
  })

  it('when environment is not set, does not enable editing the property', () => {
    const view = createEditView()
    const $aiaBox = view.$el.find('input#assignment_anonymous_instructor_annotations')
    expect($aiaBox).toHaveLength(0)
  })

  it('when environment is set to false, does not enable editing the property', () => {
    setupFakeEnv({ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED: false})
    const view = createEditView()
    const $aiaBox = view.$el.find('input#assignment_anonymous_instructor_annotations')
    expect($aiaBox).toHaveLength(0)
  })

  it('when environment is set to true, enables editing the property', () => {
    setupFakeEnv({ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED: true})
    const view = createEditView()
    const $aiaBox = view.$el.find('input#assignment_anonymous_instructor_annotations')
    expect($aiaBox).toHaveLength(1)
  })
})

describe('EditView: Anonymous Moderated Marking', () => {
  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = `
      <div id="assignment_toggle_advanced_options">
        <span data-component="ModeratedGradingFormFieldGroup"></span>
      </div>
    `
    setupFakeEnv()
  })

  afterEach(() => {
    fakeENV.teardown()
    fixtures.remove()
    jest.clearAllMocks()
  })

  it('adds the ModeratedGradingFormFieldGroup mount point', () => {
    const view = createEditView()
    const mountPoint = view.$el.find('span[data-component="ModeratedGradingFormFieldGroup"]')
    expect(mountPoint).toHaveLength(1)
  })
})

describe('EditView#validateFinalGrader', () => {
  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = `
      <div id="assignment_toggle_advanced_options">
        <span data-component="ModeratedGradingFormFieldGroup"></span>
      </div>
    `
    setupFakeEnv()
  })

  afterEach(() => {
    fakeENV.teardown()
    fixtures.remove()
    jest.clearAllMocks()
  })

  it('returns no errors if moderated grading is turned off', () => {
    const view = createEditView()
    const errors = view.validateFinalGrader({moderated_grading: 'off'})
    expect(Object.keys(errors)).toHaveLength(0)
  })

  it('returns no errors if moderated grading is turned on and there is a final grader', () => {
    const view = createEditView()
    const errors = view.validateFinalGrader({moderated_grading: 'on', final_grader_id: '1'})
    expect(Object.keys(errors)).toHaveLength(0)
  })

  it('returns an error if moderated grading is turned on and there is no final grader', () => {
    const view = createEditView()
    const errors = view.validateFinalGrader({moderated_grading: 'on', final_grader_id: null})
    expect(errors.final_grader_id[0].message).toBe('Must select a grader')
  })
})

describe('EditView#validateGraderCount', () => {
  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = `
      <div id="assignment_toggle_advanced_options">
        <span data-component="ModeratedGradingFormFieldGroup"></span>
      </div>
    `
    setupFakeEnv({MODERATED_GRADING_GRADER_LIMIT: 2})
  })

  afterEach(() => {
    fakeENV.teardown()
    fixtures.remove()
    jest.clearAllMocks()
  })

  it('returns no errors if moderated grading is turned off', () => {
    const view = createEditView()
    const errors = view.validateGraderCount({})
    expect(errors).toEqual({})
  })

  it('returns no errors if moderated grading is turned on and grader count is in an acceptable range', () => {
    const view = createEditView()
    const errors = view.validateGraderCount({moderated_grading: 'on', grader_count: '2'})
    expect(errors).toEqual({})
  })

  it('returns an error if moderated grading is turned on and grader count is empty', () => {
    const view = createEditView()
    const errors = view.validateGraderCount({moderated_grading: 'on', grader_count: ''})
    expect(errors).toEqual({
      grader_count: [
        {
          message: 'Must have at least one grader',
        },
      ],
    })
  })

  it('returns an error if moderated grading is turned on and grader count is 0', () => {
    const view = createEditView()
    const errors = view.validateGraderCount({moderated_grading: 'on', grader_count: 0})
    expect(errors).toEqual({
      grader_count: [
        {
          message: 'Must have at least one grader',
        },
      ],
    })
  })

  it('returns an error if moderated grading is turned on and grader count exceeds max', () => {
    ENV.MODERATED_GRADING_GRADER_LIMIT = 2
    const view = createEditView()
    const errors = view.validateGraderCount({moderated_grading: 'on', grader_count: '3'})
    expect(errors).toEqual({
      grader_count: [
        {
          message: 'Only a maximum of 2 graders can be assigned',
        },
      ],
    })
  })

  it('returns an error if moderated grading is turned on and grader count exceeds max grader count', () => {
    ENV.MODERATED_GRADING_MAX_GRADER_COUNT = 2
    const view = createEditView()
    const errors = view.validateGraderCount({moderated_grading: 'on', grader_count: '5'})
    expect(errors).toEqual({
      grader_count: [
        {
          message: 'Only a maximum of 2 graders can be assigned',
        },
      ],
    })
  })
})

describe('EditView#renderModeratedGradingFormFieldGroup', () => {
  let view
  let props

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)

    fixtures.innerHTML = `
      <div id="assignment_moderated_grading_fields">
        <input type="checkbox" id="assignment_moderated_grading" />
        <input type="number" id="grader_count" />
        <select id="final_grader_id"></select>
        <input type="checkbox" id="grader_comments_visible_to_graders" />
        <input type="checkbox" id="grader_names_visible_to_final_grader" />
      </div>
      <div data-component="ModeratedGradingFormFieldGroup"></div>
    `

    setupFakeEnv({
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_GRADER_LIMIT: 2,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      AVAILABLE_MODERATORS: [],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
    })

    view = createEditView({
      moderated_grading: true,
      grader_count: 2,
      final_grader_id: '1',
      grader_comments_visible_to_graders: true,
      grader_names_visible_to_final_grader: true,
    })

    jest.spyOn(React, 'createElement')
  })

  afterEach(() => {
    document.body.removeChild(fixtures)
    jest.clearAllMocks()
  })

  it('renders the moderated grading form field group when Moderated Grading is enabled', () => {
    view.renderModeratedGradingFormFieldGroup()
    const calls = React.createElement.mock.calls
    const moderatedGradingFormFieldGroupCall = calls.find(
      call => call[1] && call[1].moderatedGradingEnabled !== undefined,
    )
    expect(moderatedGradingFormFieldGroupCall[1]).toMatchObject({
      moderatedGradingEnabled: true,
      availableModerators: [],
      currentGraderCount: 2,
      finalGraderID: '1',
      graderCommentsVisibleToGraders: true,
      graderNamesVisibleToFinalGrader: true,
      locale: 'en',
      availableGradersCount: 2,
      gradedSubmissionsExist: false,
      isGroupAssignment: false,
      isPeerReviewAssignment: false,
      onGraderCommentsVisibleToGradersChange: expect.any(Function),
      onModeratedGradingChange: expect.any(Function),
    })
  })

  it('does not render the moderated grading form field group when Moderated Grading is disabled', () => {
    setupFakeEnv({
      MODERATED_GRADING_ENABLED: false,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
    })
    view = createEditView({moderated_grading: false})
    view.renderModeratedGradingFormFieldGroup()
    const calls = React.createElement.mock.calls
    const moderatedGradingFormFieldGroupCall = calls.find(
      call => call[1] && call[1].moderatedGradingEnabled !== undefined,
    )
    expect(moderatedGradingFormFieldGroupCall).toBeUndefined()
  })

  describe('props passed to the component', () => {
    beforeEach(() => {
      view.renderModeratedGradingFormFieldGroup()
      const calls = React.createElement.mock.calls
      const moderatedGradingFormFieldGroupCall = calls.find(
        call => call[1] && call[1].moderatedGradingEnabled !== undefined,
      )
      props = moderatedGradingFormFieldGroupCall[1]
    })

    it('passes the final_grader_id as a prop to the component', () => {
      expect(props.finalGraderID).toBe('1')
    })

    it('passes moderated_grading as a prop to the component', () => {
      expect(props.moderatedGradingEnabled).toBe(true)
    })

    it('passes available moderators in the ENV as a prop to the component', () => {
      expect(props.availableModerators).toEqual([])
    })

    it('passes available graders count in the ENV as a prop to the component', () => {
      expect(props.availableGradersCount).toBe(2)
    })

    it('passes locale in the ENV as a prop to the component', () => {
      expect(props.locale).toBe('en')
    })

    it('passes HAS_GRADED_SUBMISSIONS in the ENV as a prop to the component', () => {
      expect(props.gradedSubmissionsExist).toBe(false)
    })

    it('passes current grader count as a prop to the component', () => {
      expect(props.currentGraderCount).toBe(2)
    })

    it('passes grader_comments_visible_to_graders as a prop to the component', () => {
      expect(props.graderCommentsVisibleToGraders).toBe(true)
    })

    it('passes grader_names_visible_to_final_grader as a prop to the component', () => {
      expect(props.graderNamesVisibleToFinalGrader).toBe(true)
    })

    it('passes peer_reviews as a prop to the component', () => {
      expect(props.isPeerReviewAssignment).toBe(false)
    })

    it('passes has_group_category as a prop to the component', () => {
      expect(props.isGroupAssignment).toBe(false)
    })

    it('passes handleGraderCommentsVisibleToGradersChanged as a prop to the component', () => {
      expect(typeof props.onGraderCommentsVisibleToGradersChange).toBe('function')
    })

    it('passes handleModeratedGradingChanged as a prop to the component', () => {
      expect(typeof props.onModeratedGradingChange).toBe('function')
    })
  })
})

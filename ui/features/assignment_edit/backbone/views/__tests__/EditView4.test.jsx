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
import RCELoader from '@canvas/rce/serviceRCELoader'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import Section from '@canvas/sections/backbone/models/Section'
import userSettings from '@canvas/user-settings'
import React from 'react'
import EditView from '../EditView'
import '@canvas/jquery/jquery.simulate'
import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'
import fetchMock from 'fetch-mock'
// ReactDOM might be required for dynamic rendering in certain scenarios.
import ReactDOM from 'react-dom'
import {waitFor} from '@testing-library/react'
import {createRoot} from 'react-dom/client'

jest.mock('jquery-ui', () => {
  const $ = require('jquery')
  $.widget = jest.fn()
  $.ui = {
    mouse: {
      _mouseInit: jest.fn(),
      _mouseDestroy: jest.fn(),
    },
    sortable: jest.fn(),
  }
  return $
})

jest.mock('../../../react/AssetProcessors', () => ({
  attach: ({container, initialAttachedProcessors, courseId, secureParams}) => {
    const initialJson = JSON.stringify(initialAttachedProcessors)
    const el = (
      <div>
        AssetProcessors initialAttachedProcessors={initialJson} courseId={courseId} secureParams=
        {secureParams}
      </div>
    )
    createRoot(container).render(el)
  },
}))

const s_params = 'some super secure params'
const currentOrigin = window.location.origin

// Mock RCE initialization
EditView.prototype._attachEditorToDescription = () => {}

const createEditView = (assignmentOpts = {}) => {
  const defaultAssignmentOpts = {
    name: 'Test Assignment',
    secure_params: s_params,
    assignment_overrides: [],
  }
  const mergedOpts = {...defaultAssignmentOpts, ...assignmentOpts}
  const assignment = new Assignment(mergedOpts)

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

describe('EditView', () => {
  let fixtures

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = `
      <span data-component="ModeratedGradingFormFieldGroup"></span>
      <input id="annotatable_attachment_id" type="hidden" />
      <div id="annotated_document_usage_rights_container"></div>
    `

    window.ENV = {
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
      PERMISSIONS: {
        can_edit_grades: true,
      },
      context_asset_string: 'course_1',
      SETTINGS: {},
    }

    fetchMock.get('/api/v1/courses/1/settings', {})
    fetchMock.get('/api/v1/courses/1/sections?per_page=100', [])
    fetchMock.get(/\/api\/v1\/courses\/\d+\/lti_apps\/launch_definitions*/, [])
    fetchMock.post(/.*\/api\/graphql/, {})
    RCELoader.RCE = null
    return RCELoader.loadRCE()
  })

  afterEach(() => {
    document.body.removeChild(fixtures)
    $('.ui-dialog').remove()
    $('ul[id^=ui-id-]').remove()
    $('.form-dialog').remove()
    fetchMock.reset()
    jest.resetModules()
    window.ENV = null
  })

  describe('Peer Reviews', () => {
    it('does not appear when reviews are being assigned manually', () => {
      jest.spyOn(userSettings, 'contextGet').mockReturnValue({
        peer_reviews: '1',
        group_category_id: 1,
      })
      const view = createEditView()
      view.$el.appendTo($('#fixtures'))
      expect(view.$('#intra_group_peer_reviews').is(':visible')).toBeFalsy()
    })

    it('toggle does not appear when there is no group', () => {
      jest.spyOn(userSettings, 'contextGet').mockReturnValue({peer_reviews: '1'})
      const view = createEditView()
      view.$el.appendTo($('#fixtures'))
      expect(view.$('#intra_group_peer_reviews').is(':visible')).toBeFalsy()
    })
  })

  describe('Assignment Configuration Tools', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
      window.ENV = {
        AVAILABLE_MODERATORS: [],
        current_user_roles: ['teacher'],
        HAS_GRADED_SUBMISSIONS: false,
        LOCALE: 'en',
        MODERATED_GRADING_ENABLED: true,
        MODERATED_GRADING_MAX_GRADER_COUNT: 2,
        PLAGIARISM_DETECTION_PLATFORM: true,
        VALID_DATE_RANGE: {},
        COURSE_ID: 1,
        PERMISSIONS: {
          can_edit_grades: true,
        },
        context_asset_string: 'course_1',
        SETTINGS: {},
      }
    })

    it('attaches assignment configuration component', () => {
      const view = createEditView()
      expect(view.$similarityDetectionTools.children()).toHaveLength(1)
    })

    it('is hidden if submission type is not online with a file upload', () => {
      const view = createEditView()
      view.$el.appendTo($('#fixtures'))
      expect(view.$('#similarity_detection_tools').css('display')).toBe('none')

      view.$('#assignment_submission_type').val('on_paper')
      view.handleSubmissionTypeChange()
      expect(view.$('#similarity_detection_tools').css('display')).toBe('none')

      view.$('#assignment_submission_type').val('external_tool')
      view.handleSubmissionTypeChange()
      expect(view.$('#similarity_detection_tools').css('display')).toBe('none')

      view.$('#assignment_submission_type').val('online')
      view.$('#assignment_online_upload').prop('checked', false)
      view.handleSubmissionTypeChange()
      expect(view.$('#similarity_detection_tools').css('display')).toBe('none')

      view.$('#assignment_submission_type').val('online')
      view.$('#assignment_online_upload').prop('checked', true)
      view.handleSubmissionTypeChange()
      expect(view.$('#similarity_detection_tools').css('display')).toBe('block')

      view.$('#assignment_submission_type').val('online')
      view.$('#assignment_text_entry').prop('checked', false)
      view.$('#assignment_online_upload').prop('checked', false)
      view.handleSubmissionTypeChange()
      expect(view.$('#similarity_detection_tools').css('display')).toBe('none')

      view.$('#assignment_submission_type').val('online')
      view.$('#assignment_text_entry').prop('checked', true)
      view.handleSubmissionTypeChange()
      expect(view.$('#similarity_detection_tools').css('display')).toBe('block')
    })

    it('is hidden if the plagiarism_detection_platform flag is disabled', () => {
      window.ENV.PLAGIARISM_DETECTION_PLATFORM = false
      const view = createEditView()
      view.$('#assignment_submission_type').val('online')
      view.$('#assignment_online_upload').prop('checked', true)
      view.handleSubmissionTypeChange()
      expect(view.$('#similarity_detection_tools').css('display')).toBe('none')
    })
  })

  describe('Assignment External Tools', () => {
    beforeEach(() => {
      window.ENV.COURSE_ID = 1
    })

    it('attaches assignment external tools component', () => {
      const view = createEditView()
      expect(view.$assignmentExternalTools.children()).toHaveLength(1)
    })

    it('submission_type_selection modal opens on tool click', () => {
      window.ENV.context_asset_string = 'course_1'
      window.ENV.PERMISSIONS = {can_edit_grades: true}

      const view = createEditView()
      view.$el.appendTo($('#fixtures'))

      const createElementSpy = jest.spyOn(React, 'createElement')

      view.selectedTool = {
        id: '1',
        selection_width: '100%',
        selection_height: '400',
        title: 'test',
      }
      view.handleSubmissionTypeSelectionLaunch()

      expect(createElementSpy).toHaveBeenCalledWith(
        ExternalToolModalLauncher,
        expect.objectContaining({isOpen: true}),
      )
      createElementSpy.mockRestore()
    })

    it('submission_type_selection modal closes on deep link postMessage', () => {
      window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = window.origin
      window.ENV.context_asset_string = 'course_1'
      window.ENV.PERMISSIONS = {can_edit_grades: true}

      const view = createEditView()
      view.$el.appendTo($('#fixtures'))

      const message = {
        messageType: 'LtiDeepLinkingResponse',
        content_items: [
          {
            type: 'ltiResourceLink',
            url: 'http://example.com/launch-url',
          },
        ],
      }

      window.postMessage(message, window.origin)

      expect(view.$el).toBeTruthy()
    })
  })

  describe('Asset Processors', () => {
    function createEditViewOnlineSubmission({textEntry, onlineUpload, onlineUrl} = {}) {
      const view = createEditView()
      view.$('#assignment_submission_type').val('online')
      view.$('#assignment_online_upload').prop('checked', !!onlineUpload)
      view.$('#assignment_text_entry').prop('checked', !!textEntry)
      view.$('#assignment_online_url').prop('checked', !!onlineUrl)
      view.handleSubmissionTypeChange()
      return view
    }

    it('attaches AssetProcessors component when FF is on', async () => {
      window.ENV.FEATURES = {lti_asset_processor: true}
      const view = createEditViewOnlineSubmission({onlineUpload: true})
      await waitFor(() => {
        expect(view.$assetProcessorsContainer.children()).toHaveLength(1)
      })
      await waitFor(() => {
        expect(view.$assetProcessorsContainer.text()).toBe(
          'AssetProcessors initialAttachedProcessors=[] courseId=1 secureParams=some super secure params',
        )
      })
    })

    it('contains the correct initialAttachedProcessors', async () => {
      window.ENV.FEATURES = {lti_asset_processor: true}
      window.ENV.ASSET_PROCESSORS = [{id: 1}] // rest of the fields omitted here for brevity
      const view = createEditViewOnlineSubmission({onlineUpload: true})
      await waitFor(() => {
        expect(view.$assetProcessorsContainer.text()).toBe(
          'AssetProcessors initialAttachedProcessors=[{"id":1}] courseId=1 secureParams=some super secure params',
        )
      })
    })

    it('does not attach AssetProcessors component when FF is off', async () => {
      window.ENV.FEATURES = {lti_asset_processor: false}
      const view = createEditViewOnlineSubmission({onlineUpload: true})
      await waitFor(() => {
        expect(view.$assetProcessorsContainer.children()).toHaveLength(0)
      })
      // Ensure no children are added after the initial render
      await new Promise(resolve => setTimeout(resolve, 100))
      expect(view.$assetProcessorsContainer.children()).toHaveLength(0)
    })

    it('is hidden if submission type does not include online with a file upload', () => {
      window.ENV.FEATURES = {lti_asset_processor: true}
      let view = createEditViewOnlineSubmission({onlineUpload: true})
      expect(view.$assetProcessorsContainer.css('display')).toBe('block')

      view = createEditViewOnlineSubmission({onlineTextEntry: true, onlineUrl: true})
      expect(view.$assetProcessorsContainer.css('display')).toBe('none')
    })
  })

  describe('Description field', () => {
    it('does not show the description textarea', () => {
      const view = createEditView({
        is_quiz_lti_assignment: true,
        submission_types: ['external_tool'],
      })
      view.$el.appendTo($('#fixtures'))
      view.render()
      expect(view.$el.find('#assignment_description')).toHaveLength(0)
    })
  })

  // These started failing in master after Jan 1, 2025
  // cf. EGG-444
  describe.skip('Quizzes 2', () => {
    beforeEach(() => {
      window.ENV = {
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
        context_asset_string: 'course_1',
        NEW_QUIZZES_ASSIGNMENT_BUILD_BUTTON_ENABLED: true,
        HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED: true,
        CANCEL_TO: currentOrigin + '/cancel',
      }
    })

    let view

    beforeEach(() => {
      view = createEditView({
        html_url: 'http://foo',
        submission_types: ['external_tool'],
        is_quiz_lti_assignment: true,
        frozen_attributes: ['submission_types'],
        points_possible: '10',
      })
    })

    afterEach(() => {
      document.getElementById('fixtures').innerHTML = ''
      window.ENV = null
    })

    it('does not show the description textarea', () => {
      expect(view.$description).toHaveLength(0)
    })

    it('does not show the moderated grading checkbox', () => {
      expect(document.getElementById('assignment_moderated_grading')).toBeNull()
    })

    it('does not show the load in new tab checkbox', () => {
      expect(view.$externalToolsNewTab).toHaveLength(0)
    })

    it('shows the build button', () => {
      expect(view.$el.find('button.build_button')).toHaveLength(1)
    })

    it('does not show the "hide_zero_point_quiz" checkbox when "hide_zero_point_quizzes_option" FF is disabled', () => {
      window.ENV.HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED = false
      view = createEditView({
        html_url: 'http://foo',
        submission_types: ['external_tool'],
        is_quiz_lti_assignment: true,
        frozen_attributes: ['submission_types'],
      })

      expect(view.$hideZeroPointQuizzesBox).toHaveLength(0)
    })

    it('shows the "hide_zero_point_quiz" checkbox when points possible is 0', () => {
      view.$assignmentPointsPossible.val(0)
      view.$assignmentPointsPossible.trigger('change')
      expect(view.$hideZeroPointQuizzesOption).toHaveLength(1)
    })

    it('does not show the "hide_zero_point_quiz" checkbox when points possible is not 0', () => {
      view.$assignmentPointsPossible.val(10)
      view.$assignmentPointsPossible.trigger('change')
      expect(view.$hideZeroPointQuizzesOption).toHaveLength(1)
      expect(view.$hideZeroPointQuizzesOption.css('display')).toBe('none')
    })

    it('disables and checks "omit_from_final_grade" checkbox when "hide_zero_point_quiz" checkbox is checked', () => {
      view.$hideZeroPointQuizzesBox.prop('checked', true)
      view.$hideZeroPointQuizzesBox.trigger('change')
      expect(view.$omitFromFinalGradeBox.prop('disabled')).toBe(true)
      expect(view.$omitFromFinalGradeBox.prop('checked')).toBe(true)
    })

    it('enables and keeps "omit_from_final_grade" checkbox checked when "hide_zero_point_quiz" checkbox is unchecked', () => {
      view.$hideZeroPointQuizzesBox.prop('checked', true)
      view.$hideZeroPointQuizzesBox.trigger('change')
      view.$hideZeroPointQuizzesBox.prop('checked', false)
      view.$hideZeroPointQuizzesBox.trigger('change')
      expect(view.$omitFromFinalGradeBox.prop('disabled')).toBe(false)
      expect(view.$omitFromFinalGradeBox.prop('checked')).toBe(true)
    })

    it('enables and keeps "omit_from_final_grade" checkbox checked when "hide_zero_point_quiz" checkbox is hidden', () => {
      view.$hideZeroPointQuizzesBox.prop('checked', true)
      view.$hideZeroPointQuizzesBox.trigger('change')
      view.$assignmentPointsPossible.val(10)
      view.$assignmentPointsPossible.trigger('change')
      expect(view.$omitFromFinalGradeBox.prop('disabled')).toBe(false)
      expect(view.$omitFromFinalGradeBox.prop('checked')).toBe(true)
    })

    it('displays reason for disabling "omit_from_final_grade" checkbox', () => {
      view.$hideZeroPointQuizzesBox.prop('checked', true)
      view.$hideZeroPointQuizzesBox.trigger('change')
      expect(view.$('.accessible_label').text()).toBe(
        'This is enabled by default as assignments can not be withheld from the gradebook and still count towards it.',
      )
    })

    it('save routes to cancelLocation', () => {
      view.preventBuildNavigation = true
      expect(view.locationAfterSave({})).toBe(currentOrigin + '/cancel')
    })

    it('build adds full_width display param to normal route', () => {
      expect(view.locationAfterSave({})).toBe('http://foo?display=full_width')
    })

    it('does not allow user to change submission type', () => {
      expect(view.$('#assignment_submission_type').prop('disabled')).toBe(true)
    })

    it('does not allow user to change external tool url', () => {
      expect(view.$('#assignment_external_tool_tag_attributes_url').prop('disabled')).toBe(true)
    })

    it('does not allow user to choose a new external tool', () => {
      expect(view.$('#assignment_external_tool_tag_attributes_url_find').prop('disabled')).toBe(
        true,
      )
    })
  })

  describe('Quiz LTI Assignment', () => {
    beforeEach(() => {
      window.ENV.PERMISSIONS = {can_edit_grades: true}
    })

    it('does not show the description textarea', () => {
      const view = createEditView({
        is_quiz_lti_assignment: true,
        submission_types: ['external_tool'],
      })
      view.$el.appendTo($('#fixtures'))
      expect(view.$el.find('#assignment_description')).toHaveLength(0)
    })
  })
})

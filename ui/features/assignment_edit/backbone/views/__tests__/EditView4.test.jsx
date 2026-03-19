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
import {createRoot} from 'react-dom/client'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {getUrlWithHorizonParams} from '@canvas/horizon/utils'
import {SETTING_MESSAGES} from '@canvas/assignments/react/hooks/useSettingDependency'
import fakeEnv from '@canvas/test-utils/fakeENV'

// Mock the horizon utils module
vi.mock('@canvas/horizon/utils', () => ({
  getUrlWithHorizonParams: vi.fn(),
}))

vi.mock('jquery-ui', () => {
  const $ = require('jquery')
  $.widget = vi.fn()
  $.ui = {
    mouse: {
      _mouseInit: vi.fn(),
      _mouseDestroy: vi.fn(),
    },
    sortable: vi.fn(),
  }
  return $
})

vi.mock('../../../react/AssetProcessorsForAssignment', () => {
  const rootMap = new WeakMap()
  return {
    attach: ({container, initialAttachedProcessors, courseId, secureParams}) => {
      const initialJson = JSON.stringify(initialAttachedProcessors)
      const el = (
        <div>
          AssetProcessorsForAssignment initialAttachedProcessors={initialJson} courseId={courseId}{' '}
          secureParams=
          {secureParams}
        </div>
      )

      // Reuse existing root or create new one
      let root = rootMap.get(container)
      if (!root) {
        root = createRoot(container)
        rootMap.set(container, root)
      }
      root.render(el)
    },
  }
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
  http.get('/api/v1/courses/1/settings', () => {
    return HttpResponse.json({})
  }),
  http.get(/\/api\/v1\/courses\/\d+\/settings/, () => {
    return HttpResponse.json({})
  }),
  http.get('/api/v1/courses/1/sections', () => {
    return HttpResponse.json([])
  }),
  http.get(/\/api\/v1\/courses\/\d+\/sections/, () => {
    return HttpResponse.json([])
  }),
  // Mock GraphQL endpoint
  http.post(/.*\/api\/graphql/, () => {
    return HttpResponse.json({})
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

// Clean up after all tests
afterAll(() => {
  server.close()
})

const s_params = 'some super secure params'

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

describe('EditView - Peer Reviews and Configuration Tools', () => {
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

    fakeEnv.setup({
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
      FEATURES: {},
      IN_PACED_COURSE: false,
      DEEP_LINKING_POST_MESSAGE_ORIGIN: window.origin,
    })

    // Setup default mock for getUrlWithHorizonParams
    vi.mocked(getUrlWithHorizonParams).mockImplementation((url, additionalParams) => {
      if (additionalParams && Object.keys(additionalParams).length > 0) {
        const separator = url.includes('?') ? '&' : '?'
        const params = new URLSearchParams(additionalParams).toString()
        return `${url}${separator}${params}`
      }
      return url
    })

    RCELoader.RCE = null
    return RCELoader.loadRCE()
  })

  afterEach(() => {
    document.body.removeChild(fixtures)
    $('.ui-dialog').remove()
    $('ul[id^=ui-id-]').remove()
    $('.form-dialog').remove()
    server.resetHandlers()
    vi.resetModules()
    vi.clearAllMocks()
    fakeEnv.teardown()
  })

  describe('Peer Reviews', () => {
    it('does not appear when reviews are being assigned manually', () => {
      vi.spyOn(userSettings, 'contextGet').mockReturnValue({
        peer_reviews: '1',
        group_category_id: 1,
      })
      const view = createEditView()
      view.$el.appendTo($('#fixtures'))
      expect(view.$('#intra_group_peer_reviews').is(':visible')).toBeFalsy()
    })

    it('toggle does not appear when there is no group', () => {
      vi.spyOn(userSettings, 'contextGet').mockReturnValue({peer_reviews: '1'})
      const view = createEditView()
      view.$el.appendTo($('#fixtures'))
      expect(view.$('#intra_group_peer_reviews').is(':visible')).toBeFalsy()
    })

    it('does not send re-enable postMessage from handleSubmissionTypeChange when feature flag is off', () => {
      window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = false
      const view = createEditView()
      view.$el.appendTo($('#fixtures'))

      const postMessageSpy = vi.spyOn(window.top, 'postMessage')
      view.$submissionType.val('online')
      view.handleSubmissionTypeChange()

      const calls = postMessageSpy.mock.calls.filter(
        call =>
          call[0]?.subject === SETTING_MESSAGES.TOGGLE_PEER_REVIEWS && call[0]?.enabled === true,
      )
      expect(calls).toHaveLength(0)
      postMessageSpy.mockRestore()
    })

    it('sends re-enable postMessage from handleSubmissionTypeChange when feature flag is on', () => {
      window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = true
      const view = createEditView()
      view.$el.appendTo($('#fixtures'))

      const postMessageSpy = vi.spyOn(window.top, 'postMessage')
      view.$submissionType.val('online')
      view.$('#assignment_grading_type').val('points')
      view.handleSubmissionTypeChange()

      expect(postMessageSpy).toHaveBeenCalledWith(
        {subject: SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, enabled: true},
        '*',
      )
      postMessageSpy.mockRestore()
    })
  })

  describe('External Tool and Peer Review Helpers', () => {
    describe('#isExternalToolSubmissionType', () => {
      it('returns true when submission type is external_tool', () => {
        const view = createEditView()
        view.$el.appendTo($('#fixtures'))
        view.$submissionType.val('external_tool')
        expect(view.isExternalToolSubmissionType()).toBe(true)
      })

      it('returns false when submission type is online', () => {
        const view = createEditView()
        view.$el.appendTo($('#fixtures'))
        view.$submissionType.val('online')
        expect(view.isExternalToolSubmissionType()).toBe(false)
      })
    })

    describe('#canEnablePeerReviews', () => {
      it('returns false when moderated grading is enabled', () => {
        const view = createEditView({moderated_grading: true})
        view.$el.appendTo($('#fixtures'))
        view.$('#assignment_grading_type').val('points')
        view.$submissionType.val('online')
        expect(view.canEnablePeerReviews()).toBe(false)
      })

      it('returns false when grading type is not_graded', () => {
        const view = createEditView()
        view.$el.appendTo($('#fixtures'))
        view.$('#assignment_grading_type').val('not_graded')
        view.$submissionType.val('online')
        expect(view.canEnablePeerReviews()).toBe(false)
      })

      it('returns false when submission type is external_tool', () => {
        const view = createEditView()
        view.$el.appendTo($('#fixtures'))
        view.$('#assignment_grading_type').val('points')
        view.$submissionType.val('external_tool')
        expect(view.canEnablePeerReviews()).toBe(false)
      })

      it('returns true when none of the blocking conditions are met', () => {
        const view = createEditView()
        view.$el.appendTo($('#fixtures'))
        view.$('#assignment_grading_type').val('points')
        view.$submissionType.val('online')
        expect(view.canEnablePeerReviews()).toBe(true)
      })
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
})

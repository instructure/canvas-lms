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
import React from 'react'
import EditView from '../EditView'
import '@canvas/jquery/jquery.simulate'
import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'
import fetchMock from 'fetch-mock'
import {waitFor} from '@testing-library/react'
import {createRoot} from 'react-dom/client'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {getUrlWithHorizonParams} from '@canvas/horizon/utils'
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

describe('EditView - External Tools and Asset Processors', () => {
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

    fetchMock.get('/api/v1/courses/1/settings', {})
    fetchMock.get('/api/v1/courses/1/sections?per_page=100', [])
    fetchMock.get(/\/api\/v1\/courses\/\d+\/lti_apps\/launch_definitions*/, [])
    fetchMock.post(/.*\/api\/graphql/, {})
    // Catch-all for any unmocked requests to prevent XMLHttpRequest errors
    fetchMock.get('*', {status: 404})
    fetchMock.post('*', {status: 404})
    fetchMock.put('*', {status: 404})
    fetchMock.delete('*', {status: 404})
    RCELoader.RCE = null
    return RCELoader.loadRCE()
  })

  afterEach(() => {
    document.body.removeChild(fixtures)
    $('.ui-dialog').remove()
    $('ul[id^=ui-id-]').remove()
    $('.form-dialog').remove()
    fetchMock.reset()
    server.resetHandlers()
    vi.resetModules()
    vi.clearAllMocks()
    fakeEnv.teardown()
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

      const createElementSpy = vi.spyOn(React, 'createElement')

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
      window.ENV.FEATURES = {lti_asset_processor: true, lti_asset_processor_course: true}
      const view = createEditViewOnlineSubmission({onlineUpload: true})
      view.afterRender()
      await waitFor(() => {
        expect(view.$assetProcessorsContainer.children()).toHaveLength(1)
      })
      await waitFor(() => {
        expect(view.$assetProcessorsContainer.text()).toBe(
          'AssetProcessorsForAssignment initialAttachedProcessors=[] courseId=1 secureParams=some super secure params',
        )
      })
    })

    it('contains the correct initialAttachedProcessors', async () => {
      window.ENV.FEATURES = {lti_asset_processor: true, lti_asset_processor_course: true}
      window.ENV.ASSET_PROCESSORS = [{id: 1}] // rest of the fields omitted here for brevity
      const view = createEditViewOnlineSubmission({onlineUpload: true})
      view.afterRender()
      await waitFor(() => {
        expect(view.$assetProcessorsContainer.text()).toBe(
          'AssetProcessorsForAssignment initialAttachedProcessors=[{"id":1}] courseId=1 secureParams=some super secure params',
        )
      })
    })

    it('does not attach AssetProcessors component when FF is off', async () => {
      window.ENV.FEATURES = {lti_asset_processor: false}
      const view = createEditViewOnlineSubmission({onlineUpload: true})
      view.afterRender()
      expect(view.$assetProcessorsContainer.children()).toHaveLength(0)
    })

    it('does not attach AssetProcessors component when lti_asset_processor is on but lti_asset_processor_course is off', async () => {
      window.ENV.FEATURES = {lti_asset_processor: true, lti_asset_processor_course: false}
      const view = createEditViewOnlineSubmission({onlineUpload: true})
      view.afterRender()
      expect(view.$assetProcessorsContainer.children()).toHaveLength(0)
    })

    it('is hidden if submission type does not include online with a file upload', () => {
      window.ENV.FEATURES = {lti_asset_processor: true, lti_asset_processor_course: true}
      let view = createEditViewOnlineSubmission({onlineUpload: true})
      view.afterRender()
      expect(view.$assetProcessorsContainer.css('display')).toBe('block')

      view = createEditViewOnlineSubmission({onlineTextEntry: true, onlineUrl: true})
      view.afterRender()
      expect(view.$assetProcessorsContainer.css('display')).toBe('none')
    })
  })
})

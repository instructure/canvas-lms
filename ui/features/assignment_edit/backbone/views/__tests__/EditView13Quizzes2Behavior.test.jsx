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
import fetchMock from 'fetch-mock'
import {createRoot} from 'react-dom/client'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {getUrlWithHorizonParams} from '@canvas/horizon/utils'

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

      let root = rootMap.get(container)
      if (!root) {
        root = createRoot(container)
        rootMap.set(container, root)
      }
      root.render(el)
    },
  }
})

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

afterAll(() => {
  server.close()
})

const s_params = 'some super secure params'
const currentOrigin = window.location.origin

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

describe('EditView - Quizzes 2 Behavior', () => {
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
      COURSE_ID: 1,
      PERMISSIONS: {
        can_edit_grades: true,
      },
      context_asset_string: 'course_1',
      NEW_QUIZZES_ASSIGNMENT_BUILD_BUTTON_ENABLED: true,
      HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED: true,
      CANCEL_TO: currentOrigin + '/cancel',
      SETTINGS: {},
      FEATURES: {},
    }

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
    window.ENV = null
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
})

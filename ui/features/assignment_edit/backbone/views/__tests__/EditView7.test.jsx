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

const s_params = 'some super secure params'

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

  return app
}

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

describe('EditView#handleModeratedGradingChanged', () => {
  let view

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="fixtures">
        <div data-component="ModeratedGradingFormFieldGroup"></div>
        <div id="editor_tabs"></div>
        <div id="annotated_document_chooser_container"></div>
        <div id="assignment_annotated_document_info" style="display: none;"></div>
        <input type="checkbox" id="assignment_annotated_document" />
        <input type="hidden" id="annotatable_attachment_input" value="" />
        <div id="annotated_document_usage_rights_container"></div>
        <div id="assignment_graded_assignment_fields"></div>
        <div id="assignment_external_tools"></div>
        <div id="assignment_peer_reviews_fields"></div>
        <div id="assignment_group_selector"></div>
        <div id="grading_type_selector"></div>
        <fieldset id="submission_type_fields"></fieldset>
        <div id="quiz_type_selector"></div>
        <div id="anonymous_submission_selector"></div>
        <div id="group_category_selector"></div>
        <input type="checkbox" id="assignment_graders_anonymous_to_graders" />
        <label for="assignment_graders_anonymous_to_graders" style="display: none;">Graders Anonymous to Graders</label>
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
      PERMISSIONS: {
        can_edit_grades: true,
      },
      SETTINGS: {
        suppress_assignments: false,
      },
      context_asset_string: 'course_1',
      ASSIGNMENT_GROUPS: [],
      GROUP_CATEGORIES: [],
      USAGE_RIGHTS_REQUIRED: false,
      ROOT_FOLDER_ID: '1',
    })

    view = createEditView()
    view.$el.appendTo($('#fixtures'))
    view.render()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('sets the moderated grading attribute on the assignment', () => {
    view.handleModeratedGradingChanged(true)
    expect(view.assignment.moderatedGrading()).toBe(true)
  })
})

describe('EditView#handleGraderCommentsVisibleToGradersChanged', () => {
  let view

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="fixtures">
        <div data-component="ModeratedGradingFormFieldGroup"></div>
        <div id="editor_tabs"></div>
        <div id="annotated_document_chooser_container"></div>
        <div id="assignment_annotated_document_info" style="display: none;"></div>
        <input type="checkbox" id="assignment_annotated_document" />
        <input type="hidden" id="annotatable_attachment_input" value="" />
        <div id="annotated_document_usage_rights_container"></div>
        <div id="assignment_graded_assignment_fields"></div>
        <div id="assignment_external_tools"></div>
        <div id="assignment_peer_reviews_fields"></div>
        <div id="assignment_group_selector"></div>
        <div id="grading_type_selector"></div>
        <fieldset id="submission_type_fields"></fieldset>
        <div id="quiz_type_selector"></div>
        <div id="anonymous_submission_selector"></div>
        <div id="group_category_selector"></div>
        <input type="checkbox" id="assignment_graders_anonymous_to_graders" />
        <label for="assignment_graders_anonymous_to_graders" style="display: none;">Graders Anonymous to Graders</label>
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
      PERMISSIONS: {
        can_edit_grades: true,
      },
      SETTINGS: {
        suppress_assignments: false,
      },
      context_asset_string: 'course_1',
      ASSIGNMENT_GROUPS: [],
      GROUP_CATEGORIES: [],
      USAGE_RIGHTS_REQUIRED: false,
      ROOT_FOLDER_ID: '1',
    })

    view = createEditView()
    view.$el.appendTo($('#fixtures'))
    view.render()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('sets the graderCommentsVisibleToGraders attribute on the assignment', () => {
    view.handleGraderCommentsVisibleToGradersChanged(true)
    expect(view.assignment.graderCommentsVisibleToGraders()).toBe(true)
  })

  it('reveals the "Graders Anonymous to Graders" option when passed true', () => {
    view.handleGraderCommentsVisibleToGradersChanged(true)
    const label = document.querySelector('label[for="assignment_graders_anonymous_to_graders"]')
    expect(label.style.display).not.toBe('none')
  })

  it('calls uncheckAndHideGraderAnonymousToGraders when passed false', () => {
    const uncheckSpy = vi.spyOn(view, 'uncheckAndHideGraderAnonymousToGraders')
    view.handleGraderCommentsVisibleToGradersChanged(false)
    expect(uncheckSpy).toHaveBeenCalledTimes(1)
  })
})

describe('EditView#uncheckAndHideGraderAnonymousToGraders', () => {
  let view

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="fixtures">
        <div data-component="ModeratedGradingFormFieldGroup"></div>
        <div id="editor_tabs"></div>
        <div id="annotated_document_chooser_container"></div>
        <div id="assignment_annotated_document_info" style="display: none;"></div>
        <input type="checkbox" id="assignment_annotated_document" />
        <input type="hidden" id="annotatable_attachment_input" value="" />
        <div id="annotated_document_usage_rights_container"></div>
        <div id="assignment_graded_assignment_fields"></div>
        <div id="assignment_external_tools"></div>
        <div id="assignment_peer_reviews_fields"></div>
        <div id="assignment_group_selector"></div>
        <div id="grading_type_selector"></div>
        <fieldset id="submission_type_fields"></fieldset>
        <div id="quiz_type_selector"></div>
        <div id="anonymous_submission_selector"></div>
        <div id="group_category_selector"></div>
        <input type="checkbox" id="assignment_graders_anonymous_to_graders" />
        <label for="assignment_graders_anonymous_to_graders" style="display: none;">Graders Anonymous to Graders</label>
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
      PERMISSIONS: {
        can_edit_grades: true,
      },
      SETTINGS: {
        suppress_assignments: false,
      },
      context_asset_string: 'course_1',
      ASSIGNMENT_GROUPS: [],
      GROUP_CATEGORIES: [],
      USAGE_RIGHTS_REQUIRED: false,
      ROOT_FOLDER_ID: '1',
    })

    view = createEditView({
      moderated_grading: true,
      grader_comments_visible_to_graders: true,
      grader_anonymous_to_graders: true,
    })
    view.$el.appendTo($('#fixtures'))
    view.render()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('unchecks the graders anonymous to graders checkbox', () => {
    const checkbox = document.getElementById('assignment_graders_anonymous_to_graders')
    checkbox.checked = true
    view.uncheckAndHideGraderAnonymousToGraders()
    expect(checkbox.checked).toBe(false)
  })

  it('hides the graders anonymous to graders checkbox label', () => {
    const label = document.querySelector('label[for="assignment_graders_anonymous_to_graders"]')
    label.style.display = 'block'
    view.uncheckAndHideGraderAnonymousToGraders()
    expect(label.style.display).toBe('none')
  })

  it('sets the graderAnonymousToGraders attribute to false on the assignment', () => {
    view.assignment.gradersAnonymousToGraders(true)
    view.uncheckAndHideGraderAnonymousToGraders()
    expect(view.assignment.gradersAnonymousToGraders()).toBe(false)
  })
})

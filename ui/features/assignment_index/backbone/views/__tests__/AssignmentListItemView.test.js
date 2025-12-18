/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import {getByText, queryByText, findByText, waitForElementToBeRemoved} from '@testing-library/dom'
import fetchMock from 'fetch-mock'
import {setupServer} from 'msw/node'
import Backbone from '@canvas/backbone'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import Submission from '@canvas/assignments/backbone/models/Submission'
import AssignmentListItemView from '../AssignmentListItemView'
import $ from 'jquery'
import 'jquery-migrate'
import tzInTest from '@instructure/moment-utils/specHelpers'
import timezone from 'timezone'
import juneau from 'timezone/America/Juneau'
import french from 'timezone/fr_FR'
import I18nStubber from '@canvas/test-utils/I18nStubber'
import fakeENV from '@canvas/test-utils/fakeENV'
import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import '@canvas/jquery/jquery.simulate'
import {http, HttpResponse} from 'msw'
import {isAccessible} from '@canvas/test-utils/assertions'

// Mock globalUtils
vi.mock('@canvas/util/globalUtils', () => ({
  ...vi.requireActual('@canvas/util/globalUtils'),
  windowConfirm: vi.fn(() => true),
}))

let screenreaderText = null
let nonScreenreaderText = null

class AssignmentCollection extends Backbone.Collection {
  static initClass() {
    this.prototype.model = Assignment
  }
}
AssignmentCollection.initClass()

const assignment1 = () => {
  const date1 = {
    due_at: '2013-08-28T23:59:00-06:00',
    title: 'Summer Session',
  }
  const date2 = {
    due_at: '2013-08-28T23:59:00-06:00',
    title: 'Winter Session',
  }
  return buildAssignment({
    id: 1,
    name: 'History Quiz',
    description: 'test',
    due_at: '2013-08-21T23:59:00-06:00',
    points_possible: 2,
    position: 1,
    all_dates: [date1, date2],
  })
}

const assignment_grade_percent = () =>
  buildAssignment({
    id: 2,
    name: 'Science Quiz',
    grading_type: 'percent',
  })

const assignment_grade_pass_fail = () =>
  buildAssignment({
    id: 2,
    name: 'Science Quiz',
    grading_type: 'pass_fail',
  })

const assignment_grade_letter_grade = () =>
  buildAssignment({
    id: 2,
    name: 'Science Quiz',
    grading_type: 'letter_grade',
  })

const assignment_grade_not_graded = () =>
  buildAssignment({
    id: 2,
    name: 'Science Quiz',
    grading_type: 'not_graded',
  })

const buildAssignment = (options = {}) => {
  const base = {
    assignment_group_id: 1,
    due_at: null,
    grading_type: 'points',
    points_possible: 5,
    position: 2,
    course_id: 1,
    name: 'Science Quiz',
    submission_types: [],
    html_url: `http://localhost:3000/courses/1/assignments/${options.id}`,
    needs_grading_count: 0,
    all_dates: [],
    published: true,
  }
  Object.assign(base, options)
  const ac = new AssignmentCollection([base])
  ac.at(0).pollUntilFinishedDuplicating = vi.fn()
  return ac.at(0)
}

const createView = (model, options = {}) => {
  options = {
    canManage: true,
    canReadGrades: false,
    courseId: '42',
    ...options,
  }
  ENV.PERMISSIONS = {
    manage: options.canManage,
    manage_assignments_add: options.canAdd || options.canManage,
    manage_assignments_delete: options.canDelete || options.canManage,
    read_grades: options.canReadGrades,
  }

  if (options.individualAssignmentPermissions) {
    ENV.PERMISSIONS.by_assignment_id = {}
    ENV.PERMISSIONS.by_assignment_id[model.id] = options.individualAssignmentPermissions
  }

  ENV.POST_TO_SIS = options.post_to_sis
  ENV.DIRECT_SHARE_ENABLED = options.directShareEnabled
  ENV.COURSE_ID = options.courseId
  ENV.FLAGS = {
    show_additional_speed_grader_link: options.show_additional_speed_grader_link,
    newquizzes_on_quiz_page: options.newquizzes_on_quiz_page,
  }
  ENV.SHOW_SPEED_GRADER_LINK = options.show_additional_speed_grader_link
  ENV.SETTINGS = {}

  const view = new AssignmentListItemView({
    model,
    userIsAdmin: options.userIsAdmin,
  })
  view.$el.appendTo($('#fixtures'))
  view.render()
  return view
}

const genModules = count => {
  if (count === 1) {
    return ['First']
  } else {
    return ['First', 'Second']
  }
}

const genSetup = (model = assignment1()) => {
  fakeENV.setup({
    current_user_roles: ['teacher'],
    current_user_is_admin: false,
    PERMISSIONS: {manage: false},
    URLS: {assignment_sort_base_url: 'test'},
    SETTINGS: {},
  })
  const submission = new Submission()
  const view = createView(model, {canManage: false})
  screenreaderText = () => $.trim(view.$('.js-score .screenreader-only').text())
  nonScreenreaderText = () => $.trim(view.$('.js-score .non-screenreader').text())
  return {model, submission, view}
}

const genTeardown = () => {
  fakeENV.teardown()
  $('#fixtures').empty()
  // cleanup instui dialogs and trays that render in a portal outside of #fixtures
  $('[role="dialog"]').closest('span[dir="ltr"]').remove()
}

// Begin Conversion from QUnit to Jest

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterEach(() => {
  server.resetHandlers()
})

afterAll(() => {
  server.close()
})

describe('AssignmentListItemViewSpec', () => {
  const server = setupServer()

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'},
      current_user_is_admin: false,
    })
    const {model, submission, view} = genSetup()
    // Variables can be accessed here if needed
  })

  afterEach(() => {
    vi.restoreAllMocks()
    server.resetHandlers()
    genTeardown()
    tzInTest.restore()
    I18nStubber.clear()
  })

  afterAll(() => {
    server.close()
  })

  test('should be accessible', async () => {
    const view = createView(assignment1(), {canManage: true})
    await isAccessible(view, {a11yReport: true})
  })

  test('initializes child views if can manage', () => {
    const view = createView(assignment1(), {canManage: true})
    expect(view.publishIconView).toBeTruthy()
    expect(view.dateDueColumnView).toBeTruthy()
    expect(view.dateAvailableColumnView).toBeTruthy()
  })

  test("initializes no child views if can't manage", () => {
    const view = createView(assignment1(), {canManage: false})
    expect(view.publishIconView).toBeFalsy()
    expect(view.vddTooltipView).toBeFalsy()
    expect(view.editAssignmentView).toBeFalsy()
  })

  test('initializes sis toggle if post to sis enabled', () => {
    const view = createView(assignment1(), {canManage: true, post_to_sis: true})
    expect(view.sisButtonView).toBeTruthy()
  })

  test('does not initialize sis toggle if post to sis disabled', () => {
    const view = createView(assignment1(), {canManage: true, post_to_sis: false})
    expect(view.sisButtonView).toBeFalsy()
  })

  test('does not initialize sis toggle if assignment is not graded', () => {
    const model = buildAssignment({
      id: 1,
      submission_types: ['not_graded'],
    })
    const view = createView(model, {canManage: true, post_to_sis: true})
    expect(view.sisButtonView).toBeFalsy()
  })

  test("does not initialize sis toggle if post to sis disabled but can't manage", () => {
    const view = createView(assignment1(), {canManage: false, post_to_sis: false})
    expect(view.sisButtonView).toBeFalsy()
  })

  test("does not initialize sis toggle if sis enabled but can't manage", () => {
    const view = createView(assignment1(), {canManage: false, post_to_sis: true})
    expect(view.sisButtonView).toBeFalsy()
  })

  test("does not initialize sis toggle if post to sis disabled, can't manage and is unpublished", () => {
    const unpublishedModel = buildAssignment({
      id: 1,
      published: false,
    })
    const view = createView(unpublishedModel, {canManage: false, post_to_sis: false})
    expect(view.sisButtonView).toBeFalsy()
  })

  test("does not initialize sis toggle if sis enabled, can't manage and is unpublished", () => {
    const unpublishedModel = buildAssignment({
      id: 1,
      published: false,
    })
    const view = createView(unpublishedModel, {canManage: false, post_to_sis: true})
    expect(view.sisButtonView).toBeFalsy()
  })

  test('does not show sharing and copying menu items if not DIRECT_SHARE_ENABLED', () => {
    const view = createView(assignment1(), {directShareEnabled: false})
    expect(view.$('.send_assignment_to')).toHaveLength(0)
    expect(view.$('.copy_assignment_to')).toHaveLength(0)
  })

  test('updatePublishState toggles ig-published', () => {
    const model = assignment1()
    const view = createView(model, {canManage: true})
    expect(view.$('.ig-row').hasClass('ig-published')).toBe(true)
    // Change the model's published state and trigger the event
    model.set('published', false)
    // The view's updatePublishState method is bound to the model's change:published event
    // and will toggle the class based on the model's new published state
    expect(view.$('.ig-row').hasClass('ig-published')).toBe(false)
  })

  test('show ig-published class if assignment is published and canmanage is false', () => {
    ENV.current_user_roles = ['teacher']
    ENV.current_user_is_student = false
    const view = createView(assignment1(), {canManage: false})
    expect(view.$('.ig-row').hasClass('ig-published')).toBe(true)
  })

  test('does not show ig-published class if assignment is published and user has student role', () => {
    ENV.current_user_roles = ['student']
    ENV.current_user_is_student = true
    const view = createView(assignment1(), {canManage: false})
    expect(view.$('.ig-row').hasClass('ig-published')).toBe(false)
  })

  test('asks for confirmation before deleting an assignment', () => {
    const view = createView(assignment1())
    // Mock the assignment group view context that the view needs
    vi.spyOn(view, 'assignmentGroupView').mockReturnValue({
      visibleAssignments: () => [assignment1()],
    })
    // Mock window.confirm in the JSDOM environment
    const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(true)
    vi.spyOn(view, 'delete')
    view.$(`#assignment_${assignment1().id} .delete_assignment`).click()
    expect(confirmSpy).toHaveBeenCalled()
    expect(view.delete).toHaveBeenCalled()
  })

  test('does not attempt to delete an assignment due in a closed grading period', () => {
    const closedGradingModel = buildAssignment({
      in_closed_grading_period: true,
    })
    const view = createView(closedGradingModel)
    // Mock the assignment group view context
    vi.spyOn(view, 'assignmentGroupView').mockReturnValue({
      visibleAssignments: () => [closedGradingModel],
    })
    // Mock window.confirm
    const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(true)
    vi.spyOn(view, 'delete')
    view.$(`#assignment_${closedGradingModel.id} .delete_assignment`).click()
    expect(confirmSpy).not.toHaveBeenCalled()
    expect(view.delete).not.toHaveBeenCalled()
  })

  test('delete destroys model', () => {
    const old_asset_string = ENV.context_asset_string
    ENV.context_asset_string = 'course_1'
    const view = createView(assignment1())
    vi.spyOn(view.model, 'destroy')
    view.delete()
    expect(view.model.destroy).toHaveBeenCalled()
    ENV.context_asset_string = old_asset_string
  })

  test('delete calls screenreader message', async () => {
    const old_asset_string = ENV.context_asset_string
    ENV.context_asset_string = 'course_1'
    server.use(
      http.delete('/api/v1/courses/1/assignments/1', () => {
        return HttpResponse.json({
          description: '',
          due_at: null,
          grade_group_students_individually: false,
          grading_standard_id: null,
          grading_type: 'points',
          group_category_id: null,
          id: '1',
          unpublishable: true,
          only_visible_to_overrides: false,
          locked_for_user: false,
        })
      }),
    )
    const view = createView(assignment1())
    vi.spyOn($, 'screenReaderFlashMessage')
    view.delete()
    await new Promise(resolve => setTimeout(resolve, 10))
    expect($.screenReaderFlashMessage).toHaveBeenCalled()
    ENV.context_asset_string = old_asset_string
  })

  test('show score if score is set', () => {
    const model = assignment1()
    // Set submission BEFORE creating view so it renders with the submission data
    const submission = new Submission({score: 1.5555, grade: '1.5555'})
    model.set('submission', submission, {silent: true})
    const view = createView(model, {canManage: false, canReadGrades: true})
    const screenreaderText = () => $.trim(view.$('.js-score .screenreader-only').text())
    const nonScreenreaderText = () => $.trim(view.$('.js-score .non-screenreader').text())
    expect(screenreaderText()).toBe('Score: 1.56 out of 2 points.')
    expect(nonScreenreaderText()).toBe('1.56/2 pts')
  })

  test('do not show score if viewing as non-student', () => {
    const old_user_roles = ENV.current_user_roles
    ENV.current_user_roles = ['user']
    const view = createView(assignment1(), {canManage: false})
    const str = view.$('.js-score:eq(0) .non-screenreader').html()
    expect(str.search('2 pts')).not.toBe(-1)
    ENV.current_user_roles = old_user_roles
  })

  test('show no submission if none exists', () => {
    const model = assignment1()
    model.set({submission: null}, {silent: true})
    const view = createView(model, {canManage: false, canReadGrades: true})
    const screenreaderText = () => $.trim(view.$('.js-score .screenreader-only').text())
    const nonScreenreaderText = () => $.trim(view.$('.js-score .non-screenreader').text())
    expect(screenreaderText()).toBe('No submission for this assignment. 2 points possible.')
    expect(nonScreenreaderText()).toBe('-/2 pts')
  })

  test('show score if 0 correctly', () => {
    const model = assignment1()
    const submission = new Submission({score: 0, grade: '0'})
    model.set('submission', submission, {silent: true})
    const view = createView(model, {canManage: false, canReadGrades: true})
    const screenreaderText = () => $.trim(view.$('.js-score .screenreader-only').text())
    const nonScreenreaderText = () => $.trim(view.$('.js-score .non-screenreader').text())
    expect(screenreaderText()).toBe('Score: 0 out of 2 points.')
    expect(nonScreenreaderText()).toBe('0/2 pts')
  })

  test('show no submission if submission object with no submission type', () => {
    const model = assignment1()
    model.set('submission', new Submission(), {silent: true})
    const view = createView(model, {canManage: false, canReadGrades: true})
    const screenreaderText = () => $.trim(view.$('.js-score .screenreader-only').text())
    const nonScreenreaderText = () => $.trim(view.$('.js-score .non-screenreader').text())
    expect(screenreaderText()).toBe('No submission for this assignment. 2 points possible.')
    expect(nonScreenreaderText()).toBe('-/2 pts')
  })

  test('show not yet graded if submission type but no grade', () => {
    const model = assignment1()
    const submission = new Submission({submission_type: 'online', notYetGraded: true})
    model.set('submission', submission, {silent: true})
    const view = createView(model, {canManage: false, canReadGrades: true})
    const screenreaderText = () => $.trim(view.$('.js-score .screenreader-only').text())
    const nonScreenreaderText = () => $.trim(view.$('.js-score .non-screenreader').text())
    expect(screenreaderText()).toBe('Assignment not yet graded. 2 points possible.')
    expect(nonScreenreaderText()).toMatch(/-\/2 pts/)
    expect(nonScreenreaderText()).toMatch(/Not Yet Graded/)
  })

  test('disallows deleting frozen assignments', () => {
    const frozenModel = buildAssignment({
      id: 99,
      frozen: true,
    })
    const view = createView(frozenModel)
    // When canDelete() returns false, the template renders the disabled version of the delete link
    expect(view.$('a.delete_assignment.disabled')).toHaveLength(1)
  })

  test('disallows deleting assignments due in closed grading periods', () => {
    const closedGradingModel = buildAssignment({
      id: 98,
      in_closed_grading_period: true,
    })
    const view = createView(closedGradingModel)
    expect(view.$('a.delete_assignment.disabled')).toHaveLength(1)
  })

  test('allows deleting non-frozen assignments not due in closed grading periods', () => {
    const model = buildAssignment({
      id: 97,
      frozen: false,
      in_closed_grading_period: false,
    })
    const view = createView(model)
    expect(view.$('a.delete_assignment:not(.disabled)')).toHaveLength(1)
  })

  test('allows deleting frozen assignments for admins', () => {
    const frozenModel = buildAssignment({
      id: 96,
      frozen: true,
    })
    const view = createView(frozenModel, {userIsAdmin: true})
    expect(view.$('a.delete_assignment:not(.disabled)')).toHaveLength(1)
  })

  test('allows deleting assignments due in closed grading periods for admins', () => {
    const closedGradingModel = buildAssignment({
      id: 95,
      in_closed_grading_period: true,
    })
    const view = createView(closedGradingModel, {userIsAdmin: true})
    expect(view.$('a.delete_assignment:not(.disabled)')).toHaveLength(1)
  })

  test('renders link to SpeedGrader if canManage', () => {
    const model = buildAssignment({
      id: 11,
      title: 'Chicken Noodle',
    })
    const view = createView(model, {
      userIsAdmin: true,
      canManage: true,
      show_additional_speed_grader_link: true,
    })
    expect(view.$('.speed-grader-link')).toHaveLength(1)
  })

  test('does NOT render link when assignment is unpublished', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Chicken Noodle',
      published: false,
    })
    const view = createView(model, {
      userIsAdmin: true,
      canManage: true,
      show_additional_speed_grader_link: true,
    })
    expect(view.$('.speed-grader-link-container').hasClass('hidden')).toBe(true)
  })

  test('SpeedGrader link is correct', () => {
    const model = buildAssignment({
      id: 11,
      title: 'Cream of Mushroom',
    })
    const view = createView(model, {
      userIsAdmin: true,
      canManage: true,
      show_additional_speed_grader_link: true,
    })
    expect(view.$('.speed-grader-link')[0]?.href).toContain(
      '/courses/1/gradebook/speed_grader?assignment_id=11',
    )
  })

  test('can duplicate when assignment can be duplicated', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_duplicate: true,
    })
    const view = createView(model, {
      userIsAdmin: true,
      canManage: true,
    })
    const json = view.toJSON()
    expect(json.canDuplicate).toBe(true)
    expect(view.$('.duplicate_assignment')).toHaveLength(1)
  })

  test('clicks on Retry button to trigger another duplicating request', () => {
    const model = buildAssignment({
      id: 2,
      title: 'Foo Copy',
      original_assignment_name: 'Foo',
      workflow_state: 'failed_to_duplicate',
    })
    const view = createView(model)
    vi.spyOn(model, 'duplicate_failed')
    view.$(`#assignment_${model.id} .duplicate-failed-retry`).click()
    expect(model.duplicate_failed).toHaveBeenCalled()
  })

  test('clicks on Retry button to trigger another migrating request', () => {
    const model = buildAssignment({
      id: 2,
      title: 'Foo Copy',
      original_assignment_name: 'Foo',
      workflow_state: 'failed_to_migrate',
    })
    const view = createView(model)
    vi.spyOn(model, 'retry_migration')
    view.$(`#assignment_${model.id} .migrate-failed-retry`).click()
    expect(model.retry_migration).toHaveBeenCalled()
  })

  test('cannot duplicate when user is not admin', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_duplicate: true,
    })
    const view = createView(model, {
      userIsAdmin: false,
      canManage: false,
    })
    const json = view.toJSON()
    expect(json.canDuplicate).toBe(false)
    expect(view.$('.duplicate_assignment')).toHaveLength(0)
  })

  test('displays duplicating message when assignment is duplicating', () => {
    const model = buildAssignment({
      id: 2,
      title: 'Foo Copy',
      original_assignment_name: 'Foo',
      workflow_state: 'duplicating',
    })
    const view = createView(model)
    expect(view.$el.text()).toContain('Making a copy of "Foo"')
  })

  test('displays failed to duplicate message when assignment failed to duplicate', () => {
    const model = buildAssignment({
      id: 2,
      title: 'Foo Copy',
      original_assignment_name: 'Foo',
      workflow_state: 'failed_to_duplicate',
    })
    const view = createView(model)
    expect(view.$el.text()).toContain('Something went wrong with making a copy of "Foo"')
  })

  test('does not display cancel button when assignment failed to duplicate is blueprint', () => {
    const model = buildAssignment({
      id: 2,
      title: 'Foo Copy',
      original_assignment_name: 'Foo',
      workflow_state: 'failed_to_duplicate',
      is_master_course_child_content: true,
    })
    const view = createView(model)
    expect(view.$('button.duplicate-failed-cancel.btn')).toHaveLength(0)
  })

  test('displays cancel button when assignment failed to duplicate is not blueprint', () => {
    const model = buildAssignment({
      id: 2,
      title: 'Foo Copy',
      original_assignment_name: 'Foo',
      workflow_state: 'failed_to_duplicate',
    })
    const view = createView(model)
    expect(view.$('button.duplicate-failed-cancel.btn').text()).toContain('Cancel')
  })

  test('can assign assignment if flag is on and has edit permissions', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_update: true,
      submission_types: ['online_text_entry'],
    })
    const view = createView(model, {
      individualAssignmentPermissions: {manage_assign_to: true},
    })
    expect(view.$('.assign-to-link')).toHaveLength(1)
  })

  test('cannot assign assignment if no edit permissions', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_update: true,
      submission_types: ['online_text_entry'],
    })
    const view = createView(model, {
      individualAssignmentPermissions: {manage_assign_to: false},
    })
    expect(view.$('.assign-to-link')).toHaveLength(0)
  })

  test('can move when userIsAdmin is true', () => {
    const view = createView(assignment1(), {
      userIsAdmin: true,
      canManage: false,
    })
    const json = view.toJSON()
    expect(json.canMove).toBe(true)
    expect(view.className().includes('sort-disabled')).toBe(false)
  })

  test('can move when canManage is true and the assignment group id is not locked', () => {
    // Use the SAME model instance for both spy and createView
    const model = assignment1()
    vi.spyOn(model, 'canMove').mockReturnValue(true)
    const view = createView(model, {
      userIsAdmin: false,
      canManage: true,
    })
    const json = view.toJSON()
    expect(json.canMove).toBe(true)
    expect(view.className().includes('sort-disabled')).toBe(false)
  })

  test('cannot move when canManage is true but the assignment group id is locked', () => {
    // Use the SAME model instance for both spy and createView
    const model = assignment1()
    vi.spyOn(model, 'canMove').mockReturnValue(false)
    const view = createView(model, {
      userIsAdmin: false,
      canManage: true,
    })
    const json = view.toJSON()
    expect(json.canMove).toBe(false)
    expect(view.className().includes('sort-disabled')).toBe(true)
  })

  test('cannot move when canManage is false but the assignment group id is not locked', () => {
    // Use the SAME model instance for both spy and createView
    const model = assignment1()
    vi.spyOn(model, 'canMove').mockReturnValue(true)
    const view = createView(model, {
      userIsAdmin: false,
      canManage: false,
    })
    const json = view.toJSON()
    expect(json.canMove).toBe(false)
    expect(view.className().includes('sort-disabled')).toBe(true)
  })

  test('re-renders when assignment state changes', () => {
    // Use the SAME model instance to ensure the event triggers on the right model
    const model = assignment1()
    // Spy on render BEFORE creating the view so we can intercept the binding
    const renderSpy = vi.spyOn(AssignmentListItemView.prototype, 'render')
    const view = createView(model, {canManage: true})
    // Clear the spy calls from initial render
    renderSpy.mockClear()
    // Trigger the change event on the same model the view is bound to
    model.trigger('change:workflow_state')
    expect(renderSpy).toHaveBeenCalled()
  })

  test('polls for updates if assignment is duplicating', () => {
    // Use the SAME model instance for all operations
    const model = assignment1()
    vi.spyOn(model, 'isDuplicating').mockReturnValue(true)
    vi.spyOn(model, 'pollUntilFinishedDuplicating').mockImplementation(() => {})
    const view = createView(model)
    expect(model.pollUntilFinishedDuplicating).toHaveBeenCalled()
  })

  test('polls for updates if assignment is importing', () => {
    // Use the SAME model instance for all operations
    const model = assignment1()
    vi.spyOn(model, 'isImporting').mockReturnValue(true)
    vi.spyOn(model, 'pollUntilFinishedImporting').mockImplementation(() => {})
    const view = createView(model)
    expect(model.pollUntilFinishedImporting).toHaveBeenCalled()
  })

  test('shows availability for checkpoints', () => {
    const model = buildAssignment({
      id: 2,
      title: 'test checkpoint',
      workflow_state: 'published',
      due_at: '2024-08-28T23:59:00-06:00',
      lock_at: '2013-09-28T23:59:00-06:00',
      unlock_at: '2013-07-28T23:59:00-06:00',
      can_manage: true,
      checkpoints: [
        {
          id: 2,
          title: 'reply to topic',
          tag: 'reply_to_topic',
        },
        {
          id: 3,
          title: 'reply to entry',
          tag: 'reply_to_entry',
        },
      ],
    })
    const view = createView(model)
    expect(view.dateAvailableColumnView).toBeTruthy()
  })
})

// Skipped QUnit Tests Converted to Jest

// TODO: React component not rendering - dialog component requires complex initialization
describe.skip('AssignmentListItemViewSpec - opens and closes the direct share send to user dialog', () => {
  test('opens and closes the dialog correctly', async () => {
    // Create mount point before creating the view
    $('#fixtures').append('<div id="send-to-mount-point" />')
    const model = buildAssignment({
      id: 1,
      title: 'Test Assignment',
      can_manage: true,
    })
    const view = createView(model, {directShareEnabled: true})
    view.$('.send_assignment_to').click()
    expect(await findByText(document.body, 'Send to:')).toBeTruthy()
    getByText(document.body, 'Close').click()
    await waitForElementToBeRemoved(() => queryByText(document.body, 'Send to:'))
  })
})

// TODO: React component not rendering - tray component requires complex initialization
describe.skip('AssignmentListItemViewSpec - opens and closes the direct share copy to course tray', () => {
  test('opens and closes the copy to course tray correctly', async () => {
    // Create mount point before creating the view
    $('#fixtures').append('<div id="copy-to-mount-point" />')
    const model = buildAssignment({
      id: 1,
      title: 'Test Assignment',
      can_manage: true,
    })
    const view = createView(model, {directShareEnabled: true})
    // Mock the API call before triggering the action
    fetchMock.mock('/users/self/manageable_courses', [])
    view.$('.copy_assignment_to').click()
    expect(await findByText(document.body, 'Select a Course')).toBeTruthy()
    getByText(document.body, 'Close').click()
    await waitForElementToBeRemoved(() => queryByText(document.body, 'Select a Course'))
  })
})

// Continue with Other Modules

describe('AssignmentListItemViewSpec - editing assignments', () => {
  beforeEach(() => {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'},
      current_user_is_admin: false,
    })
    genSetup()
  })

  afterEach(() => {
    vi.restoreAllMocks()
    genTeardown()
  })

  test('canEdit is true if no individual permissions are set and canManage is true', () => {
    const view = createView(assignment1(), {
      userIsAdmin: false,
      canManage: true,
    })

    const json = view.toJSON()
    expect(json.canEdit).toBe(true)
  })

  test('canEdit is false if no individual permissions are set and canManage is false', () => {
    const view = createView(assignment1(), {
      userIsAdmin: false,
      canManage: false,
    })

    const json = view.toJSON()
    expect(json.canEdit).toBe(false)
  })

  test('canEdit is true if no individual permissions are set and userIsAdmin is true', () => {
    const view = createView(assignment1(), {
      userIsAdmin: true,
      canManage: false,
    })

    const json = view.toJSON()
    expect(json.canEdit).toBe(true)
  })

  test('canEdit is false if canManage is true and the individual assignment cannot be updated', () => {
    const view = createView(assignment1(), {
      canManage: true,
      individualAssignmentPermissions: {update: false},
    })

    const json = view.toJSON()
    expect(json.canEdit).toBe(false)
  })

  test('canEdit is true if canManage is true and the individual assignment can be updated', () => {
    const view = createView(assignment1(), {
      canManage: true,
      individualAssignmentPermissions: {update: true},
    })

    const json = view.toJSON()
    expect(json.canEdit).toBe(true)
  })

  test('canEdit is false if canManage is true and the update parameter does not exist', () => {
    const view = createView(assignment1(), {
      canManage: true,
      individualAssignmentPermissions: {},
    })

    const json = view.toJSON()
    expect(json.canEdit).toBe(false)
  })

  test('edit link is enabled when the individual assignment is editable', () => {
    const view = createView(assignment1(), {
      individualAssignmentPermissions: {update: true},
    })

    expect(view.$('.edit_assignment').hasClass('disabled')).toBe(false)
  })

  test('edit link is disabled when the individual assignment is not editable', () => {
    const view = createView(assignment1(), {
      individualAssignmentPermissions: {update: false},
    })

    expect(view.$('.edit_assignment').hasClass('disabled')).toBe(true)
  })
})

describe('AssignmentListItemViewSpec - skip to build screen button', () => {
  beforeEach(() => {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'},
      QUIZ_LTI_ENABLED: true,
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    genTeardown()
  })

  test('canShowBuildLink is true if QUIZ_LTI_ENABLED', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      is_quiz_lti_assignment: true,
    })
    const view = createView(model)
    const json = view.toJSON()
    expect(json.canShowBuildLink).toBe(true)
  })

  test('canShowBuildLink is false if the assignment is not a new quiz', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      is_quiz_lti_assignment: false,
    })
    const view = createView(model)
    const json = view.toJSON()
    expect(json.canShowBuildLink).toBe(false)
  })
})

describe('AssignmentListItemViewSpec - mastery paths menu option', () => {
  beforeEach(() => {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
      URLS: {assignment_sort_base_url: 'test'},
    })
    CyoeHelper.reloadEnv()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('does not render for assignment if cyoe off', () => {
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_update: true,
      submission_types: ['online_text_entry'],
    })
    const view = createView(model)
    expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(0)
  })

  test('renders for assignment if cyoe on', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_update: true,
      submission_types: ['online_text_entry'],
    })
    const view = createView(model)
    expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(1)
  })

  test('does not render for ungraded assignment if cyoe on', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_update: true,
      submission_types: ['not_graded'],
    })
    const view = createView(model)
    expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(0)
  })

  test('renders for assignment quiz if cyoe on', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_update: true,
      is_quiz_assignment: true,
      submission_types: ['online_quiz'],
    })
    const view = createView(model)
    expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(1)
  })

  test('does not render for non-assignment quiz if cyoe on', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_update: true,
      is_quiz_assignment: false,
      submission_types: ['online_quiz'],
    })
    const view = createView(model)
    expect(view.$('.icon-mastery-path')).toHaveLength(0)
  })

  test('renders for graded discussion if cyoe on', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_update: true,
      submission_types: ['discussion_topic'],
    })
    const view = createView(model)
    expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(1)
  })

  test('does not render for graded page if cyoe on', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      can_update: true,
      submission_types: ['wiki_page'],
    })
    const view = createView(model)
    expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(0)
  })
})

describe('AssignmentListItemViewSpec - mastery paths link', () => {
  beforeEach(() => {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
      CONDITIONAL_RELEASE_ENV: {
        active_rules: [
          {
            trigger_assignment_id: '1',
            scoring_ranges: [
              {
                assignment_sets: [{assignment_set_associations: [{assignment_id: '2'}]}],
              },
            ],
          },
        ],
      },
      URLS: {assignment_sort_base_url: 'test'},
    })
    CyoeHelper.reloadEnv()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('does not render for assignment if cyoe off', () => {
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    const model = buildAssignment({
      id: '1',
      title: 'Foo',
      can_update: true,
      submission_types: ['online_text_entry'],
    })
    const view = createView(model)
    expect(view.$('.ig-admin > a[href$="#mastery-paths-editor"]')).toHaveLength(0)
  })

  test('does not render for assignment if assignment does not have a rule', () => {
    const model = buildAssignment({
      id: '2',
      title: 'Foo',
      can_update: true,
      submission_types: ['online_text_entry'],
    })
    const view = createView(model)
    expect(view.$('.ig-admin > a[href$="#mastery-paths-editor"]')).toHaveLength(0)
  })

  test('renders for assignment if assignment has a rule', () => {
    const model = buildAssignment({
      id: '1',
      title: 'Foo',
      can_update: true,
      submission_types: ['online_text_entry'],
    })
    const view = createView(model)
    expect(view.$('.ig-admin > a[href$="#mastery-paths-editor"]')).toHaveLength(1)
  })
})

describe('AssignmentListItemViewSpec - mastery paths icon', () => {
  beforeEach(() => {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
      CONDITIONAL_RELEASE_ENV: {
        active_rules: [
          {
            trigger_assignment_id: '1',
            scoring_ranges: [
              {
                assignment_sets: [{assignment_set_associations: [{assignment_id: '2'}]}],
              },
            ],
          },
        ],
      },
      URLS: {assignment_sort_base_url: 'test'},
    })
    CyoeHelper.reloadEnv()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('does not render for assignment if cyoe off', () => {
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    const model = buildAssignment({
      id: '2',
      title: 'Foo',
      can_update: true,
      submission_types: ['online_text_entry'],
    })
    const view = createView(model)
    expect(view.$('.mastery-path-icon')).toHaveLength(0)
  })

  test('does not render for assignment if assignment is not released by a rule', () => {
    const model = buildAssignment({
      id: '1',
      title: 'Foo',
      can_update: true,
      submission_types: ['online_text_entry'],
    })
    const view = createView(model)
    expect(view.$('.mastery-path-icon')).toHaveLength(0)
  })

  test('renders for assignment if assignment is released by a rule', () => {
    const model = buildAssignment({
      id: '2',
      title: 'Foo',
      can_update: true,
      submission_types: ['online_text_entry'],
    })
    const view = createView(model)
    expect(view.$('.mastery-path-icon')).toHaveLength(1)
  })
})

describe('AssignmentListItemViewSpec - assignment icons', () => {
  beforeEach(() => {
    fakeENV.setup({
      current_user_roles: ['teacher', 'student'],
      URLS: {assignment_sort_base_url: 'test'},
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('renders discussion icon for discussion topic', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      submission_types: ['discussion_topic'],
    })
    const view = createView(model)
    expect(view.$('i.icon-discussion')).toHaveLength(1)
  })

  test('renders quiz icon for old quizzes', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      submission_types: ['online_quiz'],
    })
    const view = createView(model)
    expect(view.$('i.icon-quiz')).toHaveLength(1)
  })

  test('renders page icon for wiki page', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      submission_types: ['wiki_page'],
    })
    const view = createView(model)
    expect(view.$('i.icon-document')).toHaveLength(1)
  })

  test('renders solid quiz icon for new quizzes', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      is_quiz_lti_assignment: true,
    })
    const view = createView(model, {newquizzes_on_quiz_page: true})
    expect(view.$('i.icon-quiz.icon-Solid')).toHaveLength(1)
  })

  test('renders assignment icon for new quizzes if FF is off', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
      is_quiz_lti_assignment: true,
    })
    const view = createView(model, {newquizzes_on_quiz_page: false})
    expect(view.$('i.icon-quiz.icon-Solid')).toHaveLength(0)
    expect(view.$('i.icon-assignment')).toHaveLength(1)
  })

  test('renders assignment icon for other assignments', () => {
    const model = buildAssignment({
      id: 1,
      title: 'Foo',
    })
    const view = createView(model)
    expect(view.$('i.icon-assignment')).toHaveLength(1)
  })
})

describe('Assignment#quizzesRespondusEnabled', () => {
  beforeEach(() => {
    fakeENV.setup({
      current_user_roles: [],
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('returns false if the assignment is not RLDB enabled', () => {
    fakeENV.setup({current_user_roles: ['student']})
    const model = buildAssignment({
      id: 1,
      require_lockdown_browser: false,
      is_quiz_lti_assignment: true,
    })
    const view = createView(model)
    const json = view.toJSON()
    expect(json.quizzesRespondusEnabled).toBe(false)
  })

  test('returns false if the assignment is not a N.Q assignment', () => {
    fakeENV.setup({current_user_roles: ['student']})
    const model = buildAssignment({
      id: 1,
      require_lockdown_browser: true,
      is_quiz_lti_assignment: false,
    })
    const view = createView(model)
    const json = view.toJSON()
    expect(json.quizzesRespondusEnabled).toBe(false)
  })

  test('returns false if the user is not a student', () => {
    fakeENV.setup({current_user_roles: ['teacher']})
    const model = buildAssignment({
      id: 1,
      require_lockdown_browser: true,
      is_quiz_lti_assignment: true,
    })
    const view = createView(model)
    const json = view.toJSON()
    expect(json.quizzesRespondusEnabled).toBe(false)
  })

  test('returns true if the assignment is a RLDB enabled N.Q', () => {
    fakeENV.setup({current_user_roles: ['student']})
    const model = buildAssignment({
      id: 1,
      require_lockdown_browser: true,
      is_quiz_lti_assignment: true,
    })
    const view = createView(model, {canManage: false})
    const json = view.toJSON()
    expect(json.quizzesRespondusEnabled).toBe(true)
  })
})

// TODO: React modal focus management - mockRoot.render not being called
describe.skip('renderCreateEditAssignmentModal focus management', () => {
  beforeEach(() => {
    const mountPoint = document.createElement('div')
    mountPoint.id = 'create-edit-mount-point'
    document.body.appendChild(mountPoint)
  })

  afterEach(() => {
    const mountPoint = document.getElementById('create-edit-mount-point')
    if (mountPoint) {
      mountPoint.remove()
    }
  })

  test('focuses on manage link when modal closes', () => {
    const model = buildAssignment({id: 1})
    const view = createView(model)

    const manageLink = document.createElement('a')
    manageLink.id = `assign_${model.id}_manage_link`
    document.body.appendChild(manageLink)

    const focusSpy = vi.spyOn(manageLink, 'focus')

    let capturedOnClose
    const mockRender = vi.fn(element => {
      // Extract the closeHandler prop from CreateAssignmentViewAdapter
      if (element && element.props && element.props.closeHandler) {
        capturedOnClose = element.props.closeHandler
      }
    })
    const mockRoot = {
      render: mockRender,
      unmount: vi.fn(),
    }

    vi.spyOn(require('react-dom/client'), 'createRoot').mockReturnValue(mockRoot)

    view.renderCreateEditAssignmentModal()

    expect(mockRoot.render).toHaveBeenCalled()

    if (capturedOnClose) {
      capturedOnClose()
    }

    expect(focusSpy).toHaveBeenCalled()

    manageLink.remove()
  })
})

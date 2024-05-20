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

import {getByText, queryByText, findByText, waitForToBeRemoved} from '@testing-library/dom'
import fetchMock from 'fetch-mock'
import Backbone from '@canvas/backbone'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import Submission from '@canvas/assignments/backbone/models/Submission'
import AssignmentListItemView from 'ui/features/assignment_index/backbone/views/AssignmentListItemView'
import $ from 'jquery'
import 'jquery-migrate'
import tzInTest from '@canvas/datetime/specHelpers'
import timezone from 'timezone'
import juneau from 'timezone/America/Juneau'
import french from 'timezone/fr_FR'
import I18nStubber from 'helpers/I18nStubber'
import fakeENV from 'helpers/fakeENV'
import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import assertions from 'helpers/assertions'
import '@canvas/jquery/jquery.simulate'

let screenreaderText = null
let nonScreenreaderText = null
class AssignmentCollection extends Backbone.Collection {
  static initClass() {
    this.prototype.model = Assignment
  }
}
AssignmentCollection.initClass()
const assignment1 = function () {
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
const buildAssignment = function (options) {
  if (options == null) {
    options = {}
  }
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
  sinon.stub(ac.at(0), 'pollUntilFinishedDuplicating')
  return ac.at(0)
}
const createView = function (model, options) {
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
  ENV.FEATURES.differentiated_modules = options.differentiated_modules

  const view = new AssignmentListItemView({
    model,
    userIsAdmin: options.userIsAdmin,
  })
  view.$el.appendTo($('#fixtures'))
  view.render()
  return view
}
const genModules = function (count) {
  if (count === 1) {
    return ['First']
  } else {
    return ['First', 'Second']
  }
}
const genSetup = function (model = assignment1()) {
  fakeENV.setup({
    current_user_roles: ['teacher'],
    current_user_is_admin: false,
    PERMISSIONS: {manage: false},
    URLS: {assignment_sort_base_url: 'test'},
  })
  this.model = model
  this.submission = new Submission()
  this.view = createView(this.model, {canManage: false})
  screenreaderText = () => $.trim(this.view.$('.js-score .screenreader-only').text())
  return (nonScreenreaderText = () => $.trim(this.view.$('.js-score .non-screenreader').text()))
}
const genTeardown = function () {
  fakeENV.teardown()
  $('#fixtures').empty()
  // cleanup instui dialogs and trays that render in a portal outside of #fixtures
  $('[role="dialog"]').closest('span[dir="ltr"]').remove()
}

QUnit.module('AssignmentListItemViewSpec', {
  setup() {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'},
      current_user_is_admin: false,
    })
    genSetup.call(this)
    return I18nStubber.pushFrame()
  },
  teardown() {
    fakeENV.teardown()
    genTeardown.call(this)
    tzInTest.restore()
    return I18nStubber.clear()
  },
})

// eslint-disable-next-line qunit/resolve-async
test('should be accessible', function (assert) {
  const view = createView(this.model, {canManage: true})
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('initializes child views if can manage', function () {
  const view = createView(this.model, {canManage: true})
  ok(view.publishIconView)
  ok(view.dateDueColumnView)
  ok(view.dateAvailableColumnView)
  ok(view.editAssignmentView)
})

test("initializes no child views if can't manage", function () {
  const view = createView(this.model, {canManage: false})
  ok(!view.publishIconView)
  ok(!view.vddTooltipView)
  ok(!view.editAssignmentView)
})

test('initializes sis toggle if post to sis enabled', function () {
  this.model.set('published', true)
  const view = createView(this.model, {
    canManage: true,
    post_to_sis: true,
  })
  ok(view.sisButtonView)
})

test('does not initialize sis toggle if post to sis disabled', function () {
  this.model.set('published', true)
  const view = createView(this.model, {
    canManage: true,
    post_to_sis: false,
  })
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if assignment is not graded', function () {
  this.model.set('submission_types', ['not_graded'])
  const view = createView(this.model, {
    canManage: true,
    post_to_sis: true,
  })
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if post to sis disabled but can't manage", function () {
  this.model.set('published', true)
  const view = createView(this.model, {
    canManage: false,
    post_to_sis: false,
  })
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if sis enabled but can't manage", function () {
  this.model.set('published', true)
  const view = createView(this.model, {
    canManage: false,
    post_to_sis: true,
  })
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if post to sis disabled, can't manage and is unpublished", function () {
  this.model.set('published', false)
  const view = createView(this.model, {
    canManage: false,
    post_to_sis: false,
  })
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if sis enabled, can't manage and is unpublished", function () {
  this.model.set('published', false)
  const view = createView(this.model, {
    canManage: false,
    post_to_sis: true,
  })
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if post to sis disabled, can manage and is unpublished', function () {
  this.model.set('published', false)
  const view = createView(this.model, {
    canManage: true,
    post_to_sis: false,
  })
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if sis enabled, can manage and is unpublished', function () {
  this.model.set('published', false)
  const view = createView(this.model, {
    canManage: true,
    post_to_sis: true,
  })
  ok(!view.sisButtonView)
})

QUnit.skip(
  'Fix in LA-383 - opens and closes the direct share send to user dialog',
  async function () {
    const view = createView(this.model, {directShareEnabled: true})
    $('#fixtures').append('<div id="send-to-mount-point" />')
    view.$('.send_assignment_to').click()
    ok(await findByText(document.body, 'Send to:'))
    getByText(document.body, 'Close').click()
    await waitForToBeRemoved(() => queryByText(document.body, 'Send to:'))
  }
)

QUnit.skip(
  'Fix in LA-354 - opens and closes the direct share copy to course tray',
  async function () {
    const view = createView(this.model, {directShareEnabled: true})
    $('#fixtures').append('<div id="copy-to-mount-point" />')
    view.$('.copy_assignment_to').click()
    fetchMock.mock('/users/self/manageable_courses', [])
    ok(await findByText(document.body, 'Select a Course'))
    getByText(document.body, 'Close').click()
    await waitForToBeRemoved(() => queryByText(document.body, 'Select a Course'))
  }
)

test('does not show sharing and copying menu items if not DIRECT_SHARE_ENABLED', function () {
  const view = createView(this.model, {
    directShareEnabled: false,
  })
  strictEqual(view.$('.send_assignment_to').length, 0)
  strictEqual(view.$('.copy_assignment_to').length, 0)
})

test('upatePublishState toggles ig-published', function () {
  const view = createView(this.model, {canManage: true})
  ok(view.$('.ig-row').hasClass('ig-published'))
  this.model.set('published', false)
  ok(!view.$('.ig-row').hasClass('ig-published'))
})

test('asks for confirmation before deleting an assignment', function () {
  const view = createView(this.model)
  sandbox.stub(view, 'visibleAssignments').returns([])
  sandbox.stub(window, 'confirm').returns(true)
  sandbox.spy(view, 'delete')
  view.$(`#assignment_${this.model.id} .delete_assignment`).click()
  ok(window.confirm.called)
  ok(view.delete.called)
})

test('does not attempt to delete an assignment due in a closed grading period', function () {
  this.model.set('in_closed_grading_period', true)
  const view = createView(this.model)
  sandbox.stub(window, 'confirm').returns(true)
  sandbox.spy(view, 'delete')
  view.$(`#assignment_${this.model.id} .delete_assignment`).click()
  ok(window.confirm.notCalled)
  ok(view.delete.notCalled)
})

test('delete destroys model', function () {
  const old_asset_string = ENV.context_asset_string
  ENV.context_asset_string = 'course_1'
  const view = createView(this.model)
  sandbox.spy(view.model, 'destroy')
  view.delete()
  ok(view.model.destroy.called)
  ENV.context_asset_string = old_asset_string
})

test('delete calls screenreader message', function () {
  const old_asset_string = ENV.context_asset_string
  ENV.context_asset_string = 'course_1'
  const server = sinon.fakeServer.create()
  server.respondWith('DELETE', '/api/v1/courses/1/assignments/1', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify({
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
    }),
  ])
  const view = createView(this.model)
  view.delete()
  sandbox.spy($, 'screenReaderFlashMessage')
  server.respond()
  equal($.screenReaderFlashMessage.callCount, 1)
  ENV.context_asset_string = old_asset_string
})

test('show score if score is set', function () {
  this.submission.set({
    score: 1.5555,
    grade: '1.5555',
  })
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  equal(screenreaderText(), 'Score: 1.56 out of 2 points.', 'sets screenreader text')
  equal(nonScreenreaderText(), '1.56/2 pts', 'sets non-screenreader text')
})

test('do not show score if viewing as non-student', function () {
  const old_user_roles = ENV.current_user_roles
  ENV.current_user_roles = ['user']
  const view = createView(this.model, {canManage: false})
  const str = view.$('.js-score:eq(0) .non-screenreader').html()
  notStrictEqual(str.search('2 pts'), -1)
  ENV.current_user_roles = old_user_roles
})

test('show no submission if none exists', function () {
  this.model.set({submission: null})
  equal(
    screenreaderText(),
    'No submission for this assignment. 2 points possible.',
    'sets screenreader text for null points'
  )
  equal(nonScreenreaderText(), '-/2 pts', 'sets non-screenreader text for null points')
})

test('show score if 0 correctly', function () {
  this.submission.set({
    score: 0,
    grade: '0',
  })
  this.model.set('submission', this.submission)
  equal(screenreaderText(), 'Score: 0 out of 2 points.', 'sets screenreader text for 0 points')
  equal(nonScreenreaderText(), '0/2 pts', 'sets non-screenreader text for 0 points')
})

test('show no submission if submission object with no submission type', function () {
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  equal(
    screenreaderText(),
    'No submission for this assignment. 2 points possible.',
    'sets correct screenreader text for not yet graded'
  )
  equal(nonScreenreaderText(), '-/2 pts', 'sets correct non-screenreader text for not yet graded')
})

test('show not yet graded if submission type but no grade', function () {
  this.submission.set({
    submission_type: 'online',
    notYetGraded: true,
  })
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  equal(
    screenreaderText(),
    'Assignment not yet graded. 2 points possible.',
    'sets correct screenreader text for not yet graded'
  )
  ok(
    nonScreenreaderText().match('-/2 pts')[0],
    'sets correct non-screenreader text for not yet graded'
  )
  ok(nonScreenreaderText().match('Not Yet Graded')[0])
})

test('focus returns to cog after dismissing dialog', function () {
  const view = createView(this.model, {canManage: true})
  const trigger = view.$(`#assign_${this.model.id}_manage_link`)
  ok(trigger.length, 'there is an a node with the correct id')
  trigger.click()
  view.$(`#assignment_${this.model.id}_settings_edit_item`).click()
  view.editAssignmentView.close()
  equal(document.activeElement, trigger.get(0))
})

test('disallows deleting frozen assignments', function () {
  this.model.set('frozen', true)
  const view = createView(this.model)
  ok(view.$(`#assignment_${this.model.id} a.delete_assignment.disabled`).length)
})

test('disallows deleting assignments due in closed grading periods', function () {
  this.model.set('in_closed_grading_period', true)
  const view = createView(this.model)
  ok(view.$(`#assignment_${this.model.id} a.delete_assignment.disabled`).length)
})

test('allows deleting non-frozen assignments not due in closed grading periods', function () {
  this.model.set('frozen', false)
  this.model.set('in_closed_grading_period', false)
  const view = createView(this.model)
  ok(view.$(`#assignment_${this.model.id} a.delete_assignment:not(.disabled)`).length)
})

test('allows deleting frozen assignments for admins', function () {
  this.model.set('frozen', true)
  const view = createView(this.model, {userIsAdmin: true})
  ok(view.$(`#assignment_${this.model.id} a.delete_assignment:not(.disabled)`).length)
})

test('allows deleting assignments due in closed grading periods for admins', function () {
  this.model.set('any_assignment_in_closed_grading_period', true)
  const view = createView(this.model, {userIsAdmin: true})
  ok(view.$(`#assignment_${this.model.id} a.delete_assignment:not(.disabled)`).length)
})

test('allows publishing', function () {
  this.server = sinon.fakeServer.create()
  this.server.respondWith('PUT', '/api/v1/users/1/assignments/1', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(''),
  ])
  this.model.set('published', false)
  const view = createView(this.model)
  view.$(`#assignment_${this.model.id} .publish-icon`).click()
  this.server.respond()
  equal(this.model.get('published'), true)
  return this.server.restore()
})

test("correctly displays module's name", function () {
  const mods = genModules(1)
  this.model.set('modules', mods)
  const view = createView(this.model)
  notStrictEqual(view.$('.modules').text().search(`${mods[0]} Module`), -1)
})

test("correctly display's multiple modules", function () {
  const mods = genModules(2)
  this.model.set('modules', mods)
  const view = createView(this.model)
  notStrictEqual(view.$('.modules').text().search('Multiple Modules'), -1)
  notStrictEqual(view.$(`#module_tooltip_${this.model.id}`).text().search(`${mods[0]}`), -1)
  notStrictEqual(view.$(`#module_tooltip_${this.model.id}`).text().search(`${mods[1]}`), -1)
})

test('render score template with permission', function () {
  const spy = sandbox.spy(AssignmentListItemView.prototype, 'updateScore')
  createView(this.model, {
    canManage: false,
    canReadGrades: true,
  })
  ok(spy.called)
})

test('does not render score template without permission', function () {
  const spy = sandbox.spy(AssignmentListItemView.prototype, 'updateScore')
  createView(this.model, {
    canManage: false,
    canReadGrades: false,
  })
  equal(spy.callCount, 0)
})

test('renders lockAt/unlockAt with locale-appropriate format string', function () {
  tzInTest.configureAndRestoreLater({
    tz: timezone(french, 'fr_FR'),
    momentLocale: 'fr',
  })
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {
    'date.formats.short': '%-d %b',
    'date.abbr_month_names': [0, 1, 2, 3, 4, 5, 6, 7, 'août', 9, 10, 11, 12],
    'date.formats.date_at_time': '%-d %b à %k:%M',
  })
  const model = buildAssignment({
    id: 1,
    lock_at: '2113-08-28T04:00:00Z',
    all_dates: [
      {
        lock_at: '2113-08-28T04:00:00Z',
        title: 'Summer Session',
      },
      {
        unlock_at: '2113-08-28T04:00:00Z',
        title: 'Winter Session',
      },
    ],
  })
  const view = createView(model, {canManage: true})
  const $dds = view.dateAvailableColumnView.$(`#vdd_tooltip_${this.model.id}_lock div`)
  equal($('span', $dds.first()).first().text().trim(), '28 août à  4:00')
  equal($('span', $dds.last()).first().text().trim(), '28 août à  4:00')
})

test('renders lockAt/unlockAt in appropriate time zone', function () {
  tzInTest.configureAndRestoreLater({
    tz: timezone(juneau, 'America/Juneau'),
    tzData: {
      'America/Juneau': juneau,
    },
  })
  I18nStubber.stub('en', {
    'date.formats.short': '%b %-d',
    'date.formats.date_at_time': '%b %-d at %l:%M%P',
    'date.abbr_month_names': [0, 1, 2, 3, 4, 5, 6, 7, 'Aug', 9, 10, 11, 12],
  })
  const model = buildAssignment({
    id: 1,
    lock_at: '2113-08-28T04:00:00Z',
    all_dates: [
      {
        lock_at: '2113-08-28T04:00:00Z',
        title: 'Summer Session',
      },
      {
        unlock_at: '2113-08-28T04:00:00Z',
        title: 'Winter Session',
      },
    ],
  })
  const view = createView(model, {canManage: true})
  const $dds = view.dateAvailableColumnView.$(`#vdd_tooltip_${this.model.id}_lock div`)
  equal($('span', $dds.first()).first().text().trim(), 'Aug 27 at  8:00pm')
  equal($('span', $dds.last()).first().text().trim(), 'Aug 27 at  8:00pm')
})

test('renders lockAt/unlockAt for multiple due dates', () => {
  const model = buildAssignment({
    id: 1,
    all_dates: [{due_at: new Date().toISOString()}, {due_at: new Date().toISOString()}],
  })
  const view = createView(model)
  const json = view.toJSON()
  equal(json.showAvailability, true)
})

test('renders lockAt/unlockAt when locked', () => {
  const future = new Date()
  future.setDate(future.getDate() + 10)
  const model = buildAssignment({
    id: 1,
    unlock_at: future.toISOString(),
  })
  const view = createView(model)
  const json = view.toJSON()
  equal(json.showAvailability, true)
})

test('renders lockAt/unlockAt when locking in future', () => {
  const past = new Date()
  past.setDate(past.getDate() - 10)
  const future = new Date()
  future.setDate(future.getDate() + 10)
  const model = buildAssignment({
    id: 1,
    unlock_at: past,
    lock_at: future.toISOString(),
  })
  const view = createView(model)
  const json = view.toJSON()
  equal(json.showAvailability, true)
})

test('does not render lockAt/unlockAt when not locking in future', () => {
  const past = new Date()
  past.setDate(past.getDate() - 10)
  const model = buildAssignment({
    id: 1,
    unlock_at: past.toISOString(),
  })
  const view = createView(model)
  const json = view.toJSON()
  equal(json.showAvailability, false)
})

test('renders due date column with locale-appropriate format string', function () {
  tzInTest.configureAndRestoreLater({
    tz: timezone(french, 'fr_FR'),
    momentLocale: 'fr',
  })
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {
    'date.formats.short': '%-d %b',
    'date.abbr_month_names': [0, 1, 2, 3, 4, 5, 6, 7, 'août', 9, 10, 11, 12],
  })
  const view = createView(this.model, {canManage: true})
  equal(
    view.dateDueColumnView.$(`#vdd_tooltip_${this.model.id}_due div dd`).first().text().trim(),
    '29 août'
  )
})

test('renders due date column in appropriate time zone', function () {
  tzInTest.configureAndRestoreLater({
    tz: timezone(juneau, 'America/Juneau'),
    tzData: {
      'America/Juneau': juneau,
    },
  })
  I18nStubber.stub('en', {
    'date.formats.short': '%b %-d',
    'date.abbr_month_names': [0, 1, 2, 3, 4, 5, 6, 7, 'Aug', 9, 10, 11, 12],
  })
  const view = createView(this.model, {canManage: true})
  equal(
    view.dateDueColumnView.$(`#vdd_tooltip_${this.model.id}_due div dd`).first().text().trim(),
    'Aug 28'
  )
})

test('renders link to speed grader if canManage', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Chicken Noodle',
  })
  const view = createView(model, {
    userIsAdmin: true,
    canManage: true,
    show_additional_speed_grader_link: true,
  })
  equal(view.$('.speed-grader-link').length, 1)
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
  ok(view.$('.speed-grader-link-container').attr('class').includes('hidden'))
})

test('speed grader link is correct', () => {
  const model = buildAssignment({
    id: 11,
    title: 'Cream of Mushroom',
  })
  const view = createView(model, {
    userIsAdmin: true,
    canManage: true,
    show_additional_speed_grader_link: true,
  })
  ok(
    view
      .$('.speed-grader-link')[0]
      ?.href.includes('/courses/1/gradebook/speed_grader?assignment_id=11')
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
  ok(json.canDuplicate)
  equal(view.$('.duplicate_assignment').length, 1)
})

test('clicks on Retry button to trigger another duplicating request', () => {
  const model = buildAssignment({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'failed_to_duplicate',
  })
  const view = createView(model)
  sandbox.spy(model, 'duplicate_failed')
  view.$(`#assignment_${model.id} .duplicate-failed-retry`).click()
  ok(model.duplicate_failed.called)
})

test('clicks on Retry button to trigger another migrating request', () => {
  const model = buildAssignment({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'failed_to_migrate',
  })
  const view = createView(model)
  sandbox.spy(model, 'retry_migration')
  view.$(`#assignment_${model.id} .migrate-failed-retry`).click()
  ok(model.retry_migration.called)
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
  notOk(json.canDuplicate)
  equal(view.$('.duplicate_assignment').length, 0)
})

test('displays duplicating message when assignment is duplicating', () => {
  const model = buildAssignment({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'duplicating',
  })
  const view = createView(model)
  ok(view.$el.text().includes('Making a copy of "Foo"'))
})

test('displays failed to duplicate message when assignment failed to duplicate', () => {
  const model = buildAssignment({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'failed_to_duplicate',
  })
  const view = createView(model)
  ok(view.$el.text().includes('Something went wrong with making a copy of "Foo"'))
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
  strictEqual(view.$('button.duplicate-failed-cancel.btn').length, 0)
})

test('displays cancel button when assignment failed to duplicate is not blueprint', () => {
  const model = buildAssignment({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'failed_to_duplicate',
  })
  const view = createView(model)
  ok(view.$('button.duplicate-failed-cancel.btn').text().includes('Cancel'))
})

test('can assign assignment if flag is on and has edit permissions', function () {
  const view = createView(this.model, {
    canManage: true,
    differentiated_modules: true,
  })
  equal(view.$('.assign-to-link').length, 1)
})

test('canot assign assignment if no edit permissions', function () {
  const view = createView(this.model, {
    canManage: false,
    differentiated_modules: true,
  })
  equal(view.$('.assign-to-link').length, 0)
})

test('cannot assign assignment if flag is off', function () {
  const view = createView(this.model, {
    canManage: true,
    differentiated_modules: false,
  })
  equal(view.$('.assign-to-link').length, 0)
})

test('can move when userIsAdmin is true', function () {
  const view = createView(this.model, {
    userIsAdmin: true,
    canManage: false,
  })
  const json = view.toJSON()
  ok(json.canMove)
  notOk(view.className().includes('sort-disabled'))
})

test('can move when canManage is true and the assignment group id is not locked', function () {
  sandbox.stub(this.model, 'canMove').returns(true)
  const view = createView(this.model, {
    userIsAdmin: false,
    canManage: true,
  })
  const json = view.toJSON()
  ok(json.canMove)
  notOk(view.className().includes('sort-disabled'))
})

test('cannot move when canManage is true but the assignment group id is locked', function () {
  sandbox.stub(this.model, 'canMove').returns(false)
  const view = createView(this.model, {
    userIsAdmin: false,
    canManage: true,
  })
  const json = view.toJSON()
  notOk(json.canMove)
  ok(view.className().includes('sort-disabled'))
})

test('cannot move when canManage is false but the assignment group id is not locked', function () {
  sandbox.stub(this.model, 'canMove').returns(true)
  const view = createView(this.model, {
    userIsAdmin: false,
    canManage: false,
  })
  const json = view.toJSON()
  notOk(json.canMove)
  ok(view.className().includes('sort-disabled'))
})

test('re-renders when assignment state changes', function () {
  sandbox.stub(AssignmentListItemView.prototype, 'render')
  createView(this.model)
  ok(AssignmentListItemView.prototype.render.calledOnce)
  this.model.trigger('change:workflow_state')
  ok(AssignmentListItemView.prototype.render.calledTwice)
})

test('polls for updates if assignment is duplicating', function () {
  sandbox.stub(this.model, 'isDuplicating').returns(true)
  createView(this.model)
  ok(this.model.pollUntilFinishedDuplicating.calledOnce)
})

test('polls for updates if assignment is importing', function () {
  sandbox.stub(this.model, 'isImporting').returns(true)
  sandbox.stub(this.model, 'pollUntilFinishedImporting')
  createView(this.model)
  ok(this.model.pollUntilFinishedImporting.calledOnce)
})

QUnit.module('AssignmentListItemViewSpec - editing assignments', function (hooks) {
  hooks.beforeEach(function () {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'},
      current_user__is_admin: false,
    })

    genSetup.call(this)
  })

  hooks.afterEach(function () {
    fakeENV.teardown()
    genTeardown.call(this)
  })

  test('canEdit is true if no individual permissions are set and canManage is true', function () {
    const view = createView(this.model, {
      userIsAdmin: false,
      canManage: true,
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, true)
  })

  test('canEdit is false if no individual permissions are set and canManage is false', function () {
    const view = createView(this.model, {
      userIsAdmin: false,
      canManage: false,
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, false)
  })

  test('canEdit is true if no individual permissions are set and userIsAdmin is true', function () {
    const view = createView(this.model, {
      userIsAdmin: true,
      canManage: false,
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, true)
  })

  test('canEdit is false if canManage is true and the individual assignment cannot be updated', function () {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {update: false},
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, false)
  })

  test('canEdit is true if canManage is true and the individual assignment can be updated', function () {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {update: true},
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, true)
  })

  test('canEdit is false if canManage is true and the update parameter does not exist', function () {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {},
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, false)
  })

  test('edit link is enabled when the individual assignment is editable', function () {
    const view = createView(this.model, {
      individualAssignmentPermissions: {update: true},
    })

    strictEqual(view.$('.edit_assignment').hasClass('disabled'), false)
  })

  test('edit link is disabled when the individual assignment is not editable', function () {
    const view = createView(this.model, {
      individualAssignmentPermissions: {update: false},
    })

    strictEqual(view.$('.edit_assignment').hasClass('disabled'), true)
  })
})

QUnit.module('AssignmentListItemViewSpec - skip to build screen button', function (hooks) {
  hooks.beforeEach(function () {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'},
      QUIZ_LTI_ENABLED: true,
    })
  })

  hooks.afterEach(function () {
    fakeENV.teardown()
    genTeardown.call(this)
  })

  test('canShowBuildLink is true if QUIZ_LTI_ENABLED', function () {
    const view = createView(
      buildAssignment({
        id: 1,
        title: 'Foo',
        is_quiz_lti_assignment: true,
      })
    )
    const json = view.toJSON()
    strictEqual(json.canShowBuildLink, true)
  })

  test('canShowBuildLink is false if the assignment is not a new quiz', function () {
    const view = createView(
      buildAssignment({
        id: 1,
        title: 'Foo',
        is_quiz_lti_assignment: false,
      })
    )

    const json = view.toJSON()
    strictEqual(json.canShowBuildLink, false)
  })
})

QUnit.module('AssignmentListItemViewSpec - deleting assignments', function (hooks) {
  hooks.beforeEach(function () {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'},
    })
    genSetup.call(this)
  })

  hooks.afterEach(function () {
    fakeENV.teardown()
    genTeardown.call(this)
  })

  test('canDelete is true if no individual permissions are set and userIsAdmin is true', function () {
    const view = createView(this.model, {
      userIsAdmin: true,
    })

    const json = view.toJSON()
    strictEqual(json.canDelete, true)
  })

  test('canDelete is false if canManage is true and the individual assignment cannot be deleted', function () {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {delete: false},
    })

    const json = view.toJSON()
    strictEqual(json.canDelete, false)
  })

  test('canDelete is true if canManage is true and the individual assignment can be deleted', function () {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {delete: true},
    })

    const json = view.toJSON()
    strictEqual(json.canDelete, true)
  })

  test('delete link is enabled when canDelete returns true', function () {
    const view = createView(this.model, {
      individualAssignmentPermissions: {delete: true},
    })

    strictEqual(view.$('.delete_assignment').hasClass('disabled'), false)
  })

  test('delete link is disabled when canDelete returns false', function () {
    const view = createView(this.model, {
      individualAssignmentPermissions: {delete: false},
    })

    strictEqual(view.$('.delete_assignment').hasClass('disabled'), true)
  })
})

QUnit.module('AssignmentListItemViewSpec - publish/unpublish icon', function (hooks) {
  hooks.beforeEach(function () {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'},
    })
    genSetup.call(this)
  })

  hooks.afterEach(function () {
    fakeENV.teardown()
    genTeardown.call(this)
  })

  test('publish icon is enabled if the user is an admin', function () {
    const view = createView(this.model, {
      userIsAdmin: true,
      canManage: false,
    })

    strictEqual(view.$('.publish-icon').hasClass('disabled'), false)
  })

  test('publish icon is enabled if canManage is true and the individual assignment can be updated', function () {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {update: true},
    })

    strictEqual(view.$('.publish-icon').hasClass('disabled'), false)
  })

  test('publish icon is disabled if canManage is true and the individual assignment cannot be updated', function () {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {update: false},
    })

    strictEqual(view.$('.publish-icon').hasClass('disabled'), true)
  })
})

QUnit.module('AssignmentListItemViewSpec\u2014alternate grading type: percent', {
  setup() {
    return genSetup.call(this, assignment_grade_percent())
  },
  teardown() {
    return genTeardown.call(this)
  },
})

test('score and grade outputs', function () {
  this.submission.set({
    score: 1.5555,
    grade: 90,
  })
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  ok(screenreaderText().match('Score: 1.56 out of 5 points.')[0], 'sets screenreader score text')
  ok(screenreaderText().match('Grade: 90%')[0], 'sets screenreader grade text')
  ok(nonScreenreaderText().match('1.56/5 pts')[0], 'sets non-screenreader screen text')
  ok(nonScreenreaderText().match('90%')[0], 'sets non-screenreader grade text')
})

test('excused score and grade outputs', function () {
  this.submission.set({excused: true})
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  ok(screenreaderText().match('This assignment has been excused.'))
  ok(nonScreenreaderText().match('Excused'))
})

QUnit.module('AssignmentListItemViewSpec\u2014alternate grading type: pass_fail', {
  setup() {
    return genSetup.call(this, assignment_grade_pass_fail())
  },
  teardown() {
    return genTeardown.call(this)
  },
})

test('score and grade outputs', function () {
  this.submission.set({
    score: 1.5555,
    grade: 'complete',
  })
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  ok(screenreaderText().match('Score: 1.56 out of 5 points.')[0], 'sets screenreader score text')
  ok(screenreaderText().match('Grade: Complete')[0], 'sets screenreader grade text')
  ok(nonScreenreaderText().match('1.56/5 pts')[0], 'sets non-screenreader score text')
  ok(nonScreenreaderText().match('Complete')[0], 'sets non-screenreader grade text')
})

QUnit.module('AssignmentListItemViewSpec\u2014alternate grading type: letter_grade', {
  setup() {
    return genSetup.call(this, assignment_grade_letter_grade())
  },
  teardown() {
    return genTeardown.call(this)
  },
})

test('score and grade outputs', function () {
  this.submission.set({
    score: 1.5555,
    grade: 'B',
  })
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  ok(screenreaderText().match('Score: 1.56 out of 5 points.')[0], 'sets screenreader score text')
  ok(screenreaderText().match('Grade: B')[0], 'sets screenreader grade text')
  ok(nonScreenreaderText().match('1.56/5 pts')[0], 'sets non-screenreader score text')
  ok(nonScreenreaderText().match('B')[0], 'sets non-screenreader grade text')
})

QUnit.module('AssignmentListItemViewSpec\u2014alternate grading type: not_graded', {
  setup() {
    return genSetup.call(this, assignment_grade_not_graded())
  },
  teardown() {
    return genTeardown.call(this)
  },
})

test('score and grade outputs', function () {
  this.submission.set({
    score: 1.5555,
    grade: 'complete',
  })
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  equal(
    screenreaderText(),
    'This assignment will not be assigned a grade.',
    'sets screenreader text'
  )
  equal(nonScreenreaderText(), '', 'sets non-screenreader text')
})

QUnit.module('AssignListItemViewSpec - mastery paths menu option', {
  setup() {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
      URLS: {assignment_sort_base_url: 'test'},
    })
  },
  teardown() {
    fakeENV.teardown()
  },
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
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

test('renders for assignment if cyoe on', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry'],
  })
  const view = createView(model)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 1)
})

test('does not render for ungraded assignment if cyoe on', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_update: true,
    submission_types: ['not_graded'],
  })
  const view = createView(model)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
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
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 1)
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
  equal(view.$('.icon-mastery-path').length, 0)
})

test('renders for graded discussion if cyoe on', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_update: true,
    submission_types: ['discussion_topic'],
  })
  const view = createView(model)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 1)
})

test('does not render for graded page if cyoe on', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_update: true,
    submission_types: ['wiki_page'],
  })
  const view = createView(model)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

QUnit.module('AssignListItemViewSpec - mastery paths link', {
  setup() {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
      CONDITIONAL_RELEASE_ENV: {
        active_rules: [
          {
            trigger_assignment_id: '1',
            scoring_ranges: [
              {assignment_sets: [{assignment_set_associations: [{assignment_id: '2'}]}]},
            ],
          },
        ],
      },
      URLS: {assignment_sort_base_url: 'test'},
    })
    return CyoeHelper.reloadEnv()
  },
  teardown() {
    fakeENV.teardown()
  },
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
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 0)
})

test('does not render for assignment if assignment does not have a rule', () => {
  const model = buildAssignment({
    id: '2',
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry'],
  })
  const view = createView(model)
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 0)
})

test('renders for assignment if assignment has a rule', () => {
  const model = buildAssignment({
    id: '1',
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry'],
  })
  const view = createView(model)
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 1)
})

QUnit.module('AssignListItemViewSpec - mastery paths icon', {
  setup() {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
      CONDITIONAL_RELEASE_ENV: {
        active_rules: [
          {
            trigger_assignment_id: '1',
            scoring_ranges: [
              {assignment_sets: [{assignment_set_associations: [{assignment_id: '2'}]}]},
            ],
          },
        ],
      },
      URLS: {assignment_sort_base_url: 'test'},
    })
    return CyoeHelper.reloadEnv()
  },
  teardown() {
    fakeENV.teardown()
  },
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
  equal(view.$('.mastery-path-icon').length, 0)
})

test('does not render for assignment if assignment is not released by a rule', () => {
  const model = buildAssignment({
    id: '1',
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry'],
  })
  const view = createView(model)
  equal(view.$('.mastery-path-icon').length, 0)
})

test('renders for assignment if assignment is released by a rule', () => {
  const model = buildAssignment({
    id: '2',
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry'],
  })
  const view = createView(model)
  equal(view.$('.mastery-path-icon').length, 1)
})

QUnit.module('AssignListItemViewSpec - assignment icons', {
  setup() {
    fakeENV.setup({
      current_user_roles: ['teacher', 'student'],
      URLS: {assignment_sort_base_url: 'test'},
    })
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('renders discussion icon for discussion topic', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    submission_types: ['discussion_topic'],
  })
  const view = createView(model)
  equal(view.$('i.icon-discussion').length, 1)
})

test('renders quiz icon for old quizzes', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    submission_types: ['online_quiz'],
  })
  const view = createView(model)
  equal(view.$('i.icon-quiz').length, 1)
})

test('renders page icon for wiki page', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    submission_types: ['wiki_page'],
  })
  const view = createView(model)
  equal(view.$('i.icon-document').length, 1)
})

test('renders solid quiz icon for new quizzes', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    is_quiz_lti_assignment: true,
  })
  const view = createView(model, {newquizzes_on_quiz_page: true})
  equal(view.$('i.icon-quiz.icon-Solid').length, 1)
})

test('renders assignment icon for new quizzes if FF is off', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    is_quiz_lti_assignment: true,
  })
  const view = createView(model, {newquizzes_on_quiz_page: false})
  equal(view.$('i.icon-quiz.icon-Solid').length, 0)
  equal(view.$('i.icon-assignment').length, 1)
})

test('renders assignment icon for other assignments', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
  })
  const view = createView(model)
  equal(view.$('i.icon-assignment').length, 1)
})

QUnit.module('Assignment#quizzesRespondusEnabled', hooks => {
  hooks.beforeEach(() => {
    fakeENV.setup({current_user_roles: []})
  })

  hooks.afterEach(() => {
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
    equal(json.quizzesRespondusEnabled, false)
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
    equal(json.quizzesRespondusEnabled, false)
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
    equal(json.quizzesRespondusEnabled, false)
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
    equal(json.quizzesRespondusEnabled, true)
  })
})

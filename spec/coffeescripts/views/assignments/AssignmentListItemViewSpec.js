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

import Backbone from 'Backbone'
import Assignment from 'compiled/models/Assignment'
import Submission from 'compiled/models/Submission'
import AssignmentListItemView from 'compiled/views/assignments/AssignmentListItemView'
import $ from 'jquery'
import tz from 'timezone'
import juneau from 'timezone/America/Juneau'
import french from 'timezone/fr_FR'
import I18nStubber from 'helpers/I18nStubber'
import fakeENV from 'helpers/fakeENV'
import CyoeHelper from 'jsx/shared/conditional_release/CyoeHelper'
import assertions from 'helpers/assertions'
import 'helpers/jquery.simulate'

let screenreaderText = null
let nonScreenreaderText = null
const fixtures = $('#fixtures')
class AssignmentCollection extends Backbone.Collection {
  static initClass() {
    this.prototype.model = Assignment
  }
}
AssignmentCollection.initClass()
const assignment1 = function() {
  const date1 = {
    due_at: '2013-08-28T23:59:00-06:00',
    title: 'Summer Session'
  }
  const date2 = {
    due_at: '2013-08-28T23:59:00-06:00',
    title: 'Winter Session'
  }
  return buildAssignment({
    id: 1,
    name: 'History Quiz',
    description: 'test',
    due_at: '2013-08-21T23:59:00-06:00',
    points_possible: 2,
    position: 1,
    all_dates: [date1, date2]
  })
}
const assignment2 = () =>
  buildAssignment({
    id: 3,
    name: 'Math Quiz',
    due_at: '2013-08-23T23:59:00-06:00',
    points_possible: 10,
    position: 2
  })
const assignment3 = () =>
  buildAssignment({
    id: 2,
    name: 'Science Quiz',
    points_possible: 5,
    position: 3
  })
const assignment_grade_percent = () =>
  buildAssignment({
    id: 2,
    name: 'Science Quiz',
    grading_type: 'percent'
  })
const assignment_grade_pass_fail = () =>
  buildAssignment({
    id: 2,
    name: 'Science Quiz',
    grading_type: 'pass_fail'
  })
const assignment_grade_letter_grade = () =>
  buildAssignment({
    id: 2,
    name: 'Science Quiz',
    grading_type: 'letter_grade'
  })
const assignment_grade_not_graded = () =>
  buildAssignment({
    id: 2,
    name: 'Science Quiz',
    grading_type: 'not_graded'
  })
var buildAssignment = function(options) {
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
    published: true
  }
  Object.assign(base, options)
  const ac = new AssignmentCollection([base])
  sinon.stub(ac.at(0), 'pollUntilFinishedDuplicating')
  return ac.at(0)
}
const createView = function(model, options) {
  options = {
    canManage: true,
    canReadGrades: false,
    ...options
  }
  ENV.PERMISSIONS = {
    manage: options.canManage,
    read_grades: options.canReadGrades
  }

  if (options.individualAssignmentPermissions) {
    ENV.PERMISSIONS.by_assignment_id = {}
    ENV.PERMISSIONS.by_assignment_id[model.id] = options.individualAssignmentPermissions
  }

  ENV.POST_TO_SIS = options.post_to_sis
  ENV.DUPLICATE_ENABLED = options.duplicateEnabled
  const view = new AssignmentListItemView({
    model,
    userIsAdmin: options.userIsAdmin
  })
  view.$el.appendTo($('#fixtures'))
  view.render()
  return view
}
const genModules = function(count) {
  if (count === 1) {
    return ['First']
  } else {
    return ['First', 'Second']
  }
}
const genSetup = function(model = assignment1()) {
  fakeENV.setup({
    current_user_roles: ['teacher'],
    PERMISSIONS: {manage: false},
    URLS: {assignment_sort_base_url: 'test'}
  })
  this.model = model
  this.submission = new Submission()
  this.view = createView(this.model, {canManage: false})
  screenreaderText = () => $.trim(this.view.$('.js-score .screenreader-only').text())
  return (nonScreenreaderText = () => $.trim(this.view.$('.js-score .non-screenreader').text()))
}
const genTeardown = function() {
  fakeENV.teardown()
  $('#fixtures').empty()
}

QUnit.module('AssignmentListItemViewSpec', {
  setup() {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'}
    })
    genSetup.call(this)
    this.snapshot = tz.snapshot()
    return I18nStubber.pushFrame()
  },
  teardown() {
    fakeENV.teardown()
    genTeardown.call(this)
    tz.restore(this.snapshot)
    return I18nStubber.popFrame()
  }
})

test('should be accessible', function(assert) {
  const view = createView(this.model, {canManage: true})
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('initializes child views if can manage', function() {
  const view = createView(this.model, {canManage: true})
  ok(view.publishIconView)
  ok(view.dateDueColumnView)
  ok(view.dateAvailableColumnView)
  ok(view.editAssignmentView)
})

test("initializes no child views if can't manage", function() {
  const view = createView(this.model, {canManage: false})
  ok(!view.publishIconView)
  ok(!view.vddTooltipView)
  ok(!view.editAssignmentView)
})

test('initializes sis toggle if post to sis enabled', function() {
  this.model.set('published', true)
  const view = createView(this.model, {
    canManage: true,
    post_to_sis: true
  })
  ok(view.sisButtonView)
})

test('does not initialize sis toggle if post to sis disabled', function() {
  this.model.set('published', true)
  const view = createView(this.model, {
    canManage: true,
    post_to_sis: false
  })
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if assignment is not graded', function() {
  this.model.set('submission_types', ['not_graded'])
  const view = createView(this.model, {
    canManage: true,
    post_to_sis: true
  })
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if post to sis disabled but can't manage", function() {
  this.model.set('published', true)
  const view = createView(this.model, {
    canManage: false,
    post_to_sis: false
  })
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if sis enabled but can't manage", function() {
  this.model.set('published', true)
  const view = createView(this.model, {
    canManage: false,
    post_to_sis: true
  })
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if post to sis disabled, can't manage and is unpublished", function() {
  this.model.set('published', false)
  const view = createView(this.model, {
    canManage: false,
    post_to_sis: false
  })
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if sis enabled, can't manage and is unpublished", function() {
  this.model.set('published', false)
  const view = createView(this.model, {
    canManage: false,
    post_to_sis: true
  })
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if post to sis disabled, can manage and is unpublished', function() {
  this.model.set('published', false)
  const view = createView(this.model, {
    canManage: true,
    post_to_sis: false
  })
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if sis enabled, can manage and is unpublished', function() {
  this.model.set('published', false)
  const view = createView(this.model, {
    canManage: true,
    post_to_sis: true
  })
  ok(!view.sisButtonView)
})

test('upatePublishState toggles ig-published', function() {
  const view = createView(this.model, {canManage: true})
  ok(view.$('.ig-row').hasClass('ig-published'))
  this.model.set('published', false)
  ok(!view.$('.ig-row').hasClass('ig-published'))
})

test('asks for confirmation before deleting an assignment', function() {
  const view = createView(this.model)
  sandbox.stub(view, 'visibleAssignments').returns([])
  sandbox.stub(window, 'confirm').returns(true)
  sandbox.spy(view, 'delete')
  view.$(`#assignment_${this.model.id} .delete_assignment`).click()
  ok(window.confirm.called)
  ok(view.delete.called)
})

test('does not attempt to delete an assignment due in a closed grading period', function() {
  this.model.set('in_closed_grading_period', true)
  const view = createView(this.model)
  sandbox.stub(window, 'confirm').returns(true)
  sandbox.spy(view, 'delete')
  view.$(`#assignment_${this.model.id} .delete_assignment`).click()
  ok(window.confirm.notCalled)
  ok(view.delete.notCalled)
})

test('delete destroys model', function() {
  const old_asset_string = ENV.context_asset_string
  ENV.context_asset_string = 'course_1'
  const view = createView(this.model)
  sandbox.spy(view.model, 'destroy')
  view.delete()
  ok(view.model.destroy.called)
  ENV.context_asset_string = old_asset_string
})

test('delete calls screenreader message', function() {
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
      locked_for_user: false
    })
  ])
  const view = createView(this.model)
  view.delete()
  sandbox.spy($, 'screenReaderFlashMessage')
  server.respond()
  equal($.screenReaderFlashMessage.callCount, 1)
  ENV.context_asset_string = old_asset_string
})

test('show score if score is set', function() {
  this.submission.set({
    score: 1.5555,
    grade: '1.5555'
  })
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  equal(screenreaderText(), 'Score: 1.56 out of 2 points.', 'sets screenreader text')
  equal(nonScreenreaderText(), '1.56/2 pts', 'sets non-screenreader text')
})

test('do not show score if viewing as non-student', function() {
  const old_user_roles = ENV.current_user_roles
  ENV.current_user_roles = ['user']
  const view = createView(this.model, {canManage: false})
  const str = view.$('.js-score:eq(0) .non-screenreader').html()
  ok(str.search('2 pts') !== -1)
  ENV.current_user_roles = old_user_roles
})

test('show no submission if none exists', function() {
  this.model.set({submission: null})
  equal(
    screenreaderText(),
    'No submission for this assignment. 2 points possible.',
    'sets screenreader text for null points'
  )
  equal(nonScreenreaderText(), '-/2 pts', 'sets non-screenreader text for null points')
})

test('show score if 0 correctly', function() {
  this.submission.set({
    score: 0,
    grade: '0'
  })
  this.model.set('submission', this.submission)
  equal(screenreaderText(), 'Score: 0 out of 2 points.', 'sets screenreader text for 0 points')
  equal(nonScreenreaderText(), '0/2 pts', 'sets non-screenreader text for 0 points')
})

test('show no submission if submission object with no submission type', function() {
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  equal(
    screenreaderText(),
    'No submission for this assignment. 2 points possible.',
    'sets correct screenreader text for not yet graded'
  )
  equal(nonScreenreaderText(), '-/2 pts', 'sets correct non-screenreader text for not yet graded')
})

test('show not yet graded if submission type but no grade', function() {
  this.submission.set({
    submission_type: 'online',
    notYetGraded: true
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

test('focus returns to cog after dismissing dialog', function() {
  const view = createView(this.model, {canManage: true})
  const trigger = view.$(`#assign_${this.model.id}_manage_link`)
  ok(trigger.length, 'there is an a node with the correct id')
  trigger.click()
  view.$(`#assignment_${this.model.id}_settings_edit_item`).click()
  view.editAssignmentView.close()
  equal(document.activeElement, trigger.get(0))
})

test('disallows deleting frozen assignments', function() {
  this.model.set('frozen', true)
  const view = createView(this.model)
  ok(view.$(`#assignment_${this.model.id} a.delete_assignment.disabled`).length)
})

test('disallows deleting assignments due in closed grading periods', function() {
  this.model.set('in_closed_grading_period', true)
  const view = createView(this.model)
  ok(view.$(`#assignment_${this.model.id} a.delete_assignment.disabled`).length)
})

test('allows deleting non-frozen assignments not due in closed grading periods', function() {
  this.model.set('frozen', false)
  this.model.set('in_closed_grading_period', false)
  const view = createView(this.model)
  ok(view.$(`#assignment_${this.model.id} a.delete_assignment:not(.disabled)`).length)
})

test('allows deleting frozen assignments for admins', function() {
  this.model.set('frozen', true)
  const view = createView(this.model, {userIsAdmin: true})
  ok(view.$(`#assignment_${this.model.id} a.delete_assignment:not(.disabled)`).length)
})

test('allows deleting assignments due in closed grading periods for admins', function() {
  this.model.set('any_assignment_in_closed_grading_period', true)
  const view = createView(this.model, {userIsAdmin: true})
  ok(view.$(`#assignment_${this.model.id} a.delete_assignment:not(.disabled)`).length)
})

test('allows publishing', function() {
  this.server = sinon.fakeServer.create()
  this.server.respondWith('PUT', '/api/v1/users/1/assignments/1', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify('')
  ])
  this.model.set('published', false)
  const view = createView(this.model)
  view.$(`#assignment_${this.model.id} .publish-icon`).click()
  this.server.respond()
  equal(this.model.get('published'), true)
  return this.server.restore()
})

test("correctly displays module's name", function() {
  const mods = genModules(1)
  this.model.set('modules', mods)
  const view = createView(this.model)
  ok(
    view
      .$('.modules')
      .text()
      .search(`${mods[0]} Module`) !== -1
  )
})

test("correctly display's multiple modules", function() {
  const mods = genModules(2)
  this.model.set('modules', mods)
  const view = createView(this.model)
  ok(
    view
      .$('.modules')
      .text()
      .search('Multiple Modules') !== -1
  )
  ok(
    view
      .$(`#module_tooltip_${this.model.id}`)
      .text()
      .search(`${mods[0]}`) !== -1
  )
  ok(
    view
      .$(`#module_tooltip_${this.model.id}`)
      .text()
      .search(`${mods[1]}`) !== -1
  )
})

test('render score template with permission', function() {
  const spy = sandbox.spy(AssignmentListItemView.prototype, 'updateScore')
  createView(this.model, {
    canManage: false,
    canReadGrades: true
  })
  ok(spy.called)
})

test('does not render score template without permission', function() {
  const spy = sandbox.spy(AssignmentListItemView.prototype, 'updateScore')
  createView(this.model, {
    canManage: false,
    canReadGrades: false
  })
  equal(spy.callCount, 0)
})

test('renders lockAt/unlockAt with locale-appropriate format string', function() {
  tz.changeLocale(french, 'fr_FR', 'fr')
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {
    'date.formats.short': '%-d %b',
    'date.abbr_month_names.8': 'août'
  })
  const model = buildAssignment({
    id: 1,
    lock_at: '2113-08-28T04:00:00Z',
    all_dates: [
      {
        lock_at: '2113-08-28T04:00:00Z',
        title: 'Summer Session'
      },
      {
        unlock_at: '2113-08-28T04:00:00Z',
        title: 'Winter Session'
      }
    ]
  })
  const view = createView(model, {canManage: true})
  const $dds = view.dateAvailableColumnView.$(`#vdd_tooltip_${this.model.id}_lock div`)
  equal(
    $('span', $dds.first())
      .last()
      .text()
      .trim(),
    '28 août'
  )
  equal(
    $('span', $dds.last())
      .last()
      .text()
      .trim(),
    '28 août'
  )
})

test('renders lockAt/unlockAt in appropriate time zone', function() {
  tz.changeZone(juneau, 'America/Juneau')
  I18nStubber.stub('en', {
    'date.formats.short': '%b %-d',
    'date.abbr_month_names.8': 'Aug'
  })
  const model = buildAssignment({
    id: 1,
    lock_at: '2113-08-28T04:00:00Z',
    all_dates: [
      {
        lock_at: '2113-08-28T04:00:00Z',
        title: 'Summer Session'
      },
      {
        unlock_at: '2113-08-28T04:00:00Z',
        title: 'Winter Session'
      }
    ]
  })
  const view = createView(model, {canManage: true})
  const $dds = view.dateAvailableColumnView.$(`#vdd_tooltip_${this.model.id}_lock div`)
  equal(
    $('span', $dds.first())
      .last()
      .text()
      .trim(),
    'Aug 27'
  )
  equal(
    $('span', $dds.last())
      .last()
      .text()
      .trim(),
    'Aug 27'
  )
})

test('renders lockAt/unlockAt for multiple due dates', () => {
  const now = new Date()
  const model = buildAssignment({
    id: 1,
    all_dates: [{due_at: new Date().toISOString()}, {due_at: new Date().toISOString()}]
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
    unlock_at: future.toISOString()
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
    lock_at: future.toISOString()
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
    unlock_at: past.toISOString()
  })
  const view = createView(model)
  const json = view.toJSON()
  equal(json.showAvailability, false)
})

test('renders due date column with locale-appropriate format string', function() {
  tz.changeLocale(french, 'fr_FR', 'fr')
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {
    'date.formats.short': '%-d %b',
    'date.abbr_month_names.8': 'août'
  })
  const view = createView(this.model, {canManage: true})
  equal(
    view.dateDueColumnView
      .$(`#vdd_tooltip_${this.model.id}_due div dd`)
      .first()
      .text()
      .trim(),
    '29 août'
  )
})

test('renders due date column in appropriate time zone', function() {
  tz.changeZone(juneau, 'America/Juneau')
  I18nStubber.stub('en', {
    'date.formats.short': '%b %-d',
    'date.abbr_month_names.8': 'Aug'
  })
  const view = createView(this.model, {canManage: true})
  equal(
    view.dateDueColumnView
      .$(`#vdd_tooltip_${this.model.id}_due div dd`)
      .first()
      .text()
      .trim(),
    'Aug 28'
  )
})

test('can duplicate when assignment can be duplicated', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_duplicate: true
  })
  const view = createView(model, {
    userIsAdmin: true,
    canManage: true,
    duplicateEnabled: true
  })
  const json = view.toJSON()
  ok(json.canDuplicate)
  equal(view.$('.duplicate_assignment').length, 1)
})

test('cannot duplicate when user is not admin', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_duplicate: true
  })
  const view = createView(model, {
    userIsAdmin: false,
    canManage: false,
    duplicateEnabled: true
  })
  const json = view.toJSON()
  notOk(json.canDuplicate)
  equal(view.$('.duplicate_assignment').length, 0)
})

test('displays duplicating message when assignment is duplicating', function() {
  const model = buildAssignment({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'duplicating'
  })
  const view = createView(model)
  ok(view.$el.text().includes('Making a copy of "Foo"'))
})

test('displays failed to duplicate message when assignment failed to duplicate', function() {
  const model = buildAssignment({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'failed_to_duplicate'
  })
  const view = createView(model)
  ok(view.$el.text().includes('Something went wrong with making a copy of "Foo"'))
})

test('can move when userIsAdmin is true', function() {
  const view = createView(this.model, {
    userIsAdmin: true,
    canManage: false
  })
  const json = view.toJSON()
  ok(json.canMove)
  notOk(view.className().includes('sort-disabled'))
})

test('can move when canManage is true and the assignment group id is not locked', function() {
  sandbox.stub(this.model, 'canMove').returns(true)
  const view = createView(this.model, {
    userIsAdmin: false,
    canManage: true
  })
  const json = view.toJSON()
  ok(json.canMove)
  notOk(view.className().includes('sort-disabled'))
})

test('cannot move when canManage is true but the assignment group id is locked', function() {
  sandbox.stub(this.model, 'canMove').returns(false)
  const view = createView(this.model, {
    userIsAdmin: false,
    canManage: true
  })
  const json = view.toJSON()
  notOk(json.canMove)
  ok(view.className().includes('sort-disabled'))
})

test('cannot move when canManage is false but the assignment group id is not locked', function() {
  sandbox.stub(this.model, 'canMove').returns(true)
  const view = createView(this.model, {
    userIsAdmin: false,
    canManage: false
  })
  const json = view.toJSON()
  notOk(json.canMove)
  ok(view.className().includes('sort-disabled'))
})

test('re-renders when assignment state changes', function() {
  sandbox.stub(AssignmentListItemView.prototype, 'render')
  const view = createView(this.model)
  ok(AssignmentListItemView.prototype.render.calledOnce)
  this.model.trigger('change:workflow_state')
  ok(AssignmentListItemView.prototype.render.calledTwice)
})

test('polls for updates if assignment is duplicating', function() {
  sandbox.stub(this.model, 'isDuplicating').returns(true)
  const view = createView(this.model)
  ok(this.model.pollUntilFinishedDuplicating.calledOnce)
})

test('polls for updates if assignment is importing', function() {
  sandbox.stub(this.model, 'isImporting').returns(true)
  sandbox.stub(this.model, 'pollUntilFinishedImporting')
  const view = createView(this.model)
  ok(this.model.pollUntilFinishedImporting.calledOnce)
})

QUnit.module('AssignmentListItemViewSpec - editing assignments', function(hooks) {
  hooks.beforeEach(function() {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'}
    })

    genSetup.call(this)
  })

  hooks.afterEach(function() {
    fakeENV.teardown()
    genTeardown.call(this)
  })

  test('canEdit is true if no individual permissions are set and canManage is true', function() {
    const view = createView(this.model, {
      userIsAdmin: false,
      canManage: true
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, true)
  })

  test('canEdit is false if no individual permissions are set and canManage is false', function() {
    const view = createView(this.model, {
      userIsAdmin: false,
      canManage: false
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, false)
  })

  test('canEdit is true if no individual permissions are set and userIsAdmin is true', function() {
    const view = createView(this.model, {
      userIsAdmin: true,
      canManage: false
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, true)
  })

  test('canEdit is false if canManage is true and the individual assignment cannot be updated', function() {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {update: false}
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, false)
  })

  test('canEdit is true if canManage is true and the individual assignment can be updated', function() {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {update: true}
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, true)
  })

  test('canEdit is false if canManage is true and the update parameter does not exist', function() {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {}
    })

    const json = view.toJSON()
    strictEqual(json.canEdit, false)
  })

  test('edit link is enabled when the individual assignment is editable', function() {
    const view = createView(this.model, {
      individualAssignmentPermissions: {update: true}
    })

    strictEqual(view.$('.edit_assignment').hasClass('disabled'), false);
  })

  test('edit link is disabled when the individual assignment is not editable', function() {
    const view = createView(this.model, {
      individualAssignmentPermissions: {update: false}
    })

    strictEqual(view.$('.edit_assignment').hasClass('disabled'), true);
  })
});

QUnit.module('AssignmentListItemViewSpec - deleting assignments', function(hooks) {
  hooks.beforeEach(function() {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'}
    })
    genSetup.call(this)
  })

  hooks.afterEach(function() {
    fakeENV.teardown()
    genTeardown.call(this)
  })

  test('canDelete is true if no individual permissions are set and userIsAdmin is true', function() {
    const view = createView(this.model, {
      userIsAdmin: true,
      canManage: false
    })

    const json = view.toJSON()
    strictEqual(json.canDelete, true)
  })

  test('canDelete is false if canManage is true and the individual assignment cannot be updated', function() {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {update: false}
    })

    const json = view.toJSON()
    strictEqual(json.canDelete, false)
  })

  test('canDelete is true if canManage is true and the individual assignment can be updated', function() {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {update: true}
    })

    const json = view.toJSON()
    strictEqual(json.canDelete, true)
  })

  test('delete link is enabled when canDelete returns true', function() {
    const view = createView(this.model, {
      individualAssignmentPermissions: {update: true}
    })

    strictEqual(view.$('.delete_assignment').hasClass('disabled'), false);
  })

  test('delete link is disabled when canDelete returns false', function() {
    const view = createView(this.model, {
      individualAssignmentPermissions: {update: false}
    })

    strictEqual(view.$('.delete_assignment').hasClass('disabled'), true);
  })
})

QUnit.module('AssignmentListItemViewSpec - publish/unpublish icon', function(hooks) {
  hooks.beforeEach(function() {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {assignment_sort_base_url: 'test'}
    })
    genSetup.call(this)
  })

  hooks.afterEach(function() {
    fakeENV.teardown()
    genTeardown.call(this)
  })

  test('publish icon is enabled if the user is an admin', function() {
    const view = createView(this.model, {
      userIsAdmin: true,
      canManage: false
    })

    const json = view.toJSON()
    strictEqual(view.$('.publish-icon').hasClass('disabled'), false);
  })

  test('publish icon is enabled if canManage is true and the individual assignment can be updated', function() {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {update: true}
    })

    const json = view.toJSON()
    strictEqual(view.$('.publish-icon').hasClass('disabled'), false);
  })

  test('publish icon is disabled if canManage is true and the individual assignment cannot be updated', function() {
    const view = createView(this.model, {
      canManage: true,
      individualAssignmentPermissions: {update: false}
    })

    const json = view.toJSON()
    strictEqual(view.$('.publish-icon').hasClass('disabled'), true);
  })
})

QUnit.module('AssignmentListItemViewSpec\u2014alternate grading type: percent', {
  setup() {
    return genSetup.call(this, assignment_grade_percent())
  },
  teardown() {
    return genTeardown.call(this)
  }
})

test('score and grade outputs', function() {
  this.submission.set({
    score: 1.5555,
    grade: 90
  })
  this.model.set('submission', this.submission)
  this.model.trigger('change:submission')
  ok(screenreaderText().match('Score: 1.56 out of 5 points.')[0], 'sets screenreader score text')
  ok(screenreaderText().match('Grade: 90%')[0], 'sets screenreader grade text')
  ok(nonScreenreaderText().match('1.56/5 pts')[0], 'sets non-screenreader screen text')
  ok(nonScreenreaderText().match('90%')[0], 'sets non-screenreader grade text')
})

test('excused score and grade outputs', function() {
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
  }
})

test('score and grade outputs', function() {
  this.submission.set({
    score: 1.5555,
    grade: 'complete'
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
  }
})

test('score and grade outputs', function() {
  this.submission.set({
    score: 1.5555,
    grade: 'B'
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
  }
})

test('score and grade outputs', function() {
  this.submission.set({
    score: 1.5555,
    grade: 'complete'
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
      URLS: {assignment_sort_base_url: 'test'}
    })
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('does not render for assignment if cyoe off', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry']
  })
  const view = createView(model)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

test('renders for assignment if cyoe on', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry']
  })
  const view = createView(model)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 1)
})

test('does not render for ungraded assignment if cyoe on', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_update: true,
    submission_types: ['not_graded']
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
    submission_types: ['online_quiz']
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
    submission_types: ['online_quiz']
  })
  const view = createView(model)
  equal(view.$('.icon-mastery-path').length, 0)
})

test('renders for graded discussion if cyoe on', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_update: true,
    submission_types: ['discussion_topic']
  })
  const view = createView(model)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 1)
})

test('does not render for graded page if cyoe on', () => {
  const model = buildAssignment({
    id: 1,
    title: 'Foo',
    can_update: true,
    submission_types: ['wiki_page']
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
            trigger_assignment: '1',
            scoring_ranges: [{assignment_sets: [{assignments: [{assignment_id: '2'}]}]}]
          }
        ]
      },
      URLS: {assignment_sort_base_url: 'test'}
    })
    return CyoeHelper.reloadEnv()
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('does not render for assignment if cyoe off', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const model = buildAssignment({
    id: '1',
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry']
  })
  const view = createView(model)
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 0)
})

test('does not render for assignment if assignment does not have a rule', () => {
  const model = buildAssignment({
    id: '2',
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry']
  })
  const view = createView(model)
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 0)
})

test('renders for assignment if assignment has a rule', () => {
  const model = buildAssignment({
    id: '1',
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry']
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
            trigger_assignment: '1',
            scoring_ranges: [{assignment_sets: [{assignments: [{assignment_id: '2'}]}]}]
          }
        ]
      },
      URLS: {assignment_sort_base_url: 'test'}
    })
    return CyoeHelper.reloadEnv()
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('does not render for assignment if cyoe off', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const model = buildAssignment({
    id: '2',
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry']
  })
  const view = createView(model)
  equal(view.$('.mastery-path-icon').length, 0)
})

test('does not render for assignment if assignment is not released by a rule', () => {
  const model = buildAssignment({
    id: '1',
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry']
  })
  const view = createView(model)
  equal(view.$('.mastery-path-icon').length, 0)
})

test('renders for assignment if assignment is released by a rule', () => {
  const model = buildAssignment({
    id: '2',
    title: 'Foo',
    can_update: true,
    submission_types: ['online_text_entry']
  })
  const view = createView(model)
  equal(view.$('.mastery-path-icon').length, 1)
})

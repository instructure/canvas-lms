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
import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import AssignmentGroup from 'compiled/models/AssignmentGroup'
import Assignment from 'compiled/models/Assignment'
import AssignmentGroupListItemView from 'compiled/views/assignments/AssignmentGroupListItemView'
import AssignmentListItemView from 'compiled/views/assignments/AssignmentListItemView'
import AssignmentGroupListView from 'compiled/views/assignments/AssignmentGroupListView'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'
import simulate from 'helpers/jquery.simulate'
import elementToggler from 'compiled/behaviors/elementToggler'

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
  return Object.assign(base, options)
}

const group1 = () => buildGroup()

const group2 = () =>
  buildGroup({
    id: 2,
    name: 'Other Assignments',
    position: 2,
    rules: {drop_lowest: 1, drop_highest: 2, never_drop: [3, 4]}
  }) // intentionally include an invalid assignment id

const group3 = () =>
  buildGroup({
    id: 3,
    name: 'Even more Assignments',
    position: 3,
    rules: {drop_lowest: 1, drop_highest: 1}
  })

var buildGroup = function(options) {
  if (options == null) {
    options = {}
  }

  const assignments = [assignment1(), assignment2(), assignment3()]
  const base = {
    id: 1,
    name: 'Assignments',
    position: 1,
    rules: {},
    group_weight: 1,
    assignments
  }
  return Object.assign(base, options)
}

const createAssignmentGroup = function(group) {
  if (group == null) {
    group = buildGroup()
  }
  const groups = new AssignmentGroupCollection([group])
  return groups.models[0]
}

const createView = function(model, options) {
  options = {
    canManage: true,
    ...options
  }
  ENV.PERMISSIONS = {manage: options.canManage}

  const view = new AssignmentGroupListItemView({
    model,
    course: new Backbone.Model({id: 1}),
    userIsAdmin: options.userIsAdmin
  })
  view.$el.appendTo($('#fixtures'))
  view.render()

  return view
}

const createCollectionView = function() {
  const model = group3()
  var options = {
    canManage: true,
    ...options
  }
  ENV.PERMISSIONS = {manage: options.canManage}
  const groupCollection = new AssignmentGroupCollection([model])
  const assignmentGroupsView = new AssignmentGroupListView({
    collection: groupCollection,
    sortURL: 'http://localhost:3000/courses/1/assignments/',
    assignment_sort_base_url: 'http://localhost:3000/courses/1/assignments/',
    course: new Backbone.Model({id: 1})
  })
  assignmentGroupsView.$el.appendTo($('#fixtures'))
  assignmentGroupsView.render()
  return assignmentGroupsView
}
test('shows imported icon when integration_data is not empty', () => {
  ENV.URLS = {sort_url: 'test'}
  const model = createAssignmentGroup()
  model.set('integration_data', {property: 'value'})
  const view = createView(model)
  ok(view.$(`#assignment_group_${model.id} .ig-header-title .icon-sis-imported`).length)
})

test('shows imported icon with custom SIS_NAME when integration_data is not empty', () => {
  ENV.SIS_NAME = 'PowerSchool'
  ENV.URLS = {sort_url: 'test'}
  const model = createAssignmentGroup()
  model.set('integration_data', {property: 'value'})
  const view = createView(model)
  equal(
    view.$(`#assignment_group_${model.id} .ig-header-title .icon-sis-imported`)[0].title,
    'Imported from PowerSchool'
  )
})

test('does not show imported icon when integration_data is not set', () => {
  ENV.URLS = {sort_url: 'test'}
  const model = createAssignmentGroup()
  const view = createView(model)
  ok(!view.$(`#assignment_group_${model.id} .ig-header-title .icon-sis-imported`).length)
})

test('does not show imported icon when integration_data is empty', () => {
  ENV.URLS = {sort_url: 'test'}
  const model = createAssignmentGroup()
  model.set('integration_data', {})
  const view = createView(model)
  ok(!view.$(`#assignment_group_${model.id} .ig-header-title .icon-sis-imported`).length)
})

QUnit.module('AssignmentGroupListItemView as a teacher', {
  setup() {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      URLS: {sort_url: 'test'}
    })

    this.model = createAssignmentGroup()
    $(document).off()
    return elementToggler.bind()
  },

  teardown() {
    fakeENV.teardown()
    $('#fixtures').empty()
    return $('form.dialogFormView').remove()
  }
})

test('initializes collection', function() {
  const view = createView(this.model)
  ok(view.collection)
})

test('drags icon not being overridden on drag', () => {
  const view = createCollectionView()
  const assignmentGroups = {item: view.$el.find('.search_show')}
  view.$el.find('#assignment_1').trigger('sortstart', assignmentGroups)
  const dragHandle = view
    .$('#assignment_1')
    .find('i')
    .attr('class')
  equal(dragHandle, 'icon-drag-handle')
})

test('does not parse response with multiple due dates', function() {
  const {models} = this.model.get('assignments')
  const a1 = models[0]
  const a2 = models[1]

  sandbox.spy(a1, 'doNotParse')
  sandbox.spy(a2, 'doNotParse')

  createView(this.model)

  // first assignment has multiple due dates
  ok(a1.multipleDueDates())
  ok(a1.doNotParse.called)

  // second assignment has single due dates
  ok(!a2.multipleDueDates())
  ok(!a2.doNotParse.called)
})

test('initializes child views if can manage', function() {
  const view = createView(this.model)
  ok(view.editGroupView)
  ok(view.createAssignmentView)
  ok(view.deleteGroupView)
})

test('initializes editGroupView with userIsAdmin property', function() {
  let view = createView(this.model, {userIsAdmin: true})
  ok(view.editGroupView.userIsAdmin)
  view = createView(this.model, {userIsAdmin: false})
  notOk(view.editGroupView.userIsAdmin)
})

test("initializes no child views if can't manage", function() {
  const view = createView(this.model, {canManage: false})
  ok(!view.editGroupView)
  ok(!view.createAssignmentView)
  ok(!view.deleteGroupView)
})

test('initializes cache', function() {
  const view = createView(this.model)
  ok(view.cache)
})

test('toJSON includes group weight', function() {
  const view = createView(this.model)
  const json = view.toJSON()
  equal(json.groupWeight, 1)
})

test('shouldBeExpanded returns cache state', function() {
  const view = createView(this.model)
  //make sure the cache starts at true
  if (!view.shouldBeExpanded()) {
    view.toggleCache()
  }
  const key = view.cache.toKey(view.cacheKey())

  ok(view.shouldBeExpanded())
  equal(localStorage[key], 'true')

  view.toggleCache()
  ok(!view.shouldBeExpanded())
  equal(localStorage[key], 'false')
})

test('toggleCache correctly toggles cache state', function() {
  const view = createView(this.model)
  //make sure the cache starts at true
  if (!view.shouldBeExpanded()) {
    view.toggleCache()
  }

  view.toggleCache()

  ok(!view.shouldBeExpanded())
  view.toggleCache()
  ok(view.shouldBeExpanded())
})

test('currentlyExpanded returns expanded state', function() {
  const view = createView(this.model)
  //make sure the cache starts at true
  if (!view.shouldBeExpanded()) {
    view.toggleCache()
  }
  ok(view.currentlyExpanded())
})

test('toggleCollapse toggles expansion', function() {
  const view = createView(this.model)
  const $toggle_el = view.$el.find('.element_toggler')
  //make sure the cache starts at true
  if (!view.shouldBeExpanded()) {
    view.toggleCache()
  }

  ok(view.currentlyExpanded())

  view.toggleCollapse()
  ok(!view.currentlyExpanded())

  view.toggleCollapse()
  ok(view.currentlyExpanded())
})

test('displayableRules', () => {
  const model = createAssignmentGroup(group2())
  const view = createView(model)
  equal(view.displayableRules().length, 3)
})

test('cacheKey builds unique key', function() {
  const view = createView(this.model)
  deepEqual(view.cacheKey(), ['course', 1, 'user', '1', 'ag', 1, 'expanded'])
})

test('disallows deleting groups with frozen assignments', function() {
  const assignments = this.model.get('assignments')
  assignments.first().set('frozen', true)
  const view = createView(this.model)
  ok(view.$(`#assignment_group_${this.model.id} a.delete_group.disabled`).length)
})

test('disallows deleting groups with assignments due in closed grading periods', function() {
  this.model.set('any_assignment_in_closed_grading_period', true)
  const assignments = this.model.get('assignments')
  assignments.first().set('frozen', false)
  const view = createView(this.model)
  ok(view.$(`#assignment_group_${this.model.id} a.delete_group.disabled`).length)
})

test('allows deleting non-frozen groups without assignments due in closed grading periods', function() {
  this.model.set('any_assignment_in_closed_grading_period', false)
  const view = createView(this.model)
  ok(view.$(`#assignment_group_${this.model.id} a.delete_group:not(.disabled)`).length)
})

test('allows deleting frozen groups for admins', function() {
  const assignments = this.model.get('assignments')
  assignments.first().set('frozen', true)
  const view = createView(this.model, {userIsAdmin: true})
  ok(view.$(`#assignment_group_${this.model.id} a.delete_group:not(.disabled)`).length)
})

test('allows deleting groups with assignments due in closed grading periods for admins', function() {
  this.model.set('any_assignment_in_closed_grading_period', true)
  const view = createView(this.model, {userIsAdmin: true})
  ok(view.$(`#assignment_group_${this.model.id} a.delete_group:not(.disabled)`).length)
})

test('does not provide a view to delete a group with assignments due in a closed grading period', function() {
  this.model.set('any_assignment_in_closed_grading_period', true)
  const view = createView(this.model)
  ok(!view.deleteGroupView)
})

test('correctly displays rules tooltip', () => {
  const model = createAssignmentGroup(group3())
  const view = createView(model)
  const anchor = view.$('#assignment_group_3 .ag-header-controls .tooltip_link')
  equal(anchor.text(), '2 Rules')
  equal(anchor.attr('title'), 'Drop the lowest score and Drop the highest score')
})

QUnit.module('AssignmentGroupListItemView as an admin', {
  setup() {
    this.model = createAssignmentGroup()
    $(document).off()
    elementToggler.bind()
    fakeENV.setup({URLS: {sort_url: 'test'}})
  },
  teardown() {
    $('form.dialogFormView').remove()
    $('#fixtures').empty()
    fakeENV.teardown()
  }
})

test('provides a view to delete a group when canDelete is true', function() {
  sandbox.stub(this.model, 'canDelete').returns(true)
  this.model.set('any_assignment_in_closed_grading_period', true)
  const view = createView(this.model, {userIsAdmin: true})
  ok(view.deleteGroupView)
  notOk(view.$(`#assignment_group_${this.model.id} a.delete_group.disabled`).length)
})

test('provides a view to delete a group when canDelete is false', function() {
  sandbox.stub(this.model, 'canDelete').returns(false)
  this.model.set('any_assignment_in_closed_grading_period', true)
  const view = createView(this.model, {userIsAdmin: true})
  ok(view.deleteGroupView)
  notOk(view.$(`#assignment_group_${this.model.id} a.delete_group.disabled`).length)
})

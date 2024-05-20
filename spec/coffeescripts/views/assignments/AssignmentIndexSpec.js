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

import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import Course from '@canvas/courses/backbone/models/Course'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import AssignmentGroupListView from 'ui/features/assignment_index/backbone/views/AssignmentGroupListView'
import AssignmentSettingsView from 'ui/features/assignment_index/backbone/views/AssignmentSettingsView'
import AssignmentSyncSettingsView from 'ui/features/assignment_index/backbone/views/AssignmentSyncSettingsView'
import AssignmentGroupWeightsView from 'ui/features/assignment_index/backbone/views/AssignmentGroupWeightsView'
import IndexView from 'ui/features/assignment_index/backbone/views/IndexView'
import ToggleShowByView from 'ui/features/assignment_index/backbone/views/ToggleShowByView'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import '@canvas/jquery/jquery.simulate'

const fixtures = $('#fixtures')

let assignmentGroups = null

function assignmentIndex(opts = {withAssignmentSettings: false}) {
  $('<div id="content"></div>').appendTo(fixtures)

  const course = new Course({id: 1})

  const group1 = new AssignmentGroup({
    name: 'Group 1',
    assignments: [
      {id: 1, name: 'Foo Name'},
      {id: 2, name: 'Bar Title'},
    ],
  })
  const group2 = new AssignmentGroup({
    name: 'Group 2',
    assignments: [
      {id: 1, name: 'Baz Title'},
      {id: 2, name: 'Qux Name'},
    ],
  })
  assignmentGroups = new AssignmentGroupCollection([group1, group2], {course})

  let assignmentSettingsView = false
  let assignmentSyncSettingsView = false
  if (opts.withAssignmentSettings)
    assignmentSettingsView = new AssignmentSettingsView({
      model: course,
      assignmentGroups,
      weightsView: AssignmentGroupWeightsView,
      userIsAdmin: true,
    })
  assignmentSyncSettingsView = new AssignmentSyncSettingsView({
    collection: assignmentGroups,
    model: course,
    sisName: 'ENV.SIS_NAME',
  })

  const assignmentGroupsView = new AssignmentGroupListView({
    collection: assignmentGroups,
    course,
  })

  let showByView = false
  if (!ENV.PERMISSIONS.manage) {
    showByView = new ToggleShowByView({
      course,
      assignmentGroups,
    })
  }

  const app = new IndexView({
    assignmentGroupsView,
    collection: assignmentGroups,
    createGroupView: false,
    assignmentSettingsView,
    assignmentSyncSettingsView,
    showByView,
    ...opts,
  })

  return app.render()
}

QUnit.module('AssignmentIndex', {
  setup() {
    fakeENV.setup({
      PERMISSIONS: {manage: true},
      URLS: {
        assignment_sort_base_url: 'test',
      },
    })
    this.enable_spy = sandbox.spy(IndexView.prototype, 'enableSearch')
  },

  teardown() {
    fakeENV.teardown()
    assignmentGroups = null
    fixtures.empty()
  },
})

// eslint-disable-next-line qunit/resolve-async
test('should be accessible', assert => {
  const view = assignmentIndex()
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('should filter by search term', () => {
  const view = assignmentIndex()
  $('#search_term').val('foo')
  view.filterResults()
  equal(view.$el.find('.assignment').not('.hidden').length, 1)

  $('#search_term').val('BooBerry')
  view.filterResults()
  equal(view.$el.find('.assignment').not('.hidden').length, 0)

  $('#search_term').val('name')
  view.filterResults()
  equal(view.$el.find('.assignment').not('.hidden').length, 2)
})

test('should have search disabled on render', () => {
  const view = assignmentIndex()
  ok(view.$('#search_term').is(':disabled'))
})

test('should enable search on assignmentGroup reset', () => {
  const view = assignmentIndex()
  assignmentGroups.reset()
  ok(!view.$('#search_term').is(':disabled'))
})

test('enable search handler should only fire on the first reset', function () {
  assignmentIndex()
  assignmentGroups.reset()
  ok(this.enable_spy.calledOnce)
  // reset a second time and make sure it was still only called once
  assignmentGroups.reset()
  ok(this.enable_spy.calledOnce)
})

test('should show modules column', () => {
  const view = assignmentIndex()

  const [a1, a2] = assignmentGroups.assignments()
  a1.set('modules', ['One', 'Two'])
  a2.set('modules', ['Three'])

  ok(
    view
      .$('#assignment_1 .modules .tooltip_link')
      .text()
      .match(/Multiple Modules/)
  )
  ok(
    view
      .$('#assignment_1 .modules')
      .text()
      .match(/One\s+Two/)
  )
  ok(
    view
      .$('#assignment_2 .modules')
      .text()
      .match(/Three Module/)
  )
})

test("should show 'Add Quiz/Test' button if quiz lti is enabled", () => {
  ENV.FEATURES.instui_nav = true
  ENV.PERMISSIONS.manage_assignments_add = true
  ENV.QUIZ_LTI_ENABLED = true
  const view = assignmentIndex({withAssignmentSettings: true})
  const $button = view.$('#new_quiz_lti')
  equal($button.length, 1)
  ok(/\?quiz_lti$/.test($button.attr('href')))
})

test("should not show 'Add Quiz/Test' button if quiz lti is not enabled", () => {
  ENV.FEATURES.instui_nav = true
  ENV.PERMISSIONS.manage_assignments_add = true
  ENV.QUIZ_LTI_ENABLED = false
  const view = assignmentIndex({withAssignmentSettings: true})
  equal(view.$('#new_quiz_lti').length, 0)
})

test('should contain a drag and drop warning for screen readers', () => {
  const view = assignmentIndex()
  equal(view.$('.drag_and_drop_warning').length, 1)
})

QUnit.module('student index view', {
  setup() {
    fakeENV.setup({
      PERMISSIONS: {manage: false},
      URLS: {
        assignment_sort_base_url: 'test',
      },
    })
  },

  teardown() {
    fakeENV.teardown()
    assignmentGroups = null
    fixtures.empty()
  },
})

test('should not contain a drag and drop warning for screen readers', () => {
  const view = assignmentIndex()
  equal(view.$('.drag_and_drop_warning').length, 0)
})

test('should clear search on toggle', () => {
  const clear_spy = sandbox.spy(IndexView.prototype, 'clearSearch')
  const view = assignmentIndex()
  view.$('#search_term').val('something')
  view.showByView.initializeCache()
  view.showByView.toggleShowBy('date')
  equal(view.$('#search_term').val(), '')
  ok(clear_spy.called)
})

QUnit.module('AssignmentIndex - bulk edit', {
  setup() {
    fakeENV.setup({
      PERMISSIONS: {manage_assignments: true},
      URLS: {
        new_assignment_url: 'test',
      },
    })
  },

  teardown() {
    fakeENV.teardown()
    fixtures.empty()
  },
})

test('it should show bulk edit menu', () => {
  const view = assignmentIndex({withAssignmentSettings: true})
  equal(view.$('#requestBulkEditMenuItem').length, 1)
})

// If we actually try to render the bulk edit interface, we have to wait for the
// interface to load and then mock the fetch and wait for that. Not worth it for
// now.
QUnit.skip(
  'it should show only the bulk edit interface when the bulk edit menu item is clicked',
  () => {
    const view = assignmentIndex({withAssignmentSettings: true})
    view.$('#requestBulkEditMenuItem')[0].click()
    equal(view.$('#bulkEditRoot').length, 1)
    equal(view.$('.header-bar').length, 0)
  }
)

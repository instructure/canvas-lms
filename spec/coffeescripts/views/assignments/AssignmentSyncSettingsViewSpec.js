/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import Course from 'compiled/models/Course'
import AssignmentGroup from 'compiled/models/AssignmentGroup'
import AssignmentSyncSettingsView from 'compiled/views/assignments/AssignmentSyncSettingsView'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'
import 'helpers/jquery.simulate'

const group = (opts = {}) =>
  new AssignmentGroup({
    group_weight: 50,
    ...opts
  })
const assignmentGroups = function() {
  this.groups = new AssignmentGroupCollection([group(), group()])
}
const createView = function(opts = {}) {
  this.course = new Course()
  this.course.urlRoot = '/courses/1'
  const view = new AssignmentSyncSettingsView({
    model: this.course,
    userIsAdmin: opts.userIsAdmin,
    sisName: 'PowerSchool'
  })
  view.open()
  return view
}

QUnit.module('AssignmentSyncSettingsView', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('openDisableSync sets viewToggle to true', () => {
  const view = createView()
  view.openDisableSync()
  equal(view.viewToggle, true)
  return view.remove()
})

test('currentGradingPeriod returns "" if a grading period is not selected', () => {
  const view = createView()
  const grading_period_id = view.currentGradingPeriod()
  equal(grading_period_id, '')
  return view.remove()
})

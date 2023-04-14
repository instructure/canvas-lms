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

import Course from '@canvas/courses/backbone/models/Course'
import AssignmentSyncSettingsView from 'ui/features/assignment_index/backbone/views/AssignmentSyncSettingsView'
import fakeENV from 'helpers/fakeENV'

const createView = function (opts = {}) {
  const course = new Course()
  course.urlRoot = '/courses/1'
  const view = new AssignmentSyncSettingsView({
    model: course,
    userIsAdmin: opts.userIsAdmin,
    sisName: 'PowerSchool',
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
  },
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

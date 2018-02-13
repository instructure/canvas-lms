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

import AssignmentGroup from 'compiled/models/AssignmentGroup'
import Assignment from 'compiled/models/Assignment'
import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import Course from 'compiled/models/Course'
import fakeENV from 'helpers/fakeENV'

const COURSE_SUBMISSIONS_URL = '/courses/1/submissions'

QUnit.module('AssignmentGroupCollection', {
  setup() {
    fakeENV.setup()
    this.server = sinon.fakeServer.create()
    this.assignments = [1, 2, 3, 4].map(id => new Assignment({id}))
    this.group = new AssignmentGroup({assignments: this.assignments})
    this.collection = new AssignmentGroupCollection([this.group], {
      courseSubmissionsURL: COURSE_SUBMISSIONS_URL
    })
  },
  teardown() {
    fakeENV.teardown()
    this.server.restore()
  }
})

test('::model is AssignmentGroup', () =>
  strictEqual(AssignmentGroupCollection.prototype.model, AssignmentGroup))

test('default params include assignments and not discussion topics', () => {
  const {include} = AssignmentGroupCollection.prototype.defaults.params
  deepEqual(include, ['assignments'], 'include only contains assignments')
})

test('optionProperties', () => {
  const course = new Course()
  const collection = new AssignmentGroupCollection([], {
    course,
    courseSubmissionsURL: COURSE_SUBMISSIONS_URL
  })
  strictEqual(
    collection.courseSubmissionsURL,
    COURSE_SUBMISSIONS_URL,
    'assigns courseSubmissionsURL to this.courseSubmissionsURL'
  )
  strictEqual(collection.course, course, 'assigns course to this.course')
})

test('(#getGrades) loading grades from the server', function() {
  ENV.observed_student_ids = []
  ENV.PERMISSIONS.read_grades = true
  let triggeredChangeForAssignmentWithoutSubmission = false
  const submissions = [1, 2, 3].map(id => ({
    id,
    assignment_id: id,
    grade: id
  }))
  this.server.respondWith('GET', `${COURSE_SUBMISSIONS_URL}?per_page=50`, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(submissions)
  ])
  const lastAssignment = this.assignments[3]
  lastAssignment.on(
    'change:submission',
    () => (triggeredChangeForAssignmentWithoutSubmission = true)
  )
  this.collection.getGrades()
  this.server.respond()
  for (const assignment of this.assignments) {
    if (assignment.get('id') === 4) continue
    equal(
      assignment.get('submission').get('grade'),
      assignment.get('id'),
      'sets submission grade for assignments with a matching submission'
    )
  }
  ok(
    triggeredChangeForAssignmentWithoutSubmission,
    'triggers change for assignments without a matching submission grade so the UI can update'
  )
})

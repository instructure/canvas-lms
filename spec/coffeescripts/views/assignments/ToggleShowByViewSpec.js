//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import _ from 'underscore'
import AssignmentGroup from 'compiled/models/AssignmentGroup'
import Course from 'compiled/models/Course'
import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import ToggleShowByView from 'compiled/views/assignments/ToggleShowByView'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'

const COURSE_SUBMISSIONS_URL = '/courses/1/submissions'

const createView = function() {
  ENV.PERMISSIONS = {manage: false, read_grades: true}
  const course = new Course({id: 1})
  // the dates are in opposite order of what they will be sorted into
  const assignments = [
    {
      id: 1,
      name: 'Past Assignments',
      due_at: new Date(2013, 8, 20),
      position: 1,
      submission_types: ['online']
    },
    {
      id: 2,
      name: 'Past Assignments',
      due_at: new Date(2013, 8, 21),
      position: 2,
      submission_types: ['on_paper']
    },
    {
      id: 3,
      name: 'Upcoming Assignments',
      due_at: new Date(3013, 8, 21),
      position: 1
    },
    {
      id: 4,
      name: 'Overdue Assignments',
      due_at: new Date(2013, 8, 21),
      position: 1,
      submission_types: ['online']
    },
    {
      id: 5,
      name: 'Past Assignments',
      due_at: new Date(2013, 8, 22),
      position: 3,
      submission_types: ['online']
    },
    {
      id: 6,
      name: 'Overdue Assignments',
      due_at: new Date(2013, 8, 20),
      position: 2,
      submission_types: ['online']
    },
    {
      id: 7,
      name: 'Undated Assignments'
    },
    {
      id: 8,
      name: 'Upcoming Assignments',
      due_at: new Date(3013, 8, 20),
      position: 2
    }
  ]
  const group = new AssignmentGroup({assignments})
  const collection = new AssignmentGroupCollection([group], {
    courseSubmissionsURL: COURSE_SUBMISSIONS_URL,
    course
  })
  return new ToggleShowByView({course, assignmentGroups: collection})
}

const getGrades = function(collection, server) {
  const submissions = [
    {id: 1, assignment_id: 1, grade: 305},
    {id: 2, assignment_id: 4},
    {id: 3, assignment_id: 5, submission_type: 'online'}
  ]
  let url = `${COURSE_SUBMISSIONS_URL}?`
  if (ENV.observed_student_ids.length === 1) {
    url = `${url}student_ids[]=${ENV.observed_student_ids[0]}&`
  }
  url = `${url}per_page=50`

  server.respondWith('GET', url, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(submissions)
  ])

  collection.getGrades()
  return server.respond()
}

QUnit.module('ToggleShowByView', {
  setup() {
    this.server = sinon.fakeServer.create()
    fakeENV.setup()
    ENV.observed_student_ids = []
  },

  teardown() {
    fakeENV.teardown()
    this.server.restore()
    $('.ui-dialog').remove()
    $('ul[id^=ui-id-]').remove()
  }
})

test('should be accessible', assert => {
  const view = createView(true)
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('should sort assignments into groups correctly', function() {
  const view = createView()
  getGrades(view.assignmentGroups, this.server)

  equal(view.assignmentGroups.length, 4)
  view.assignmentGroups.each(group => {
    const assignments = group.get('assignments').models
    _.each(assignments, as => equal(group.name(), as.name()))
  })
})

test('should sort assignments by date correctly', function() {
  const view = createView(true)
  getGrades(view.assignmentGroups, this.server)

  // check past assignment sorting (descending)
  const past = view.assignmentGroups.findWhere({id: 'past'})
  let assignments = past.get('assignments').models
  equal(assignments[0].get('due_at'), new Date(2013, 8, 22).toString())
  equal(assignments[1].get('due_at'), new Date(2013, 8, 21).toString())
  equal(assignments[2].get('due_at'), new Date(2013, 8, 20).toString())

  // check overdue assignment sorting (ascending)
  const overdue = view.assignmentGroups.findWhere({id: 'overdue'})
  assignments = overdue.get('assignments').models
  equal(assignments[0].get('due_at'), new Date(2013, 8, 20).toString())
  equal(assignments[1].get('due_at'), new Date(2013, 8, 21).toString())

  // check upcoming assignment sorting (ascending)
  const upcoming = view.assignmentGroups.findWhere({id: 'upcoming'})
  assignments = upcoming.get('assignments').models
  equal(assignments[0].get('due_at'), new Date(3013, 8, 20).toString())
  equal(assignments[1].get('due_at'), new Date(3013, 8, 21).toString())
})

test('observer view who are not observing a student', function() {
  // Regular observer view
  ENV.current_user_has_been_observer_in_this_course = true
  const view = createView()
  getGrades(view.assignmentGroups, this.server)

  const past = view.assignmentGroups.findWhere({id: 'past'})
  let assignments = past.get('assignments').models
  equal(assignments.length, 5)

  const overdue = view.assignmentGroups.findWhere({id: 'overdue'})
  equal(overdue, undefined)

  const upcoming = view.assignmentGroups.findWhere({id: 'upcoming'})
  assignments = upcoming.get('assignments').models
  equal(assignments.length, 2)
})

test('observer view who are observing a student', function() {
  ENV.current_user_has_been_observer_in_this_course = true
  ENV.observed_student_ids = ['1']
  const view = createView()
  getGrades(view.assignmentGroups, this.server)

  const past = view.assignmentGroups.findWhere({id: 'past'})
  let assignments = past.get('assignments').models
  equal(assignments.length, 3)

  const overdue = view.assignmentGroups.findWhere({id: 'overdue'})
  assignments = overdue.get('assignments').models
  equal(assignments.length, 2)

  const upcoming = view.assignmentGroups.findWhere({id: 'upcoming'})
  assignments = upcoming.get('assignments').models
  equal(assignments.length, 2)
})

// This will change in the future from a basic observer with no observing students to
// way of selecting which student to observer for now though it defaults to a standard observer
test('observer view who are observing multiple students', function() {
  ENV.observed_student_ids = ['1', '2']
  ENV.current_user_has_been_observer_in_this_course = true
  const view = createView()
  getGrades(view.assignmentGroups, this.server)
  const past = view.assignmentGroups.findWhere({id: 'past'})
  let assignments = past.get('assignments').models
  equal(assignments.length, 5)

  const overdue = view.assignmentGroups.findWhere({id: 'overdue'})
  equal(overdue, undefined)

  const upcoming = view.assignmentGroups.findWhere({id: 'upcoming'})
  assignments = upcoming.get('assignments').models
  equal(assignments.length, 2)
})

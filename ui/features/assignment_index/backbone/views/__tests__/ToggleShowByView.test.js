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

import _ from 'lodash'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import Course from '@canvas/courses/backbone/models/Course'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import ToggleShowByView from '../ToggleShowByView'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import {isAccessible} from '@canvas/test-utils/jestAssertions'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const equal = (x, y) => expect(x).toEqual(y)

const COURSE_SUBMISSIONS_URL = '/courses/1/submissions'

const createView = function () {
  ENV.PERMISSIONS = {manage: false, read_grades: true}
  const course = new Course({id: 1})
  // the dates are in opposite order of what they will be sorted into
  const assignments = [
    {
      id: 1,
      name: 'Past Assignments',
      due_at: new Date(2013, 8, 20),
      position: 1,
      submission_types: ['online'],
    },
    {
      id: 2,
      name: 'Past Assignments',
      due_at: new Date(2013, 8, 21),
      position: 2,
      submission_types: ['on_paper'],
    },
    {
      id: 3,
      name: 'Upcoming Assignments',
      due_at: new Date(3013, 8, 21),
      position: 1,
    },
    {
      id: 4,
      name: 'Overdue Assignments',
      due_at: new Date(2013, 8, 21),
      position: 1,
      submission_types: ['online'],
    },
    {
      id: 5,
      name: 'Past Assignments',
      due_at: new Date(2013, 8, 22),
      position: 3,
      submission_types: ['online'],
    },
    {
      id: 6,
      name: 'Overdue Assignments',
      due_at: new Date(2013, 8, 20),
      position: 2,
      submission_types: ['online'],
    },
    {
      id: 7,
      name: 'Undated Assignments',
    },
    {
      id: 8,
      name: 'Upcoming Assignments',
      due_at: new Date(3013, 8, 20),
      position: 2,
    },
  ]
  const group = new AssignmentGroup({assignments})
  const collection = new AssignmentGroupCollection([group], {
    courseSubmissionsURL: COURSE_SUBMISSIONS_URL,
    course,
  })
  return new ToggleShowByView({course, assignmentGroups: collection})
}

const getGrades = async function (collection) {
  await collection.getGrades()
}

const submissions = [
  {id: 1, assignment_id: 1, grade: 305},
  {id: 2, assignment_id: 4},
  {id: 3, assignment_id: 5, submission_type: 'online'},
]

const server = setupServer(
  http.get('/courses/1/submissions', () => {
    return HttpResponse.json(submissions)
  }),
)

describe('ToggleShowByView', function () {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup()
    ENV.observed_student_ids = []
  })

  afterEach(() => {
    fakeENV.teardown()
    $('.ui-dialog').remove()
    $('ul[id^=ui-id-]').remove()
  })

  test('should be accessible', done => {
    const view = createView(true)
    isAccessible(view, done, {a11yReport: true})
  })

  test('should sort assignments into groups correctly', async function () {
    const view = createView()
    await getGrades(view.assignmentGroups)

    equal(view.assignmentGroups.length, 4)
    view.assignmentGroups.each(group => {
      const assignments = group.get('assignments').models
      _.each(assignments, as => equal(group.name(), as.name()))
    })
  })

  test('should sort assignments by date correctly', async function () {
    const view = createView(true)
    await getGrades(view.assignmentGroups)

    // check past assignment sorting (descending)
    const past = view.assignmentGroups.findWhere({id: 'past'})
    let assignments = past.get('assignments').models
    equal(assignments[0].get('due_at'), new Date(2013, 8, 22))
    equal(assignments[1].get('due_at'), new Date(2013, 8, 21))
    equal(assignments[2].get('due_at'), new Date(2013, 8, 20))

    // check overdue assignment sorting (ascending)
    const overdue = view.assignmentGroups.findWhere({id: 'overdue'})
    assignments = overdue.get('assignments').models
    equal(assignments[0].get('due_at'), new Date(2013, 8, 20))
    equal(assignments[1].get('due_at'), new Date(2013, 8, 21))

    // check upcoming assignment sorting (ascending)
    const upcoming = view.assignmentGroups.findWhere({id: 'upcoming'})
    assignments = upcoming.get('assignments').models
    equal(assignments[0].get('due_at'), new Date(3013, 8, 20))
    equal(assignments[1].get('due_at'), new Date(3013, 8, 21))
  })

  test('observer view who are not observing a student', async function () {
    // Regular observer view
    ENV.current_user_has_been_observer_in_this_course = true
    const view = createView()
    await getGrades(view.assignmentGroups)

    const past = view.assignmentGroups.findWhere({id: 'past'})
    let assignments = past.get('assignments').models
    equal(assignments.length, 5)

    const overdue = view.assignmentGroups.findWhere({id: 'overdue'})
    equal(overdue, undefined)

    const upcoming = view.assignmentGroups.findWhere({id: 'upcoming'})
    assignments = upcoming.get('assignments').models
    equal(assignments.length, 2)
  })

  test('observer view who are observing a student', async function () {
    ENV.current_user_has_been_observer_in_this_course = true
    ENV.observed_student_ids = ['1']
    const view = createView()
    await getGrades(view.assignmentGroups)

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
  test('observer view who are observing multiple students', async function () {
    ENV.observed_student_ids = ['1', '2']
    ENV.current_user_has_been_observer_in_this_course = true
    const view = createView()
    await getGrades(view.assignmentGroups)
    const past = view.assignmentGroups.findWhere({id: 'past'})
    let assignments = past.get('assignments').models
    equal(assignments.length, 5)

    const overdue = view.assignmentGroups.findWhere({id: 'overdue'})
    equal(overdue, undefined)

    const upcoming = view.assignmentGroups.findWhere({id: 'upcoming'})
    assignments = upcoming.get('assignments').models
    equal(assignments.length, 2)
  })
})

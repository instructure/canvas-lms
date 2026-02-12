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
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import Course from '@canvas/courses/backbone/models/Course'
import fakeENV from '@canvas/test-utils/fakeENV'
import {saveObservedId} from '@canvas/observer-picker/ObserverGetObservee'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)
const deepEqual = (x, y) => expect(x).toEqual(y)
const strictEqual = (x, y) => expect(x).toEqual(y)

const COURSE_SUBMISSIONS_URL = '/courses/1/submissions'

let assignments
let group
let collection

const server = setupServer()

describe('AssignmentGroupCollection', () => {
  beforeAll(() => {
    server.listen({
      onUnhandledRequest: 'error',
    })
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    fakeENV.setup()
    assignments = [1, 2, 3, 4].map(id => new Assignment({id}))
    group = new AssignmentGroup({assignments})
    collection = new AssignmentGroupCollection([group], {
      courseSubmissionsURL: COURSE_SUBMISSIONS_URL,
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    server.resetHandlers()
  })

  test('::model is AssignmentGroup', () =>
    strictEqual(AssignmentGroupCollection.prototype.model, AssignmentGroup))

  test('default params include assignments and not discussion topics', () => {
    const {include} = AssignmentGroupCollection.prototype.defaults.params
    deepEqual(include, ['assignments'], 'include only contains assignments')
  })

  test('default params include peer_review when feature flag is enabled', () => {
    ENV.FEATURES = {peer_review_allocation_and_grading: true}
    const {include} = AssignmentGroupCollection.prototype.defaults.params
    deepEqual(
      include,
      ['assignments', 'peer_review'],
      'include contains assignments and peer_review when feature flag is enabled',
    )
  })

  test('optionProperties', () => {
    const course = new Course()
    const collection_ = new AssignmentGroupCollection([], {
      course,
      courseSubmissionsURL: COURSE_SUBMISSIONS_URL,
    })
    strictEqual(
      collection_.courseSubmissionsURL,
      COURSE_SUBMISSIONS_URL,
      'assigns courseSubmissionsURL to courseSubmissionsURL',
    )
    strictEqual(collection_.course, course, 'assigns course to course')
  })

  test('(#getGrades) loading grades from the server', async function () {
    ENV.observed_student_ids = []
    ENV.PERMISSIONS.read_grades = true
    let triggeredChangeForAssignmentWithoutSubmission = false
    const submissions = [1, 2, 3].map(id => ({
      id,
      assignment_id: id,
      grade: id,
    }))

    server.use(
      http.get(`${COURSE_SUBMISSIONS_URL}`, ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('per_page') === '50') {
          return HttpResponse.json(submissions)
        }
      }),
    )

    const lastAssignment = assignments[3]
    lastAssignment.on(
      'change:submission',
      () => (triggeredChangeForAssignmentWithoutSubmission = true),
    )

    await collection.getGrades()

    for (const assignment of assignments) {
      if (assignment.get('id') === 4) continue
      equal(
        assignment.get('submission').get('grade'),
        assignment.get('id'),
        'sets submission grade for assignments with a matching submission',
      )
    }
    ok(
      triggeredChangeForAssignmentWithoutSubmission,
      'triggers change for assignments without a matching submission grade so the UI can update',
    )
  })

  test('(#getObservedUserId) when observing a student', function () {
    const expected_user_id = '2012'
    const current_user_id = '1999'
    ENV.current_user = {id: current_user_id}
    ENV.observed_student_ids = [123, 456, 789] // should be ignored

    saveObservedId(current_user_id, expected_user_id) // should be used

    const actual_user_id = collection.getObservedUserId()

    equal(expected_user_id, actual_user_id, 'returns the selected observed user id')
  })

  test('(#getObservedUserId) when not observing a student', function () {
    ENV.observed_student_ids = []

    const actual_user_id = collection.getObservedUserId()

    equal(!!actual_user_id, false, 'returns falsey')
  })

  describe('expandPeerReviewSubAssignments', () => {
    beforeEach(() => {
      ENV.FLAGS = {}
      ENV.current_user_roles = []
      ENV.PERMISSIONS = {}
    })

    test('does nothing when feature flag is disabled', () => {
      ENV.FLAGS.peer_review_allocation_and_grading = false
      ENV.current_user_roles = ['student']

      const assignment = new Assignment({
        id: 1,
        peer_review_sub_assignment: {
          id: 101,
          due_at: '2024-01-15',
        },
      })
      const group = new AssignmentGroup({assignments: [assignment]})
      const collection = new AssignmentGroupCollection([group])

      const initialCount = group.get('assignments').length
      collection.expandPeerReviewSubAssignments()

      equal(group.get('assignments').length, initialCount, 'should not add peer review assignments')
    })

    test('does nothing when user is not a student', () => {
      ENV.FLAGS.peer_review_allocation_and_grading = true
      ENV.current_user_roles = ['teacher']
      ENV.PERMISSIONS.manage = true

      const assignment = new Assignment({
        id: 1,
        peer_review_sub_assignment: {
          id: 101,
          due_at: '2024-01-15',
        },
      })
      const group = new AssignmentGroup({assignments: [assignment]})
      const collection = new AssignmentGroupCollection([group])

      const initialCount = group.get('assignments').length
      collection.expandPeerReviewSubAssignments()

      equal(group.get('assignments').length, initialCount, 'should not add peer review assignments')
    })

    test('expands peer review sub-assignments for students when feature flag is enabled', () => {
      ENV.FLAGS.peer_review_allocation_and_grading = true
      ENV.current_user_roles = ['student']
      ENV.PERMISSIONS.manage = false

      const assignment = new Assignment({
        id: 1,
        name: 'Test Assignment',
        peer_review_count: 2,
        assignment_group_id: 10,
        course_id: 100,
        published: true,
        html_url: '/courses/100/assignments/1',
        peer_review_sub_assignment: {
          id: 101,
          due_at: '2024-01-15',
          lock_at: '2024-01-20',
          unlock_at: '2024-01-10',
        },
      })
      const group = new AssignmentGroup({id: 10, assignments: [assignment]})
      const collection = new AssignmentGroupCollection([group])

      collection.expandPeerReviewSubAssignments()

      equal(group.get('assignments').length, 2, 'should add peer review assignment')

      const peerReviewAssignment = group.get('assignments').at(1)
      equal(peerReviewAssignment.get('id'), 101, 'should have correct id')
      equal(
        peerReviewAssignment.get('due_at'),
        '2024-01-15',
        'should have due_at from sub-assignment',
      )
      equal(
        peerReviewAssignment.get('lock_at'),
        '2024-01-20',
        'should have lock_at from sub-assignment',
      )
      equal(
        peerReviewAssignment.get('unlock_at'),
        '2024-01-10',
        'should have unlock_at from sub-assignment',
      )
      equal(peerReviewAssignment.get('parent_assignment_id'), 1, 'should have parent_assignment_id')
      equal(
        peerReviewAssignment.get('parent_assignment_name'),
        'Test Assignment',
        'should have parent_assignment_name',
      )
      equal(
        peerReviewAssignment.get('parent_peer_review_count'),
        2,
        'should have parent_peer_review_count',
      )
      equal(
        peerReviewAssignment.get('is_peer_review_assignment'),
        true,
        'should be marked as peer review assignment',
      )
      equal(
        peerReviewAssignment.get('assignment_group_id'),
        10,
        'should inherit assignment_group_id',
      )
      equal(peerReviewAssignment.get('course_id'), 100, 'should inherit course_id')
      equal(peerReviewAssignment.get('published'), true, 'should inherit published')
      equal(
        peerReviewAssignment.get('html_url'),
        '/courses/100/assignments/1/peer_reviews',
        'should have peer reviews URL',
      )
    })

    test('does not add assignments when there are no peer_review_sub_assignments', () => {
      ENV.FLAGS.peer_review_allocation_and_grading = true
      ENV.current_user_roles = ['student']
      ENV.PERMISSIONS.manage = false

      const assignment = new Assignment({
        id: 1,
        name: 'Test Assignment',
      })
      const group = new AssignmentGroup({assignments: [assignment]})
      const collection = new AssignmentGroupCollection([group])

      const initialCount = group.get('assignments').length
      collection.expandPeerReviewSubAssignments()

      equal(group.get('assignments').length, initialCount, 'should not add any assignments')
    })

    test('expands multiple peer review sub-assignments across multiple groups', () => {
      ENV.FLAGS.peer_review_allocation_and_grading = true
      ENV.current_user_roles = ['student']
      ENV.PERMISSIONS.manage = false

      const assignment1 = new Assignment({
        id: 1,
        name: 'Assignment 1',
        html_url: '/courses/100/assignments/1',
        peer_review_sub_assignment: {id: 101, due_at: '2024-01-15'},
      })
      const assignment2 = new Assignment({
        id: 2,
        name: 'Assignment 2',
        html_url: '/courses/100/assignments/2',
        peer_review_sub_assignment: {id: 102, due_at: '2024-01-16'},
      })
      const group1 = new AssignmentGroup({id: 10, assignments: [assignment1]})
      const group2 = new AssignmentGroup({id: 20, assignments: [assignment2]})
      const collection = new AssignmentGroupCollection([group1, group2])

      collection.expandPeerReviewSubAssignments()

      equal(group1.get('assignments').length, 2, 'should add peer review assignment to group 1')
      equal(group2.get('assignments').length, 2, 'should add peer review assignment to group 2')
    })
  })
})

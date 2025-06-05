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
import $ from 'jquery'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)
const deepEqual = (x, y) => expect(x).toEqual(y)
const strictEqual = (x, y) => expect(x).toEqual(y)

const COURSE_SUBMISSIONS_URL = '/courses/1/submissions'

let assignments
let group
let collection

describe('AssignmentGroupCollection', () => {
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
    jest.restoreAllMocks()
  })

  test('::model is AssignmentGroup', () =>
    strictEqual(AssignmentGroupCollection.prototype.model, AssignmentGroup))

  test('default params include assignments and not discussion topics', () => {
    const {include} = AssignmentGroupCollection.prototype.defaults.params
    deepEqual(include, ['assignments'], 'include only contains assignments')
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

  test('(#getGrades) loading grades from the server', function () {
    ENV.observed_student_ids = []
    ENV.PERMISSIONS.read_grades = true
    let triggeredChangeForAssignmentWithoutSubmission = false
    const submissions = [1, 2, 3].map(id => ({
      id,
      assignment_id: id,
      grade: id,
    }))

    const ajaxSpy = jest.spyOn($, 'ajax').mockImplementation(options => {
      if (options.url === `${COURSE_SUBMISSIONS_URL}?per_page=50`) {
        // Simulate successful response
        const deferred = $.Deferred()
        setTimeout(() => {
          options.success(submissions)
          deferred.resolve(submissions)
        }, 0)
        return deferred.promise()
      }
    })

    const lastAssignment = assignments[3]
    lastAssignment.on(
      'change:submission',
      () => (triggeredChangeForAssignmentWithoutSubmission = true),
    )

    collection.getGrades()

    // Wait for the mock to resolve
    return new Promise(resolve => {
      setTimeout(() => {
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
        resolve()
      }, 10)
    })
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
})

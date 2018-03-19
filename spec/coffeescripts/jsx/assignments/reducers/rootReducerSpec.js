/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import rootReducer from 'jsx/assignments/reducers/rootReducer'
import Constants from 'jsx/assignments/constants'
import ModerationActions from 'jsx/assignments/actions/ModerationActions'

const fakeStudents = [
  {
    id: 2,
    display_name: 'Test Student',
    avatar_image_url: 'https://canvas.instructure.com/images/messages/avatar-50.png',
    html_url: 'http://localhost:3000/courses/1/users/2',
    in_moderation_set: false,
    selected_provisional_grade_id: null,
    provisional_grades: []
  },
  {
    id: 3,
    display_name: 'a@example.edu',
    avatar_image_url: 'https://canvas.instructure.com/images/messages/avatar-50.png',
    html_url: 'http://localhost:3000/courses/1/users/3',
    in_moderation_set: false,
    selected_provisional_grade_id: null,
    provisional_grades: [
      {
        grade: '4',
        score: 4,
        graded_at: '2015-09-11T15:42:28Z',
        scorer_id: 1,
        final: false,
        provisional_grade_id: 10,
        grade_matches_current_submission: true,
        speedgrader_url:
          encodeURI('http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#{"student_id":"3","provisional_grade_id":10}')
      },
      {
        grade: '10',
        score: '10',
        graded_at: '2015-09-11T15:42:28Z',
        scorer_id: 1,
        final: false,
        provisional_grade_id: 10,
        grade_matches_current_submission: true,
        speedgrader_url:
          encodeURI('http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#{"student_id":"3","provisional_grade_id":10}')
      },
      {
        grade: '1',
        score: '1',
        graded_at: '2015-09-11T15:42:28Z',
        scorer_id: 1,
        final: false,
        provisional_grade_id: 10,
        grade_matches_current_submission: true,
        speedgrader_url:
          encodeURI('http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#{"student_id":"3","provisional_grade_id":10}')
      }
    ]
  },
  {
    id: 4,
    display_name: 'b@example.edu',
    avatar_image_url: 'https://canvas.instructure.com/images/messages/avatar-50.png',
    html_url: 'http://localhost:3000/courses/1/users/4',
    in_moderation_set: true,
    selected_provisional_grade_id: 13,
    provisional_grades: [
      {
        grade: '6',
        score: 6,
        graded_at: '2015-09-11T16:44:09Z',
        scorer_id: 1,
        final: false,
        provisional_grade_id: 11,
        grade_matches_current_submission: true,
        speedgrader_url:
          encodeURI('http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#{"student_id":"4","provisional_grade_id":11}')
      },
      {
        grade: '6',
        score: 6,
        graded_at: '2015-09-21T17:23:43Z',
        scorer_id: 1,
        final: true,
        provisional_grade_id: 13,
        grade_matches_current_submission: true,
        speedgrader_url:
          encodeURI('http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#{"student_id":"4","provisional_grade_id":13}')
      },
      {
        grade: '6',
        score: 6,
        graded_at: '2015-09-21T17:23:43Z',
        scorer_id: 1,
        final: true,
        provisional_grade_id: 13,
        grade_matches_current_submission: true,
        speedgrader_url:
          encodeURI('http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#{"student_id":"4","provisional_grade_id":13}')
      }
    ]
  }
]

QUnit.module('students reducer')

test('concatenates students on GOT_STUDENTS', () => {
  const initialState = {
    studentList: {
      students: [{id: 1, one: 1}, {id: 2, two: 2}]
    }
  }
  const gotStudentsAction = {
    type: 'GOT_STUDENTS',
    payload: {
      students: [{id: 3, three: 3}, {id: 4, four: 4}]
    }
  }
  const newState = rootReducer(initialState, gotStudentsAction)
  const expected = [{id: 1, one: 1}, {id: 2, two: 2}, {id: 3, three: 3}, {id: 4, four: 4}]
  deepEqual(newState.studentList.students, expected, 'successfully concatenates')
})

test('filters out duplicate students on GOT_STUDENTS', () => {
  const initialState = {
    studentList: {
      students: [{id: 1, one: 1}, {id: 2, two: 2}]
    }
  }
  const gotStudentsAction = {
    type: 'GOT_STUDENTS',
    payload: {
      students: [{id: 3, three: 3}, {id: 3, three: 3}]
    }
  }
  const newState = rootReducer(initialState, gotStudentsAction)
  const expected = [{id: 1, one: 1}, {id: 2, two: 2}, {id: 3, three: 3}]
  deepEqual(newState.studentList.students, expected, 'successfully concatenates')
})

test('updates the moderation set handling UPDATED_MODERATION_SET', () => {
  const initialState = {
    studentList: {
      students: [{id: 1}, {id: 2}]
    }
  }
  const updatedModerationSetAction = {
    type: 'UPDATED_MODERATION_SET',
    payload: {
      students: [{id: 1}, {id: 2}]
    }
  }
  const newState = rootReducer(initialState, updatedModerationSetAction)
  const expected = [
    {id: 1, in_moderation_set: true, on_moderation_stage: false},
    {id: 2, in_moderation_set: true, on_moderation_stage: false}
  ]

  deepEqual(newState.studentList.students, expected, 'successfully updates moderation set')
})

test('sets all the students on_moderation_stage property to true on SELECT_ALL_STUDENTS', () => {
  const initialState = {
    studentList: {
      students: [{id: 1}, {id: 2}]
    }
  }
  const selectAllStudentsAction = {
    type: 'SELECT_ALL_STUDENTS',
    payload: {
      students: [{id: 1}, {id: 2}]
    }
  }
  const newState = rootReducer(initialState, selectAllStudentsAction)
  const expected = [{id: 1, on_moderation_stage: true}, {id: 2, on_moderation_stage: true}]

  deepEqual(
    newState.studentList.students,
    expected,
    'successfully updates all students on_moderation_stage property'
  )
})

test('sets all the students on_moderation_stage property to false on UNSELECT_ALL_STUDENTS', () => {
  const initialState = {
    studentList: {
      students: [{id: 1, on_moderation_stage: true}, {id: 2, on_moderation_stage: true}]
    }
  }
  const unselectAllStudentsAction = {type: 'UNSELECT_ALL_STUDENTS'}
  const newState = rootReducer(initialState, unselectAllStudentsAction)
  const expected = [{id: 1, on_moderation_stage: false}, {id: 2, on_moderation_stage: false}]

  deepEqual(
    newState.studentList.students,
    expected,
    'successfully updates all students on_moderation_stage property'
  )
})

test('sets on_moderation_stage property to true on SELECT_STUDENT', () => {
  const initialState = {
    studentList: {
      students: [{id: 1}, {id: 2}]
    }
  }
  const selectStudentAction = {
    type: 'SELECT_STUDENT',
    payload: {
      studentId: 2
    }
  }
  const newState = rootReducer(initialState, selectStudentAction)
  const expected = [{id: 1}, {id: 2, on_moderation_stage: true}]

  deepEqual(
    newState.studentList.students,
    expected,
    'successfully updates student on_moderation_stage property'
  )
})

test('sets on_moderation_stage property to false on UNSELECT_STUDENT', () => {
  const initialState = {
    studentList: {
      students: [{id: 1, on_moderation_stage: true}, {id: 2}]
    }
  }
  const unselectStudentAction = {
    type: 'UNSELECT_STUDENT',
    payload: {studentId: 1}
  }
  const newState = rootReducer(initialState, unselectStudentAction)
  const expected = [{id: 1, on_moderation_stage: false}, {id: 2}]

  deepEqual(
    newState.studentList.students,
    expected,
    'successfully updates student on_moderation_stage property'
  )
})

test('set the on_moderation_stage to false from all students on UPDATED_MODERATION_SET', () => {
  const initialState = {
    studentList: {
      students: [{id: 1, on_moderation_stage: true}, {id: 2, on_moderation_stage: true}]
    }
  }
  const updatedModerationSetAction = {
    type: 'UPDATED_MODERATION_SET',
    payload: {
      students: [{id: 1}, {id: 2}, {id: 3}]
    }
  }
  const newState = rootReducer(initialState, updatedModerationSetAction)
  const studentsInSet = newState.studentList.students.find(student => student.on_moderation_stage)
  ok(!studentsInSet, 'updates state')
})

test('sets the selected_provisional_grade_id for a student on SELECT_MARK', () => {
  const initialState = {
    studentList: {
      students: [
        {
          id: 1,
          selected_provisional_grade_id: null,
          provisional_grades: [{provisional_grade_id: 10}]
        }
      ]
    }
  }
  const selectMarkAction = {
    type: 'SELECT_MARK',
    payload: {
      studentId: 1,
      selectedProvisionalId: 10
    }
  }

  const newState = rootReducer(initialState, selectMarkAction)
  const expected = [
    {
      id: 1,
      selected_provisional_grade_id: 10,
      provisional_grades: [{provisional_grade_id: 10}]
    }
  ]

  deepEqual(
    newState.studentList.students,
    expected,
    'student received updated selected_provisional_grade_id property'
  )
})

QUnit.module('urls reducer')

test('passes through whatever the current state is', () => {
  const initialState = {urls: {test_url: 'test'}}
  const someRandomAction = {type: 'Random'}
  const newState = rootReducer(initialState, someRandomAction)
  deepEqual(newState.urls, initialState.urls, 'passes through unchanged')
})

QUnit.module('assignments reducer')

test('sets to published on PUBLISHED_GRADES', () => {
  const initialState = {assignments: {published: false}}
  const publishedGradesAction = {
    type: 'PUBLISHED_GRADES',
    payload: {
      time: Date.now(),
      message: 'test'
    }
  }
  const newState = rootReducer(initialState, publishedGradesAction)
  ok(newState.assignment.published, 'successfully sets to publish')
})

QUnit.module('flashMessage reducer')

test('sets success message on PUBLISHED_GRADES', () => {
  const initialState = {flashMessage: {}}
  const publishedGradesAction = {
    type: 'PUBLISHED_GRADES',
    payload: {
      time: 123,
      message: 'test success'
    }
  }
  const newState = rootReducer(initialState, publishedGradesAction)
  const expected = {
    time: 123,
    message: 'test success',
    error: false
  }
  deepEqual(newState.flashMessage, expected, 'updates state')
})

test('sets failure message on PUBLISHED_GRADES_FAILED', () => {
  const initialState = {flashMessage: {}}
  const publishedGradesAction = {
    type: 'PUBLISHED_GRADES_FAILED',
    payload: {
      time: 123,
      message: 'failed to publish',
      error: true
    }
  }
  const newState = rootReducer(initialState, publishedGradesAction)
  const expected = {
    time: 123,
    message: 'failed to publish',
    error: true
  }
  deepEqual(newState.flashMessage, expected, 'updates state')
})

test('sets success message on UPDATED_MODERATION_SET', () => {
  const initialState = {
    flashMessage: {},
    studentList: {students: []}
  }
  const updatedModerationSetAction = {
    type: 'UPDATED_MODERATION_SET',
    payload: {
      time: 10,
      message: 'test success',
      students: [{id: 1}, {id: 2}]
    }
  }
  const newState = rootReducer(initialState, updatedModerationSetAction)
  const expected = {
    time: 10,
    message: 'test success',
    error: false
  }
  deepEqual(newState.flashMessage, expected, 'updates state')
})

test('sets failure message on UPDATE_MODERATION_SET_FAILED', () => {
  const initialState = {flashMessage: {}}
  const updatedModerationSetAction = {
    type: 'UPDATE_MODERATION_SET_FAILED',
    payload: {
      time: 10,
      message: 'test failure',
      students: [{id: 1}, {id: 2}]
    }
  }
  const newState = rootReducer(initialState, updatedModerationSetAction)
  const expected = {
    time: 10,
    message: 'test failure',
    error: true
  }
  deepEqual(newState.flashMessage, expected, 'updates state')
})

test('sets message and error on SELECTING_PROVISIONAL_GRADES_FAILED', () => {
  const message = 'some error message'
  const error = new Error(message)
  error.time = Date.now()

  const initialState = {flashMessage: {}}
  const updatedModerationSetAction = {
    type: 'SELECTING_PROVISIONAL_GRADES_FAILED',
    payload: error,
    error: true
  }
  const newState = rootReducer(initialState, updatedModerationSetAction)
  const expected = {
    time: error.time,
    message,
    error: true
  }
  deepEqual(newState.flashMessage, expected, 'updates state')
})

QUnit.module('inflightAction reducer', {
  setup() {
    this.initialState = {
      inflightAction: {
        review: false,
        publish: false
      }
    }

    this.inflightInitialState = {
      students: {},
      inflightAction: {
        review: true,
        publish: true
      }
    }
  }
})

test('marks the review action as in-flight on ACTION_DISPATCHED with a payload of review', function() {
  const reviewActionDispatchedAction = {
    type: 'ACTION_DISPATCHED',
    payload: {name: 'review'}
  }

  const stateWithReviewDispatched = rootReducer(this.initialState, reviewActionDispatchedAction)
  equal(stateWithReviewDispatched.inflightAction.review, true)
  equal(stateWithReviewDispatched.inflightAction.publish, false)
})

test('marks the publish action as in-flight on ACTION_DISPATCHED with a payload of publish', function() {
  const publishActionDispatchedAction = {
    type: 'ACTION_DISPATCHED',
    payload: {name: 'publish'}
  }

  const stateWithPublishDispatched = rootReducer(this.initialState, publishActionDispatchedAction)
  equal(stateWithPublishDispatched.inflightAction.publish, true)
  equal(stateWithPublishDispatched.inflightAction.review, false)
})

test('lands the review action on UPDATED_MODERATION_SET', function() {
  const updatedModerationSetAction = {
    type: 'UPDATED_MODERATION_SET',
    payload: {students: []}
  }
  const stateWithReviewLanded = rootReducer(this.inflightInitialState, updatedModerationSetAction)
  equal(stateWithReviewLanded.inflightAction.review, false)
})

test('lands the review action on UPDATE_MODERATION_SET_FAILED', function() {
  const updateModerationSetFailedAction = {
    type: 'UPDATE_MODERATION_SET_FAILED',
    payload: {time: Date.now()}
  }

  const stateWithReviewLanded = rootReducer(
    this.inflightInitialState,
    updateModerationSetFailedAction
  )
  equal(stateWithReviewLanded.inflightAction.review, false)
})

test('lands the publish action on PUBLISHED_GRADES', function() {
  const publishedGradesAction = {
    type: 'PUBLISHED_GRADES',
    payload: {time: Date.now()}
  }

  const stateWithPublishLanded = rootReducer(this.inflightInitialState, publishedGradesAction)
  equal(stateWithPublishLanded.inflightAction.publish, false)
})

test('lands the publish action on PUBLISHED_GRADES_FAILED', function() {
  const publishedGradesFailedAction = {
    type: 'PUBLISHED_GRADES_FAILED',
    payload: {time: Date.now()}
  }

  const stateWithPublishLanded = rootReducer(this.inflightInitialState, publishedGradesFailedAction)
  equal(stateWithPublishLanded.inflightAction.publish, false)
})

QUnit.module('sorting mark1 column on SORT_MARK1_COLUMN')

test('default to descending order when clicking on a new column', () => {
  const initialState = {
    studentList: {
      students: fakeStudents,
      sort: {
        column: undefined,
        direction: undefined
      }
    }
  }

  const updatedModerationSetAction = {type: ModerationActions.SORT_MARK1_COLUMN}
  const newState = rootReducer(initialState, updatedModerationSetAction)

  deepEqual(newState.studentList.students[0].id, 4, 'sorts the right student to the top')
})

test('sorts students to descending order when previously ascending', () => {
  const initialState = {
    studentList: {
      students: fakeStudents,
      sort: {
        column: Constants.markColumnNames.MARK_ONE,
        direction: Constants.sortDirections.ASCENDING
      }
    }
  }

  const updatedModerationSetAction = {type: ModerationActions.SORT_MARK1_COLUMN}
  const newState = rootReducer(initialState, updatedModerationSetAction)

  deepEqual(newState.studentList.students[0].id, 4, 'sorts the right student to the top')
})

test('sorts students to ascending order when previously descending', () => {
  const initialState = {
    studentList: {
      students: fakeStudents,
      sort: {
        column: Constants.markColumnNames.MARK_ONE,
        direction: Constants.sortDirections.DESCENDING
      }
    }
  }

  const updatedModerationSetAction = {type: ModerationActions.SORT_MARK1_COLUMN}
  const newState = rootReducer(initialState, updatedModerationSetAction)

  equal(
    newState.studentList.sort.direction,
    Constants.sortDirections.ASCENDING,
    'sets the right direction'
  )
  deepEqual(newState.studentList.students[0].id, 2, 'sorts the right student to the top')
})

QUnit.module('sorting mark2 column on SORT_MARK2_COLUMN')

test('default to descending order when clicking on a new column', () => {
  const initialState = {
    studentList: {
      students: fakeStudents,
      sort: {
        column: undefined,
        direction: undefined
      }
    }
  }

  const updatedModerationSetAction = {type: ModerationActions.SORT_MARK2_COLUMN}
  const newState = rootReducer(initialState, updatedModerationSetAction)

  deepEqual(newState.studentList.students[0].id, 3, 'sorts the right student to the top')
})

test('sorts students to descending order when previously ascending', () => {
  const initialState = {
    studentList: {
      students: fakeStudents,
      sort: {
        column: Constants.markColumnNames.MARK_TWO,
        direction: Constants.sortDirections.ASCENDING
      }
    }
  }

  const updatedModerationSetAction = {type: ModerationActions.SORT_MARK2_COLUMN}
  const newState = rootReducer(initialState, updatedModerationSetAction)

  deepEqual(newState.studentList.students[0].id, 3, 'sorts the right student to the top')
})

test('sorts students to ascending order when previously descending', () => {
  const initialState = {
    studentList: {
      students: fakeStudents,
      sort: {
        column: Constants.markColumnNames.MARK_TWO,
        direction: Constants.sortDirections.DESCENDING
      }
    }
  }

  const updatedModerationSetAction = {type: ModerationActions.SORT_MARK2_COLUMN}
  const newState = rootReducer(initialState, updatedModerationSetAction)

  equal(
    newState.studentList.sort.direction,
    Constants.sortDirections.ASCENDING,
    'sets the right direction'
  )
  deepEqual(newState.studentList.students[0].id, 2, 'sorts the right student to the top')
})

QUnit.module('sorting mark3 column on SORT_MARK3_COLUMN')

test('default to descending order when clicking on a new column', () => {
  const initialState = {
    studentList: {
      students: fakeStudents,
      sort: {
        column: undefined,
        direction: undefined
      }
    }
  }

  const updatedModerationSetAction = {type: ModerationActions.SORT_MARK3_COLUMN}
  const newState = rootReducer(initialState, updatedModerationSetAction)

  deepEqual(newState.studentList.students[0].id, 4, 'sorts the right student to the top')
})

test('sorts students to descending order when previously ascending', () => {
  const initialState = {
    studentList: {
      students: fakeStudents,
      sort: {
        column: Constants.markColumnNames.MARK_THREE,
        direction: Constants.sortDirections.ASCENDING
      }
    }
  }

  const updatedModerationSetAction = {type: ModerationActions.SORT_MARK3_COLUMN}
  const newState = rootReducer(initialState, updatedModerationSetAction)

  deepEqual(newState.studentList.students[0].id, 4, 'sorts the right student to the top')
})

test('sorts students to ascending order when previously descending', () => {
  const initialState = {
    studentList: {
      students: fakeStudents,
      sort: {
        column: Constants.markColumnNames.MARK_THREE,
        direction: Constants.sortDirections.DESCENDING
      }
    }
  }

  const updatedModerationSetAction = {type: ModerationActions.SORT_MARK3_COLUMN}
  const newState = rootReducer(initialState, updatedModerationSetAction)

  equal(
    newState.studentList.sort.direction,
    Constants.sortDirections.ASCENDING,
    'sets the right direction'
  )
  deepEqual(newState.studentList.students[0].id, 2, 'sorts the right student to the top')
})

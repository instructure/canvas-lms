/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {fromJS} from 'immutable'
import moment from 'moment'
import SubmissionStateMap from '@canvas/grading/SubmissionStateMap'
import {createGradebook} from './GradebookSpecHelper'
import fakeENV from '@canvas/test-utils/fakeENV'

const studentWithoutSubmission = {
  id: '1',
  group_ids: ['1'],
  sections: ['1'],
}

const studentWithSubmission = {
  id: '1',
  group_ids: ['1'],
  sections: ['1'],
  assignment_1: {},
}

const yesterday = moment(new Date()).subtract(1, 'day')
const tomorrow = moment(new Date()).add(1, 'day')

const baseAssignment = fromJS({
  id: '1',
  published: true,
  effectiveDueDates: {
    1: {due_at: new Date(), grading_period_id: '2', in_closed_grading_period: true},
  },
})
const unpublishedAssignment = baseAssignment.merge({published: false})
const anonymousMutedAssignment = baseAssignment.merge({
  anonymize_students: true,
  anonymous_grading: true,
  muted: true,
})
const moderatedAndGradesUnpublishedAssignment = baseAssignment.merge({
  moderated_grading: true,
  grades_published: false,
})
const hiddenFromStudent = baseAssignment.merge({
  only_visible_to_overrides: true,
  assignment_visibility: [],
})
const hasGradingPeriodsAssignment = baseAssignment

function createMap(opts = {}) {
  const defaults = {
    hasGradingPeriods: false,
    selectedGradingPeriodID: '0',
    isAdmin: false,
  }

  const params = {...defaults, ...opts}
  return new SubmissionStateMap(params)
}

function createAndSetupMap(assignment, student, opts = {}) {
  const map = createMap(opts)
  const assignments = {}
  assignments[assignment.id] = assignment
  map.setup([student], assignments)
  return map
}

describe('#setSubmissionCellState', () => {
  test('the submission state is locked if assignment is not published', () => {
    const assignment = {
      id: '1',
      published: false,
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.locked).toBe(true)
  })

  test('the submission state has hideGrade set if assignment is not published', () => {
    const assignment = {
      id: '1',
      published: false,
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.hideGrade).toBe(true)
  })

  test('the submission state is locked if assignment is not visible', () => {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: true,
      assignment_visibility: [],
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.locked).toBe(true)
  })

  test('the submission state has hideGrade set if assignment is not visible', () => {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: true,
      assignment_visibility: [],
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.hideGrade).toBe(true)
  })

  test('the submission state is not locked if assignment is published and visible', () => {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: false,
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.locked).toBe(false)
  })

  test('the submission state has hideGrade not set if assignment is published and visible', () => {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: false,
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.hideGrade).toBe(false)
  })

  test('the submission state is locked when the student is not assigned', () => {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: true,
      assignment_visibility: ['2'],
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.locked).toBe(true)
  })

  test('the submission state is not locked if not moderated grading', () => {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: false,
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.locked).toBe(false)
  })

  test('the submission state has hideGrade not set if not moderated grading', () => {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: false,
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.hideGrade).toBe(false)
  })

  test('the submission state is not locked if moderated grading and grades published', () => {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: true,
      grades_published: true,
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.locked).toBe(false)
  })

  test('the submission state has hideGrade not set if moderated grading and grades published', () => {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: true,
      grades_published: true,
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.hideGrade).toBe(false)
  })

  test('the submission state is locked if moderated grading and grades not published', () => {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: true,
      grades_published: false,
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.locked).toBe(true)
  })

  test('the submission state has hideGrade not set if moderated grading and grades not published', () => {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: true,
      grades_published: false,
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithSubmission.id,
      assignment_id: assignment.id,
    })
    expect(submission.hideGrade).toBe(false)
  })

  describe('when the assignment is anonymous', () => {
    let assignment

    beforeEach(() => {
      assignment = {id: '1', published: true, anonymous_grading: true}
    })

    test('the submission state is locked when anonymize_students is true', () => {
      assignment.anonymize_students = true
      const map = createAndSetupMap(assignment, studentWithSubmission)
      const submission = map.getSubmissionState({
        user_id: studentWithSubmission.id,
        assignment_id: assignment.id,
      })
      expect(submission.locked).toBe(true)
    })

    test('the submission state is hidden when anonymize_students is true', () => {
      assignment.anonymize_students = true
      const map = createAndSetupMap(assignment, studentWithSubmission)
      const submission = map.getSubmissionState({
        user_id: studentWithSubmission.id,
        assignment_id: assignment.id,
      })
      expect(submission.hideGrade).toBe(true)
    })

    test('the submission state is unlocked when the assignment is unmuted', () => {
      const map = createAndSetupMap(assignment, studentWithSubmission)
      const submission = map.getSubmissionState({
        user_id: studentWithSubmission.id,
        assignment_id: assignment.id,
      })
      expect(submission.locked).toBe(false)
    })

    test('the submission state is not hidden when the assignment is unmuted', () => {
      const map = createAndSetupMap(assignment, studentWithSubmission)
      const submission = map.getSubmissionState({
        user_id: studentWithSubmission.id,
        assignment_id: assignment.id,
      })
      expect(submission.hideGrade).toBe(false)
    })
  })

  describe('no submission', () => {
    test('the submission object is missing if the assignment is late', () => {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: {1: {due_at: yesterday}},
      }
      const map = createAndSetupMap(assignment, studentWithoutSubmission)
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id)
      expect(submission.missing).toBe(true)
    })

    test('the submission object is not missing if the assignment is not late', () => {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: {1: {due_at: tomorrow}},
      }
      const map = createAndSetupMap(assignment, studentWithoutSubmission)
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id)
      expect(submission.missing).toBe(false)
    })

    test('the submission object is not missing, if the assignment is not late and there are no due dates', () => {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: {},
      }
      const map = createAndSetupMap(assignment, studentWithoutSubmission)
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id)
      expect(submission.missing).toBe(false)
    })

    test('the submission object has seconds_late set to zero', () => {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: {1: {due_at: new Date()}},
      }
      const map = createAndSetupMap(assignment, studentWithoutSubmission)
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id)
      expect(submission.seconds_late).toBe(0)
    })

    test('the submission object has late set to false', () => {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: {1: {due_at: new Date()}},
      }
      const map = createAndSetupMap(assignment, studentWithoutSubmission)
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id)
      expect(submission.late).toBe(false)
    })

    test('the submission object has excused set to false', () => {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: {1: {due_at: new Date()}},
      }
      const map = createAndSetupMap(assignment, studentWithoutSubmission)
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id)
      expect(submission.excused).toBe(false)
    })
  })

  test('an unpublished assignment is locked and grades are hidden', () => {
    const map = createAndSetupMap(unpublishedAssignment.toJS(), studentWithoutSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithoutSubmission.id,
      assignment_id: moderatedAndGradesUnpublishedAssignment.get('id'),
    })
    expect(submission).toEqual({locked: true, hideGrade: true})
  })

  test('a moderated and unpublished grades assignment is locked and grades not hidden when published', () => {
    const map = createAndSetupMap(
      moderatedAndGradesUnpublishedAssignment.toJS(),
      studentWithoutSubmission
    )
    const submission = map.getSubmissionState({
      user_id: studentWithoutSubmission.id,
      assignment_id: moderatedAndGradesUnpublishedAssignment.get('id'),
    })
    expect(submission).toEqual({locked: true, hideGrade: false})
  })

  test('an assignment that is hidden from the student is locked and grades are hidden', () => {
    const map = createAndSetupMap(hiddenFromStudent.toJS(), studentWithoutSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithoutSubmission.id,
      assignment_id: hiddenFromStudent.get('id'),
    })
    expect(submission).toEqual({locked: true, hideGrade: true})
  })

  test('an assignment that does not fall into any other buckets is unlocked and does not hide grades', () => {
    const map = createAndSetupMap(baseAssignment.toJS(), studentWithoutSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithoutSubmission.id,
      assignment_id: baseAssignment.get('id'),
    })
    expect(submission).toEqual({locked: false, hideGrade: false})
  })

  describe('Order of submission state’s grade visibility and locking.', () => {
    describe('An assignment that', () => {
      test('is unpublished takes precedence over one that is moderated and has unpublished grades', () => {
        const assignment = moderatedAndGradesUnpublishedAssignment.merge(unpublishedAssignment)
        const map = createAndSetupMap(assignment.toJS(), studentWithSubmission)
        const submission = map.getSubmissionState({
          user_id: studentWithSubmission.id,
          assignment_id: assignment.get('id'),
        })
        expect(submission).toEqual({locked: true, hideGrade: true})
      })

      test('is anonymously graded and muted takes precedence over one that is moderated and has unpublished grades', () => {
        const assignment = moderatedAndGradesUnpublishedAssignment.merge(anonymousMutedAssignment)
        const map = createAndSetupMap(assignment.toJS(), studentWithSubmission)
        const submission = map.getSubmissionState({
          user_id: studentWithSubmission.id,
          assignment_id: assignment.get('id'),
        })
        expect(submission).toEqual({locked: true, hideGrade: true})
      })

      test('is moderated and has unpublished grades takes precedence over one that is hidden from the student', () => {
        const assignment = hiddenFromStudent.merge(moderatedAndGradesUnpublishedAssignment)
        const map = createAndSetupMap(assignment.toJS(), studentWithSubmission)
        const submission = map.getSubmissionState({
          user_id: studentWithSubmission.id,
          assignment_id: assignment.get('id'),
        })
        expect(submission).toEqual({locked: true, hideGrade: false})
      })

      test('is hidden from the student takes precedence over one that has grading periods', () => {
        const assignment = hasGradingPeriodsAssignment.merge(hiddenFromStudent)
        const map = createAndSetupMap(assignment.toJS(), studentWithSubmission, {
          hasGradingPeriods: true,
        })
        const submission = map.getSubmissionState({
          user_id: studentWithSubmission.id,
          assignment_id: assignment.get('id'),
        })
        expect(submission).toEqual({locked: true, hideGrade: true})
      })

      test('has grading periods takes precedence over all other assignments', () => {
        const assignment = hasGradingPeriodsAssignment.merge(baseAssignment)
        const map = createAndSetupMap(assignment.toJS(), studentWithSubmission, {
          hasGradingPeriods: true,
        })
        const actualSubmissionState = map.getSubmissionState({
          user_id: studentWithSubmission.id,
          assignment_id: assignment.get('id'),
        })
        const expectedSubmissionState = {
          locked: true,
          hideGrade: false,
          inClosedGradingPeriod: true,
          inNoGradingPeriod: false,
          inOtherGradingPeriod: false,
        }
        expect(actualSubmissionState).toEqual(expectedSubmissionState)
      })
    })
  })
})

describe('Gradebook#initSubmissionStateMap', () => {
  test('initializes a new submission state map', () => {
    const gradebook = createGradebook()
    const originalMap = gradebook.submissionStateMap
    gradebook.initSubmissionStateMap()
    expect(gradebook.submissionStateMap.constructor).toBe(SubmissionStateMap)
    expect(originalMap).not.toBe(gradebook.submissionStateMap)
  })

  test('sets the submission state map .hasGradingPeriods to true when a grading period set exists', () => {
    const gradebook = createGradebook({
      grading_period_set: {id: '1501', grading_periods: [{id: '701'}, {id: '702'}]},
    })
    expect(gradebook.submissionStateMap.hasGradingPeriods).toBe(true)
  })

  test('sets the submission state map .hasGradingPeriods to false when no grading period set exists', () => {
    const gradebook = createGradebook()
    expect(gradebook.submissionStateMap.hasGradingPeriods).toBe(false)
  })

  test('sets the submission state map .selectedGradingPeriodID to the "grading period to show"', () => {
    const gradebook = createGradebook()
    gradebook.gradingPeriodId = '1401'
    gradebook.initSubmissionStateMap()
    expect(gradebook.submissionStateMap.selectedGradingPeriodID).toBe('1401')
  })

  test('sets the submission state map .isAdmin when the current user roles includes "admin"', () => {
    fakeENV.setup({current_user_roles: ['admin']})
    const gradebook = createGradebook()
    expect(gradebook.submissionStateMap.isAdmin).toBe(true)
    fakeENV.teardown()
  })

  test('sets the submission state map .isAdmin when the current user roles do not include "admin"', () => {
    const gradebook = createGradebook()
    expect(gradebook.submissionStateMap.isAdmin).toBe(false)
  })

  test('initializes a submission state map', () => {
    const gradebook = createGradebook()
    expect(gradebook.submissionStateMap.constructor).toBe(SubmissionStateMap)
  })
})

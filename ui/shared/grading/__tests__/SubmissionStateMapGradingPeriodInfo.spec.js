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

import SubmissionStateMap from '../SubmissionStateMap'

const student = {
  id: '1',
  group_ids: ['1'],
  sections: ['1'],
}

function createMap(opts = {}) {
  const params = {
    hasGradingPeriods: false,
    selectedGradingPeriodID: '0',
    isAdmin: false,
    ...opts,
  }

  return new SubmissionStateMap(params)
}

function createAndSetupMap(assignment, opts = {}) {
  const submissionStateMap = createMap(opts)
  const assignments = {}
  assignments[assignment.id] = assignment
  submissionStateMap.setup([student], assignments)
  return submissionStateMap
}

describe('SubmissionStateMap without grading periods', () => {
  const dueDate = '2015-07-15'
  let assignment
  let submissionStateMap
  let options

  beforeEach(() => {
    options = {hasGradingPeriods: false}
    assignment = {id: '1', published: true, effectiveDueDates: {}}
  })

  describe('inNoGradingPeriod', () => {
    test('returns undefined if submission has no grading period', () => {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        in_closed_grading_period: false,
      }
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inNoGradingPeriod).toBeUndefined()
    })

    test('returns undefined if submission has a grading period', () => {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        grading_period_id: 1,
        in_closed_grading_period: false,
      }
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inNoGradingPeriod).toBeUndefined()
    })
  })

  describe('inOtherGradingPeriod', () => {
    beforeEach(() => {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        in_closed_grading_period: false,
      }
    })

    test('returns undefined if filtering by grading period and submission is not in any grading period', () => {
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inOtherGradingPeriod).toBeUndefined()
    })

    test('returns undefined if filtering by grading period and submission is in another grading period', () => {
      assignment.effectiveDueDates[student.id].grading_period_id = '1'
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inOtherGradingPeriod).toBeUndefined()
    })

    test('returns undefined if filtering by grading period and submission is in the same grading period', () => {
      assignment.effectiveDueDates[student.id].grading_period_id = '2'
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inOtherGradingPeriod).toBeUndefined()
    })
  })

  describe('inClosedGradingPeriod', () => {
    beforeEach(() => {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
      }
    })

    test('returns undefined if submission is in a closed grading period', () => {
      assignment.effectiveDueDates[student.id].in_closed_grading_period = true
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inClosedGradingPeriod).toBeUndefined()
    })

    test('returns undefined if submission is in a closed grading period (2)', () => {
      assignment.effectiveDueDates[student.id].in_closed_grading_period = false
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inClosedGradingPeriod).toBeUndefined()
    })
  })
})

describe('SubmissionStateMap with grading periods', () => {
  const dueDate = '2015-07-15'
  let assignment
  let submissionStateMap
  let options

  beforeEach(() => {
    options = {hasGradingPeriods: true, selectedGradingPeriodID: '0'}
    assignment = {id: '1', published: true, effectiveDueDates: {}}
  })

  describe('inNoGradingPeriod', () => {
    test('returns true if submission has no grading period', () => {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        in_closed_grading_period: false,
      }
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inNoGradingPeriod).toBe(true)
    })

    test('returns false if submission has a grading period', () => {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        grading_period_id: 1,
        in_closed_grading_period: false,
      }
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inNoGradingPeriod).toBe(false)
    })
  })

  describe('inOtherGradingPeriod', () => {
    beforeEach(() => {
      options = {hasGradingPeriods: true, selectedGradingPeriodID: '2'}
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        in_closed_grading_period: false,
      }
    })

    test('returns false if filtering by grading period and submission is not in any grading period', () => {
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inOtherGradingPeriod).toBe(false)
    })

    test('returns true if filtering by grading period and submission is in another grading period', () => {
      assignment.effectiveDueDates[student.id].grading_period_id = '1'
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inOtherGradingPeriod).toBe(true)
    })

    test('returns false if filtering by grading period and submission is in the same grading period', () => {
      assignment.effectiveDueDates[student.id].grading_period_id = '2'
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inOtherGradingPeriod).toBe(false)
    })
  })

  describe('inClosedGradingPeriod', () => {
    beforeEach(() => {
      options = {hasGradingPeriods: true, selectedGradingPeriodID: '2'}
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
      }
    })

    test('returns true if submission is in a closed grading period', () => {
      assignment.effectiveDueDates[student.id].in_closed_grading_period = true
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inClosedGradingPeriod).toBe(true)
    })

    test('returns false if submission is not in a closed grading period', () => {
      assignment.effectiveDueDates[student.id].in_closed_grading_period = false
      submissionStateMap = createAndSetupMap(assignment, options)

      const state = submissionStateMap.getSubmissionState({
        user_id: student.id,
        assignment_id: assignment.id,
      })

      expect(state.inClosedGradingPeriod).toBe(false)
    })
  })
})

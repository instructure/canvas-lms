/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
  const defaults = {
    hasGradingPeriods: false,
    selectedGradingPeriodID: '0',
    isAdmin: false,
  }

  return new SubmissionStateMap({...defaults, ...opts})
}

function createAndSetupMap(assignment, opts = {}) {
  const map = createMap(opts)
  const assignments = {
    [assignment.id]: assignment,
  }
  map.setup([student], assignments)
  return map
}

// Tests for SubmissionStateMap without grading periods
describe('SubmissionStateMap without grading periods', () => {
  test('submission in an unpublished assignment is hidden', () => {
    const assignment = {id: '1', published: false, effectiveDueDates: {}, visible_to_everyone: true}
    const map = createAndSetupMap(assignment, {hasGradingPeriods: false})
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(true)
  })

  test('submission in a published assignment is not hidden', () => {
    const assignment = {id: '1', published: true, effectiveDueDates: {}, visible_to_everyone: true}
    const map = createAndSetupMap(assignment, {hasGradingPeriods: false})
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(false)
  })

  test('submission has grade hidden for a student without assignment visibility', () => {
    const assignment = {
      id: '1',
      published: true,
      effectiveDueDates: {},
      visible_to_everyone: false,
    }
    const map = createAndSetupMap(assignment, {hasGradingPeriods: false})
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(true)
  })

  test('submission has grade visible for a student with assignment visibility', () => {
    const assignment = {id: '1', published: true, effectiveDueDates: {}, visible_to_everyone: true}
    assignment.effectiveDueDates[student.id] = {
      due_at: null,
      grading_period_id: null,
      in_closed_grading_period: false,
    }

    const map = createAndSetupMap(assignment, {hasGradingPeriods: false})
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(false)
  })
})

// Tests for SubmissionStateMap with grading periods and all grading periods selected
describe('SubmissionStateMap with grading periods and all grading periods selected', () => {
  const DATE_IN_CLOSED_PERIOD = '2015-07-15'
  const DATE_NOT_IN_CLOSED_PERIOD = '2015-08-15'
  const mapOptions = {hasGradingPeriods: true, selectedGradingPeriodID: '0'}

  test('submission has grade hidden for a student without assignment visibility', () => {
    const assignment = {
      id: '1',
      published: true,
      effectiveDueDates: {},
      visible_to_everyone: false,
    }
    const map = createAndSetupMap(assignment, mapOptions)
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(true)
  })

  test('submission has grade visible for an assigned student with assignment due in a closed grading period', () => {
    const assignment = {id: '1', published: true, effectiveDueDates: {}, visible_to_everyone: true}
    assignment.effectiveDueDates[student.id] = {
      due_at: DATE_IN_CLOSED_PERIOD,
      grading_period_id: '1',
      in_closed_grading_period: true,
    }

    const map = createAndSetupMap(assignment, mapOptions)
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(false)
  })

  test('submission has grade visible for an assigned student with assignment due outside of a closed grading period', () => {
    const assignment = {id: '1', published: true, effectiveDueDates: {}, visible_to_everyone: true}
    assignment.effectiveDueDates[student.id] = {
      due_at: DATE_NOT_IN_CLOSED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false,
    }

    const map = createAndSetupMap(assignment, mapOptions)
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(false)
  })
})

// Tests for SubmissionStateMap with grading periods and a non-closed grading period selected
describe('SubmissionStateMap with grading periods and a non-closed grading period selected', () => {
  const SELECTED_PERIOD_ID = '1'
  const DATE_IN_SELECTED_PERIOD = '2015-08-15'
  const DATE_NOT_IN_SELECTED_PERIOD = '2015-10-15'
  const mapOptions = {hasGradingPeriods: true, selectedGradingPeriodID: SELECTED_PERIOD_ID}

  test('submission has grade hidden for a student without assignment visibility', () => {
    const assignment = {id: '1', published: true, effectiveDueDates: {}, visible_to_everyone: true}
    const map = createAndSetupMap(assignment, mapOptions)
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(true)
  })

  test('submission has grade hidden for an assigned student with assignment due outside of the selected grading period', () => {
    const assignment = {id: '1', published: true, effectiveDueDates: {}, visible_to_everyone: true}
    assignment.effectiveDueDates[student.id] = {
      due_at: DATE_NOT_IN_SELECTED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false,
    }

    const map = createAndSetupMap(assignment, mapOptions)
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(true)
  })

  test('submission has grade visible for an assigned student with assignment due in the selected grading period', () => {
    const assignment = {id: '1', published: true, effectiveDueDates: {}, visible_to_everyone: true}
    assignment.effectiveDueDates[student.id] = {
      due_at: DATE_IN_SELECTED_PERIOD,
      grading_period_id: SELECTED_PERIOD_ID,
      in_closed_grading_period: false,
    }

    const map = createAndSetupMap(assignment, mapOptions)
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(false)
  })
})

// Tests for SubmissionStateMap with grading periods and a closed grading period selected
describe('SubmissionStateMap with grading periods and a closed grading period selected', () => {
  const SELECTED_PERIOD_ID = '1'
  const DATE_IN_SELECTED_PERIOD = '2015-07-15'
  const DATE_NOT_IN_SELECTED_PERIOD = '2015-08-15'
  const mapOptions = {hasGradingPeriods: true, selectedGradingPeriodID: SELECTED_PERIOD_ID}

  test('submission has grade hidden for a student without assignment visibility', () => {
    const assignment = {id: '1', published: true, effectiveDueDates: {}, visible_to_everyone: true}
    const map = createAndSetupMap(assignment, mapOptions)
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(true)
  })

  test('submission has grade hidden for an assigned student with assignment due outside of the selected grading period', () => {
    const assignment = {id: '1', published: true, effectiveDueDates: {}, visible_to_everyone: true}
    assignment.effectiveDueDates[student.id] = {
      due_at: DATE_NOT_IN_SELECTED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false,
    }

    const map = createAndSetupMap(assignment, mapOptions)
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(true)
  })

  test('submission has grade visible for an assigned student with assignment due in the selected grading period', () => {
    const assignment = {id: '1', published: true, effectiveDueDates: {}, visible_to_everyone: true}
    assignment.effectiveDueDates[student.id] = {
      due_at: DATE_IN_SELECTED_PERIOD,
      grading_period_id: SELECTED_PERIOD_ID,
      in_closed_grading_period: true,
    }

    const map = createAndSetupMap(assignment, mapOptions)
    const state = map.getSubmissionState({user_id: student.id, assignment_id: assignment.id})
    expect(state.hideGrade).toBe(false)
  })
})

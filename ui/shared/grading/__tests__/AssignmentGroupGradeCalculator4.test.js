/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import _ from 'lodash'
import AssignmentGroupGradeCalculator from '../AssignmentGroupGradeCalculator'

let submissions
let assignments
let assignmentGroup

describe('AssignmentGroupGradeCalculator.calculate with only ungraded submissions', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: null},
      {assignment_id: 202, score: null},
      {assignment_id: 203, score: null},
    ]
    assignments = [
      {id: 201, points_possible: 5, omit_from_final_grade: false, anonymize_students: false},
      {id: 202, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
      {id: 203, points_possible: 20, omit_from_final_grade: false, anonymize_students: false},
    ]
    assignmentGroup = {id: 301, rules: {}, assignments}
  })

  test('sets current score as 0', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(0)
    expect(grades.current.possible).toBe(0)
  })

  test('sets final score as 0', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.final.score).toBe(0)
    expect(grades.final.possible).toBe(35)
  })
})

describe('AssignmentGroupGradeCalculator.calculate "never_drop" rule', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 31},
      {assignment_id: 202, score: 19},
      {assignment_id: 203, score: 12},
      {assignment_id: 204, score: 6},
    ]
    assignments = [
      {id: 201, points_possible: 40, omit_from_final_grade: false, anonymize_students: false},
      {id: 202, points_possible: 24, omit_from_final_grade: false, anonymize_students: false},
      {id: 203, points_possible: 16, omit_from_final_grade: false, anonymize_students: false},
      {id: 204, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
    ]
    assignmentGroup = {id: 301, rules: {never_drop: [204]}, assignments}
  })

  test('prevents submissions from being dropped for low scores', () => {
    assignmentGroup.rules.drop_lowest = 1
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(56)
    expect(grades.current.possible).toBe(74)
    expect(grades.current.submissions[2].drop).toBeTruthy()
    expect(grades.current.submissions[0].drop).toBeFalsy()
    expect(grades.current.submissions[1].drop).toBeFalsy()
    expect(grades.current.submissions[3].drop).toBeFalsy()
    expect(grades.final.score).toBe(56)
    expect(grades.final.possible).toBe(74)
    expect(grades.final.submissions[2].drop).toBeTruthy()
    expect(grades.final.submissions[0].drop).toBeFalsy()
    expect(grades.final.submissions[1].drop).toBeFalsy()
    expect(grades.final.submissions[3].drop).toBeFalsy()
  })

  test('prevents submissions from being dropped for high scores', () => {
    assignmentGroup.rules = {drop_highest: 1, never_drop: [201]}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(49)
    expect(grades.current.possible).toBe(66)
    expect(grades.current.submissions[1].drop).toBeTruthy()
    expect(grades.current.submissions[0].drop).toBeFalsy()
    expect(grades.current.submissions[2].drop).toBeFalsy()
    expect(grades.current.submissions[3].drop).toBeFalsy()
    expect(grades.final.score).toBe(49)
    expect(grades.final.possible).toBe(66)
    expect(grades.final.submissions[1].drop).toBeTruthy()
    expect(grades.final.submissions[0].drop).toBeFalsy()
    expect(grades.final.submissions[2].drop).toBeFalsy()
    expect(grades.final.submissions[3].drop).toBeFalsy()
  })

  test('considers multiple assignments', () => {
    assignmentGroup.rules = {drop_lowest: 1, never_drop: [203, 204]}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(49)
    expect(grades.current.possible).toBe(66)
    expect(grades.current.submissions[1].drop).toBeTruthy()
    expect(grades.current.submissions[0].drop).toBeFalsy()
    expect(grades.current.submissions[2].drop).toBeFalsy()
    expect(grades.current.submissions[3].drop).toBeFalsy()
    expect(grades.final.score).toBe(49)
    expect(grades.final.possible).toBe(66)
    expect(grades.final.submissions[1].drop).toBeTruthy()
    expect(grades.final.submissions[0].drop).toBeFalsy()
    expect(grades.final.submissions[2].drop).toBeFalsy()
    expect(grades.final.submissions[3].drop).toBeFalsy()
  })

  test('does not drop any scores when drop_lowest is equal to the number of droppable submissions', () => {
    assignmentGroup.rules = {drop_lowest: 1, never_drop: [202, 203, 204]}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(68)
    expect(grades.current.possible).toBe(90)
    expect(grades.current.submissions.every(submission => !submission.drop)).toBeTruthy()
    expect(grades.final.score).toBe(68)
    expect(grades.final.possible).toBe(90)
    expect(grades.final.submissions.every(submission => !submission.drop)).toBeTruthy()
  })

  test('does not drop any scores when drop_highest is equal to the number of droppable submissions', () => {
    assignmentGroup.rules = {drop_highest: 1, never_drop: [202, 203, 204]}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(68)
    expect(grades.current.possible).toBe(90)
    expect(grades.current.submissions.every(submission => !submission.drop)).toBeTruthy()
    expect(grades.final.score).toBe(68)
    expect(grades.final.possible).toBe(90)
    expect(grades.final.submissions.every(submission => !submission.drop)).toBeTruthy()
  })

  test('does not drop any low score submissions when all assignments are listed as "never drop"', () => {
    assignmentGroup.rules = {drop_lowest: 1, never_drop: [201, 202, 203, 204]}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.submissions.every(submission => !submission.drop)).toBeTruthy()
    expect(grades.final.submissions.every(submission => !submission.drop)).toBeTruthy()
  })

  test('does not drop any high score submissions when all assignments are listed as "never drop"', () => {
    assignmentGroup.rules = {drop_highest: 1, never_drop: [201, 202, 203, 204]}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.submissions.every(submission => !submission.drop)).toBeTruthy()
    expect(grades.final.submissions.every(submission => !submission.drop)).toBeTruthy()
  })
})

describe('AssignmentGroupGradeCalculator', () => {
  describe('.calculate', () => {
    beforeEach(() => {
      submissions = [
        {id: 101, assignment_id: 201, score: 100},
        {id: 102, assignment_id: 202, score: null},
      ]
      assignments = [
        {id: 201, points_possible: 100, workflow_state: 'published'},
        {id: 202, points_possible: 100, workflow_state: 'unpublished'},
      ]
      assignmentGroup = {id: 301, rules: {}, assignments}
    })

    test('does not include unpublished assignments in points possible for final score', () => {
      const {
        final: {possible: finalPossible},
      } = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
      expect(finalPossible).toBe(100)
    })

    test('does not include unpublished assignments in points possible for current score', () => {
      const {
        current: {possible: currentPossible},
      } = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
      expect(currentPossible).toBe(100)
    })

    test('does not include unpublished assignment in submission_count for final score', () => {
      const {
        final: {submission_count: finalSubmissionCount},
      } = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
      expect(finalSubmissionCount).toBe(1)
    })

    test('does not include unpublished assignment in submission_count for current score', () => {
      const {
        current: {submission_count: currentSubmissionCount},
      } = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
      expect(currentSubmissionCount).toBe(1)
    })
  })
})

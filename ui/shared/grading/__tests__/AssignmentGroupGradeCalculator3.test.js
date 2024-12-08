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

describe('AssignmentGroupGradeCalculator.calculate with "drop_lowest" and "drop_highest" rules', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 100},
      {assignment_id: 202, score: 42},
      {assignment_id: 203, score: 14},
      {assignment_id: 204, score: 3},
      {assignment_id: 205, score: null},
    ]
    assignments = [
      {id: 201, points_possible: 100, omit_from_final_grade: false, anonymize_students: false},
      {id: 202, points_possible: 91, omit_from_final_grade: false, anonymize_students: false},
      {id: 203, points_possible: 55, omit_from_final_grade: false, anonymize_students: false},
      {id: 204, points_possible: 38, omit_from_final_grade: false, anonymize_students: false},
      {id: 205, points_possible: 1000, omit_from_final_grade: false, anonymize_students: false},
    ]
    assignmentGroup = {id: 301, rules: {drop_lowest: 1, drop_highest: 1}, assignments}
  })

  test('drops the most and least favorable scores', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(56)
    expect(grades.current.possible).toBe(146)
    expect(grades.current.submissions[0].drop).toBeTruthy()
    expect(grades.current.submissions[3].drop).toBeTruthy()
    expect(grades.final.score).toBe(59)
    expect(grades.final.possible).toBe(184)
    expect(grades.final.submissions[0].drop).toBeTruthy()
    expect(grades.final.submissions[4].drop).toBeTruthy()
  })

  test('does not drop higher scores when combined drop rules match the number of submissions', () => {
    assignmentGroup.rules = {drop_lowest: 2, drop_highest: 2}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(103)
    expect(grades.current.possible).toBe(138)
    expect(grades.current.submissions[1].drop).toBeTruthy()
    expect(grades.current.submissions[2].drop).toBeTruthy()
    expect(grades.current.submissions[0].drop).toBeFalsy()
    expect(grades.current.submissions[3].drop).toBeFalsy()
    expect(grades.current.submissions[4].drop).toBeFalsy()
    expect(grades.final.score).toBe(14)
    expect(grades.final.possible).toBe(55)
    expect(grades.final.submissions[0].drop).toBeTruthy()
    expect(grades.final.submissions[1].drop).toBeTruthy()
    expect(grades.final.submissions[3].drop).toBeTruthy()
    expect(grades.final.submissions[4].drop).toBeTruthy()
    expect(grades.final.submissions[2].drop).toBeFalsy()
  })

  test('does not drop higher scores when combined drop rules exceed the number of submissions', () => {
    assignmentGroup.rules = {drop_lowest: 2, drop_highest: 3}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(103)
    expect(grades.current.possible).toBe(138)
    expect(grades.current.submissions[1].drop).toBeTruthy()
    expect(grades.current.submissions[2].drop).toBeTruthy()
    expect(grades.current.submissions[0].drop).toBeFalsy()
    expect(grades.current.submissions[3].drop).toBeFalsy()
    expect(grades.current.submissions[4].drop).toBeFalsy()
    expect(grades.final.score).toBe(156)
    expect(grades.final.possible).toBe(246)
    expect(grades.final.submissions[3].drop).toBeTruthy()
    expect(grades.final.submissions[4].drop).toBeTruthy()
    expect(grades.final.submissions[0].drop).toBeFalsy()
    expect(grades.final.submissions[1].drop).toBeFalsy()
    expect(grades.final.submissions[2].drop).toBeFalsy()
  })
})

describe('AssignmentGroupGradeCalculator.calculate "drop_highest" rule (2)', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 100},
      {assignment_id: 202, score: 42},
      {assignment_id: 203, score: 14},
      {assignment_id: 204, score: 30},
      {assignment_id: 205, score: null},
    ]
    assignments = [
      {id: 201, points_possible: 100, omit_from_final_grade: false, anonymize_students: false},
      {id: 202, points_possible: 91, omit_from_final_grade: false, anonymize_students: false},
      {id: 203, points_possible: 55, omit_from_final_grade: false, anonymize_students: false},
      {id: 204, points_possible: 38, omit_from_final_grade: false, anonymize_students: false},
      {id: 205, points_possible: 1000, omit_from_final_grade: false, anonymize_students: false},
    ]
    assignmentGroup = {id: 301, rules: {drop_highest: 2}, assignments}
  })

  test('drops multiple submissions to minimize overall percentage grade', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(56)
    expect(grades.current.possible).toBe(146)
    expect(grades.current.submissions[0].drop).toBeTruthy()
    expect(grades.current.submissions[3].drop).toBeTruthy()
    expect(grades.final.score).toBe(44)
    expect(grades.final.possible).toBe(1093)
    expect(grades.final.submissions[0].drop).toBeTruthy()
    expect(grades.final.submissions[1].drop).toBeTruthy()
  })

  test('does not drop any scores when drop_highest is equal to the number of droppable submissions', () => {
    assignmentGroup.rules = {drop_highest: 4}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(186)
    expect(grades.current.possible).toBe(284)
    expect(grades.current.submissions.every(sub => !sub.drop)).toBe(true)
    expect(grades.final.score).toBe(0)
    expect(grades.final.possible).toBe(1000)
    expect(grades.final.submissions[0].drop).toBeTruthy()
    expect(grades.final.submissions[1].drop).toBeTruthy()
    expect(grades.final.submissions[2].drop).toBeTruthy()
    expect(grades.final.submissions[3].drop).toBeTruthy()
    expect(grades.final.submissions[4].drop).toBeFalsy()
  })

  test('does not drop any scores when drop_highest is greater than the number of submissions', () => {
    assignmentGroup.rules = {drop_highest: 5}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(186)
    expect(grades.current.possible).toBe(284)
    expect(grades.current.submissions.every(sub => !sub.drop)).toBe(true)
    expect(grades.final.score).toBe(186)
    expect(grades.final.possible).toBe(1284)
    expect(grades.final.submissions.every(sub => !sub.drop)).toBe(true)
  })
})

describe('AssignmentGroupGradeCalculator.calculate with equivalent submissions and assignments', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 9},
      {assignment_id: 202, score: 9},
      {assignment_id: 203, score: 9},
      {assignment_id: 204, score: 9},
    ]
    assignments = [
      {id: 201, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
      {id: 202, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
      {id: 203, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
      {id: 204, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
    ]
    assignmentGroup = {id: 301, rules: {}, assignments}
  })

  test('drops the same low-score submission regardless of submission order', () => {
    assignmentGroup.rules = {drop_lowest: 1}
    let grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    const droppedSubmission1 = _.find(grades.current.submissions, 'drop')
    submissions.reverse()
    grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    const droppedSubmission2 = _.find(grades.current.submissions, 'drop')
    expect(droppedSubmission1.assignment_id).toBe(droppedSubmission2.assignment_id)
  })

  test('drops the same high-score submission regardless of submission order', () => {
    assignmentGroup.rules = {drop_highest: 1}
    let grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    const droppedSubmission1 = _.find(grades.current.submissions, 'drop')
    submissions.reverse()
    grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    const droppedSubmission2 = _.find(grades.current.submissions, 'drop')
    expect(droppedSubmission1.assignment_id).toBe(droppedSubmission2.assignment_id)
  })

  test('drops the same low-score submission for unpointed assignments', () => {
    assignmentGroup.rules = {drop_lowest: 1}
    assignmentGroup.assignments.forEach(assignment => {
      assignment.points_possible = 0
    })
    let grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    const droppedSubmission1 = _.find(grades.current.submissions, 'drop')
    submissions.reverse()
    grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    const droppedSubmission2 = _.find(grades.current.submissions, 'drop')
    expect(droppedSubmission1.assignment_id).toBe(droppedSubmission2.assignment_id)
  })

  test('drops the same high-score submission for unpointed assignments', () => {
    assignmentGroup.rules = {drop_highest: 1}
    assignmentGroup.assignments.forEach(assignment => {
      assignment.points_possible = 0
    })
    let grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    const droppedSubmission1 = _.find(grades.current.submissions, 'drop')
    submissions.reverse()
    grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    const droppedSubmission2 = _.find(grades.current.submissions, 'drop')
    expect(droppedSubmission1.assignment_id).toBe(droppedSubmission2.assignment_id)
  })
})

describe('AssignmentGroupGradeCalculator.calculate with only unpointed assignments', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 10},
      {assignment_id: 202, score: 5},
      {assignment_id: 203, score: 20},
      {assignment_id: 204, score: 0},
    ]
    assignments = [
      {id: 201, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
      {id: 202, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
      {id: 203, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
      {id: 204, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
    ]
    assignmentGroup = {id: 301, rules: {}, assignments}
  })

  test('drops the submission with the lowest score when drop_lowest is 1', () => {
    assignmentGroup.rules = {drop_lowest: 1}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(35)
    expect(grades.current.submissions[3].drop).toBeTruthy()
  })

  test('drops the submission with the highest score when drop_highest is 1', () => {
    assignmentGroup.rules = {drop_highest: 1}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(15)
    expect(grades.current.submissions[2].drop).toBeTruthy()
  })

  test('drops submissions that match the given rules', () => {
    assignmentGroup.rules = {drop_highest: 1, drop_lowest: 2}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(10)
    expect(grades.current.submissions[1].drop).toBeTruthy()
    expect(grades.current.submissions[2].drop).toBeTruthy()
    expect(grades.current.submissions[3].drop).toBeTruthy()
  })
})

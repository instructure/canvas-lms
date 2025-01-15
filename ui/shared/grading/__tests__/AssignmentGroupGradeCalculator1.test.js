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

describe('AssignmentGroupGradeCalculator.calculate with no submissions and no assignments', () => {
  beforeEach(() => {
    submissions = []
    assignmentGroup = {id: 301, rules: {}, assignments: [], group_weight: 100}
  })

  test('returns a current and final score of 0', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(0)
    expect(grades.final.score).toBe(0)
  })

  test('includes 0 points possible', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.possible).toBe(0)
    expect(grades.final.possible).toBe(0)
  })

  test('includes assignment group attributes', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.assignmentGroupId).toBe(301)
    expect(grades.assignmentGroupWeight).toBe(100)
  })

  test('uses a score unit of "points"', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.scoreUnit).toBe('points')
  })
})

describe('AssignmentGroupGradeCalculator.calculate with some assignments and submissions', () => {
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
    assignmentGroup = {id: 301, rules: {}, assignments}
  })

  test('adds all scores for current and final grades', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(159)
    expect(grades.final.score).toBe(159)
  })

  test('excludes assignment points on ungraded submissions for the current grade', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.possible).toBe(284)
    expect(grades.final.possible).toBe(1284)
  })

  test('ignores hidden submissions', () => {
    submissions[1].hidden = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(117)
    expect(grades.final.score).toBe(117)
  })

  test('excludes assignment points on hidden submissions', () => {
    submissions[1].hidden = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.possible).toBe(193)
    expect(grades.final.possible).toBe(1193)
  })

  test('ignores excused submissions', () => {
    submissions[1].excused = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(117)
    expect(grades.final.score).toBe(117)
  })

  test('excludes assignment points on excused submissions', () => {
    submissions[1].excused = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.possible).toBe(193)
    expect(grades.final.possible).toBe(1193)
  })

  test('excludes submissions "pending review" from the current grade', () => {
    submissions[1].workflow_state = 'pending_review'
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(117)
    expect(grades.current.possible).toBe(193)
  })

  test('includes submissions "pending review" in the final grade', () => {
    submissions[1].workflow_state = 'pending_review'
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.final.score).toBe(159)
    expect(grades.final.possible).toBe(1284)
  })

  test('excludes assignments "omitted from final grade" from the current grade', () => {
    assignmentGroup.assignments[2].omit_from_final_grade = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(145)
    expect(grades.current.possible).toBe(229)
  })

  test('excludes assignments "anonymizing students" from the current grade', () => {
    assignmentGroup.assignments[2].anonymize_students = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(145)
    expect(grades.current.possible).toBe(229)
  })

  test('includes assignments "anonymizing students" in the current grade when "grade calc ignore unposted anonymous" flag is disabled', () => {
    assignmentGroup.assignments[2].anonymize_students = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, false)
    expect(grades.current.score).toBe(159)
    expect(grades.current.possible).toBe(284)
  })

  test('excludes assignments "omitted from final grade" from the final grade', () => {
    assignmentGroup.assignments[2].omit_from_final_grade = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.final.score).toBe(145)
    expect(grades.final.possible).toBe(1229)
  })

  test('excludes assignments "anonymizing students" from the final grade', () => {
    assignmentGroup.assignments[2].anonymize_students = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.final.score).toBe(145)
    expect(grades.final.possible).toBe(1229)
  })

  test('excludes ungraded assignments "omitted from final grade" from the final grade', () => {
    assignmentGroup.assignments[4].omit_from_final_grade = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.final.score).toBe(159)
    expect(grades.final.possible).toBe(284)
  })

  test('eliminates multiple submissions for the same assignment', () => {
    submissions.push({...submissions[0]})
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(159)
    expect(grades.final.score).toBe(159)
    expect(grades.current.possible).toBe(284)
    expect(grades.final.possible).toBe(1284)
  })

  test('avoids floating point rounding errors on submission percentages', () => {
    submissions[0].score = 21.4
    assignments[0].points_possible = 40
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.submissions[0].percent).toBeCloseTo(0.535)
    expect(grades.final.submissions[0].percent).toBeCloseTo(0.535)
  })
})

describe('AssignmentGroupGradeCalculator.calculate with assignments having no points possible', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 10},
      {assignment_id: 202, score: 10},
    ]
    assignments = [
      {id: 201, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
      {id: 202, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
    ]
    assignmentGroup = {id: 301, rules: {}, assignments}
  })

  test('includes scores for submissions on unpointed assignments', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(20)
    expect(grades.final.score).toBe(20)
  })
})

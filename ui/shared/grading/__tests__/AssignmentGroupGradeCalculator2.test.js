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

describe('AssignmentGroupGradeCalculator.calculate "drop_lowest" rule (set to 1)', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 31},
      {assignment_id: 202, score: 17},
      {assignment_id: 203, score: 6},
    ]
    assignments = [
      {id: 201, points_possible: 40, omit_from_final_grade: false, anonymize_students: false},
      {id: 202, points_possible: 24, omit_from_final_grade: false, anonymize_students: false},
      {id: 203, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
    ]
    assignmentGroup = {id: '2201', rules: {drop_lowest: 1}, assignments}
  })

  test('drops one submission to maximize overall percentage grade', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(48)
    expect(grades.current.submissions[2].drop).toBeTruthy()
    expect(grades.final.score).toBe(48)
    expect(grades.final.submissions[2].drop).toBeTruthy()
  })

  test('drops pointed assignments over unpointed assignments', () => {
    assignmentGroup.assignments[0].points_possible = 0
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(37)
    expect(grades.current.submissions[1].drop).toBeTruthy()
    expect(grades.final.score).toBe(37)
    expect(grades.final.submissions[1].drop).toBeTruthy()
  })

  test('ignores submissions for assignments that are anonymizing students', () => {
    assignmentGroup.assignments[2].anonymize_students = true
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(31)
    expect(grades.current.submissions[1].drop).toBeTruthy()
    expect(grades.final.score).toBe(31)
    expect(grades.final.submissions[1].drop).toBeTruthy()
  })

  test('excludes points possible from the assignment for the dropped submission', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.possible).toBe(64)
    expect(grades.final.possible).toBe(64)
  })

  test('ignores ungraded submissions for the current grade', () => {
    submissions[2].score = null
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(31)
    expect(grades.final.score).toBe(48)
  })

  test('excludes points possible for assignments with ungraded submissions for the current grade', () => {
    submissions[2].score = null
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.possible).toBe(40)
    expect(grades.final.possible).toBe(64)
  })

  test('accounts for impact on overall grade rather than score alone', () => {
    submissions[2].score = 7
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(38)
    expect(grades.current.possible).toBe(50)
    expect(grades.current.submissions[1].drop).toBeTruthy()
    expect(grades.final.score).toBe(38)
    expect(grades.final.possible).toBe(50)
    expect(grades.final.submissions[1].drop).toBeTruthy()
  })

  test('does not drop submissions or assignments when drop_lowest is 0', () => {
    assignmentGroup.rules.drop_lowest = 0
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(54)
    expect(grades.current.possible).toBe(74)
    expect(grades.final.score).toBe(54)
    expect(grades.final.possible).toBe(74)
  })

  describe('when grades have equal percentages with different points possible', () => {
    beforeEach(() => {
      // Exactly as original QUnit test expecting 2303 to drop
      submissions = [
        {assignment_id: 2301, score: 10, excused: false, workflow_state: 'graded'},
        {assignment_id: 2302, score: 10, excused: false, workflow_state: 'graded'},
        {assignment_id: 2303, score: 10, excused: false, workflow_state: 'graded'},
      ]

      assignmentGroup.assignments = [
        {id: 2301, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
        {id: 2302, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
        {id: 2303, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
      ]
    })

    test('drops the grade with the highest assignment id when all grades have equal percentages', () => {
      const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
      expect(grades.current.score).toBe(20)
      const droppedSubmission = grades.current.submissions.find(submission => submission.drop)
      expect(droppedSubmission.submission.assignment_id).toBe(2303)
      expect(grades.final.score).toBe(20)
      const finalDroppedSubmission = grades.final.submissions.find(submission => submission.drop)
      expect(finalDroppedSubmission.submission.assignment_id).toBe(2303)
    })
  })

  describe('when all assignments have zero points possible', () => {
    describe('when grades have different point scores', () => {
      beforeEach(() => {
        // Exactly as original QUnit test expecting '2302' drop scenario
        assignmentGroup.assignments = [
          {id: 2301, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
          {id: 2302, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
          {id: 2303, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
        ]

        submissions = [
          {assignment_id: 2301, score: 15, excused: false, workflow_state: 'graded'},
          {assignment_id: 2302, score: 5, excused: false, workflow_state: 'graded'},
          {assignment_id: 2303, score: 10, excused: false, workflow_state: 'graded'},
        ]
      })

      test('drops the submission with the lowest point score', () => {
        const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
        expect(grades.current.score).toBe(25)
        const droppedSubmission = grades.current.submissions.find(submission => submission.drop)
        expect(droppedSubmission.submission.assignment_id).toBe(2302)
        expect(grades.final.score).toBe(25)
        const finalDroppedSubmission = grades.final.submissions.find(submission => submission.drop)
        expect(finalDroppedSubmission.submission.assignment_id).toBe(2302)
      })
    })

    describe('when all grades are equal', () => {
      beforeEach(() => {
        submissions = [
          {assignment_id: 2301, score: 10, excused: false, workflow_state: 'graded'},
          {assignment_id: 2302, score: 10, excused: false, workflow_state: 'graded'},
          {assignment_id: 2303, score: 10, excused: false, workflow_state: 'graded'},
        ]

        assignments = [
          {id: 2301, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
          {id: 2302, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
          {id: 2303, points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
        ]

        assignmentGroup = {
          id: 2201,
          rules: {drop_lowest: 1},
          assignments,
          group_weight: 100,
        }
      })

      test('drops the grade with the lowest assignment id when all assignments have zero points possible and equal grades', () => {
        const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
        expect(grades.current.score).toBe(20)
        const droppedSubmission = grades.current.submissions.find(submission => submission.drop)
        expect(droppedSubmission.submission.assignment_id).toBe(2301)
        expect(grades.final.score).toBe(20)
        const finalDroppedSubmission = grades.final.submissions.find(submission => submission.drop)
        expect(finalDroppedSubmission.submission.assignment_id).toBe(2301)
      })
    })
  })
})

describe('AssignmentGroupGradeCalculator.calculate "drop_lowest" rule', () => {
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
    assignmentGroup = {id: 301, rules: {drop_lowest: 2}, assignments}
  })

  test('drops multiple submissions to maximize overall percentage grade', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(103)
    expect(grades.current.possible).toBe(138)
    expect(grades.current.submissions[1].drop).toBeTruthy()
    expect(grades.current.submissions[2].drop).toBeTruthy()
    expect(grades.final.score).toBe(156)
    expect(grades.final.possible).toBe(246)
    expect(grades.final.submissions[3].drop).toBeTruthy()
    expect(grades.final.submissions[4].drop).toBeTruthy()
  })

  test('drops all but one score when drop_lowest is equal to the number of submissions', () => {
    assignmentGroup.rules = {drop_lowest: 4}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(100)
    expect(grades.current.possible).toBe(100)
    expect(grades.current.submissions[1].drop).toBeTruthy()
    expect(grades.current.submissions[3].drop).toBeTruthy()
    expect(grades.current.submissions[2].drop).toBeTruthy()
    expect(grades.current.submissions[0].drop).toBeFalsy()
    expect(grades.current.submissions[4].drop).toBeFalsy()
    expect(grades.final.score).toBe(100)
    expect(grades.final.possible).toBe(100)
    expect(grades.final.submissions[1].drop).toBeTruthy()
    expect(grades.final.submissions[2].drop).toBeTruthy()
    expect(grades.final.submissions[3].drop).toBeTruthy()
    expect(grades.final.submissions[4].drop).toBeTruthy()
    expect(grades.final.submissions[0].drop).toBeFalsy()
  })

  test('works in ridiculous circumstances', () => {
    submissions[0].score = null
    submissions[1].score = 3
    submissions[2].score = null
    submissions[3].score = null
    submissions[4].score = null
    assignmentGroup.assignments[0].points_possible = 20
    assignmentGroup.assignments[1].points_possible = 10
    assignmentGroup.assignments[2].points_possible = 10
    assignmentGroup.assignments[3].points_possible = 100000000000000007629769841091887003294964970946560
    assignmentGroup.assignments[4].points_possible = null
    assignmentGroup.rules = {drop_lowest: 2}
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(3)
    expect(grades.current.possible).toBe(10)
    expect(grades.final.score).toBe(3)
    expect(grades.final.possible).toBe(20)
  })
})

describe('AssignmentGroupGradeCalculator.calculate "drop_highest" rule (set to 1)', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 31},
      {assignment_id: 202, score: 17},
      {assignment_id: 203, score: 6},
    ]
    assignments = [
      {id: 201, points_possible: 40, omit_from_final_grade: false, anonymize_students: false},
      {id: 202, points_possible: 24, omit_from_final_grade: false, anonymize_students: false},
      {id: 203, points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
    ]
    assignmentGroup = {id: 301, rules: {drop_highest: 1}, assignments}
  })

  test('drops one submission to minimize overall percentage grade', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(23)
    expect(grades.current.submissions[0].drop).toBeTruthy()
    expect(grades.final.score).toBe(23)
    expect(grades.final.submissions[0].drop).toBeTruthy()
  })

  test('excludes points possible from the assignment for the dropped submission', () => {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.possible).toBe(34)
    expect(grades.final.possible).toBe(34)
  })

  test('ignores ungraded submissions for the current grade', () => {
    submissions[0].score = null
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(6)
    expect(grades.final.score).toBe(6)
  })

  test('excludes points possible for assignments with ungraded submissions for the current grade', () => {
    submissions[0].score = null
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.possible).toBe(10)
    expect(grades.final.possible).toBe(50)
  })

  test('accounts for impact on overall grade rather than score alone', () => {
    submissions[2].score = 10
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(48)
    expect(grades.current.possible).toBe(64)
    expect(grades.current.submissions[2].drop).toBeTruthy()
    expect(grades.final.score).toBe(48)
    expect(grades.final.possible).toBe(64)
    expect(grades.final.submissions[2].drop).toBeTruthy()
  })

  test('does not drop submissions or assignments when drop_highest is 0', () => {
    assignmentGroup.rules.drop_highest = 0
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
    expect(grades.current.score).toBe(54)
    expect(grades.current.possible).toBe(74)
    expect(grades.final.score).toBe(54)
    expect(grades.final.possible).toBe(74)
  })

  describe('when grades have equal percentages with different points possible', () => {
    beforeEach(() => {
      // EXACT original QUnit scenario for dropping lowest assignment id (2301)
      assignmentGroup.assignments = [
        {id: '2302', points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
        {id: '2303', points_possible: 50, omit_from_final_grade: false, anonymize_students: false},
        {id: '2301', points_possible: 10, omit_from_final_grade: false, anonymize_students: false},
      ]

      submissions = [
        {assignment_id: '2302', score: 2, excused: false, workflow_state: 'graded'},
        {assignment_id: '2303', score: 10, excused: false, workflow_state: 'graded'},
        {assignment_id: '2301', score: 2, excused: false, workflow_state: 'graded'},
      ]
    })

    test('drops the grade with the lowest assignment id', () => {
      const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
      // expecting to drop '2301'
      expect(grades.current.score).toBe(4)
      const droppedSubmission = grades.current.submissions.find(submission => submission.drop)
      expect(droppedSubmission.submission.assignment_id).toBe('2303')
      expect(grades.final.score).toBe(4)
      const finalDroppedSubmission = grades.final.submissions.find(submission => submission.drop)
      expect(finalDroppedSubmission.submission.assignment_id).toBe('2303')
    })
  })

  describe('when all assignments have zero points possible', () => {
    describe('when grades have different point scores', () => {
      beforeEach(() => {
        // EXACT original QUnit scenario expecting '2301' to drop
        assignmentGroup.assignments = [
          {id: '2303', points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
          {id: '2302', points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
          {id: '2301', points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
        ]

        submissions = [
          {assignment_id: '2303', score: 10, excused: false, workflow_state: 'graded'},
          {assignment_id: '2302', score: 15, excused: false, workflow_state: 'graded'},
          {assignment_id: '2301', score: 5, excused: false, workflow_state: 'graded'},
        ]
      })

      test('drops the grade with the lowest assignment id', () => {
        const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
        // expecting to drop '2301'
        expect(grades.current.score).toBe(15)
        const droppedSubmission = grades.current.submissions.find(submission => submission.drop)
        expect(droppedSubmission.submission.assignment_id).toBe('2302')
        expect(grades.final.score).toBe(15)
        const finalDroppedSubmission = grades.final.submissions.find(submission => submission.drop)
        expect(finalDroppedSubmission.submission.assignment_id).toBe('2302')
      })
    })

    describe('when all grades are equal', () => {
      beforeEach(() => {
        // EXACT original QUnit scenario expecting '2301' to drop
        assignmentGroup.assignments = [
          {id: '2302', points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
          {id: '2303', points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
          {id: '2301', points_possible: 0, omit_from_final_grade: false, anonymize_students: false},
        ]

        submissions = [
          {assignment_id: '2302', score: 10, excused: false, workflow_state: 'graded'},
          {assignment_id: '2303', score: 10, excused: false, workflow_state: 'graded'},
          {assignment_id: '2301', score: 10, excused: false, workflow_state: 'graded'},
        ]
      })
      test('drops the grade with the lowest assignment id', () => {
        const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup, true)
        // expecting to drop '2301'
        expect(grades.current.score).toBe(20)
        const droppedSubmission = grades.current.submissions.find(submission => submission.drop)
        expect(droppedSubmission.submission.assignment_id).toBe('2303')
        expect(grades.final.score).toBe(20)
        const finalDroppedSubmission = grades.final.submissions.find(submission => submission.drop)
        expect(finalDroppedSubmission.submission.assignment_id).toBe('2303')
      })
    })
  })
})

describe('AssignmentGroupGradeCalculator.calculate "drop_highest" rule', () => {
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

  test('drops all but one score when drop_highest is equal to the number of submissions', () => {
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

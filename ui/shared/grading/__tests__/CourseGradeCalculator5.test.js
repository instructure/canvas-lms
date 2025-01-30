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

import _ from 'lodash'
import CourseGradeCalculator from '../CourseGradeCalculator'

const equal = (x, y) => expect(x).toBe(y)
const strictEqual = (x, y) => expect(x).toStrictEqual(y)
const deepEqual = (x, y) => expect(x).toEqual(y)

let submissions
let assignments
let assignmentGroups
let gradingPeriodSet
let gradingPeriods
let effectiveDueDates

function calculateWithGradingPeriods(weightingScheme, ignoreUnpostedAnonymous = true) {
  return CourseGradeCalculator.calculate(
    submissions,
    assignmentGroups,
    weightingScheme,
    ignoreUnpostedAnonymous,
    gradingPeriodSet,
    effectiveDueDates,
  )
}

// This is a use case that is STRONGLY discouraged to users, but is still not
// prevented. Assignment group rules must never be applied to multiple grading
// periods in combination. Doing so would impact grades in closed grading
// periods, which must never occur.
describe('CourseGradeCalculator.calculate with assignment groups across multiple weighted grading periods', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 10},
      {assignment_id: 202, score: 5},
      {assignment_id: 203, score: 3},
    ]
    assignments = [
      {id: 201, points_possible: 10, omit_from_final_grade: false},
      {id: 202, points_possible: 10, omit_from_final_grade: false},
      {id: 203, points_possible: 10, omit_from_final_grade: false},
    ]
    assignmentGroups = [
      {id: 301, group_weight: 50, rules: {}, assignments: assignments.slice(0, 2)},
      {id: 302, group_weight: 50, rules: {}, assignments: assignments.slice(2, 3)},
    ]
    gradingPeriods = [
      {id: '701', weight: 50},
      {id: '702', weight: 50},
    ]
    gradingPeriodSet = {gradingPeriods, weighted: true}
    effectiveDueDates = {
      201: {grading_period_id: '701'}, // in first assignment group and first grading period
      202: {grading_period_id: '702'}, // in first assignment group and second grading period
      203: {grading_period_id: '702'},
    }
  })

  test('recombines assignment group grades of divided assignment groups', () => {
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.assignmentGroups[301].current.score, 15)
    equal(grades.assignmentGroups[301].final.score, 15)
    equal(grades.assignmentGroups[301].current.possible, 20)
    equal(grades.assignmentGroups[301].final.possible, 20)
  })

  test('recombines assignment group submissions of divided assignment groups', () => {
    const grades = calculateWithGradingPeriods('percent')
    const listSubmissionAssignmentIds = grade =>
      _.map(grade.submissions, ({submission}) => submission.assignment_id)
    deepEqual(listSubmissionAssignmentIds(grades.assignmentGroups[301].current), [201, 202])
    deepEqual(listSubmissionAssignmentIds(grades.assignmentGroups[301].final), [201, 202])
    equal(grades.assignmentGroups[301].current.submission_count, 2)
    equal(grades.assignmentGroups[301].final.submission_count, 2)
  })

  test('divides assignment groups across related grading periods', () => {
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.gradingPeriods[701].assignmentGroups[301].current.score, 10)
    equal(grades.gradingPeriods[701].assignmentGroups[301].final.score, 10)
    equal(grades.gradingPeriods[702].assignmentGroups[301].current.score, 5)
    equal(grades.gradingPeriods[702].assignmentGroups[301].final.score, 5)
    equal(grades.gradingPeriods[702].assignmentGroups[302].current.score, 3)
    equal(grades.gradingPeriods[702].assignmentGroups[302].final.score, 3)
  })

  test('accounts for divided assignment groups in grading period scores', () => {
    const grades = calculateWithGradingPeriods('percent')
    equal(
      grades.gradingPeriods[701].current.score,
      100,
      'grading period 701 scores include only assignment 201',
    )
    equal(
      grades.gradingPeriods[701].final.score,
      100,
      'grading period 701 scores include only assignment 201',
    )
    equal(
      grades.gradingPeriods[702].current.score,
      40,
      'grading period 702 scores include assignments 202 & 203',
    )
    equal(
      grades.gradingPeriods[702].final.score,
      40,
      'grading period 702 scores include assignments 202 & 203',
    )
  })

  test('weights assignments groups with equal grading period weights', () => {
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 70, 'each grading period accounts for half of the current score')
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.score, 70, 'each grading period accounts for half of the final score')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('weights assignments groups with unequal grading period weights', () => {
    gradingPeriods[0].weight = 25
    gradingPeriods[1].weight = 75
    const grades = calculateWithGradingPeriods('percent')
    equal(
      grades.current.score,
      55,
      'lower-scoring grading periods with higher weight decrease the current score',
    )
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(
      grades.final.score,
      55,
      'lower-scoring grading periods with higher weight decrease the final score',
    )
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('excludes assignment groups containing only assignments not assigned to the given student', () => {
    delete effectiveDueDates[203]
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 75, 'assignment 203 is not assigned to the student')
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.score, 75, 'assignment 203 is not assigned to the student')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('excludes assignments not assigned to the given student', () => {
    delete effectiveDueDates[202]
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 65, 'assignment 202 is not assigned to the student')
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.score, 65, 'assignment 202 is not assigned to the student')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('avoids floating point errors in assignment group scores', () => {
    submissions = [
      {assignment_id: 201, score: 110.1},
      {assignment_id: 202, score: 170.7},
      {assignment_id: 203, score: 103.3},
    ]
    assignments = [
      {id: 201, points_possible: 120},
      {id: 202, points_possible: 190},
      {id: 203, points_possible: 120},
    ]
    assignmentGroups = [
      {id: 301, group_weight: 50, rules: {}, assignments: assignments.slice(0, 2)},
      {id: 302, group_weight: 50, rules: {}, assignments: assignments.slice(2, 3)},
    ]

    // 110.1 + 170.7 === 280.79999999999995
    const grades = calculateWithGradingPeriods('percent')
    strictEqual(grades.assignmentGroups[301].current.score, 280.8)
    strictEqual(grades.assignmentGroups[302].current.score, 103.3)
    strictEqual(grades.assignmentGroups[301].final.score, 280.8)
    strictEqual(grades.assignmentGroups[302].final.score, 103.3)
  })

  test('avoids floating point errors in assignment group points possible', () => {
    submissions = [
      {assignment_id: 201, score: 100},
      {assignment_id: 202, score: 100},
      {assignment_id: 203, score: 90},
    ]
    assignments = [
      {id: 201, points_possible: 110.1},
      {id: 202, points_possible: 170.7},
      {id: 203, points_possible: 103.3},
    ]
    assignmentGroups = [
      {id: 301, group_weight: 50, rules: {}, assignments: assignments.slice(0, 2)},
      {id: 302, group_weight: 50, rules: {}, assignments: assignments.slice(2, 3)},
    ]

    // 110.1 + 170.7 === 280.79999999999995
    const grades = calculateWithGradingPeriods('percent')
    strictEqual(grades.assignmentGroups[301].current.possible, 280.8)
    strictEqual(grades.assignmentGroups[302].current.possible, 103.3)
    strictEqual(grades.assignmentGroups[301].final.possible, 280.8)
    strictEqual(grades.assignmentGroups[302].final.possible, 103.3)
  })
})

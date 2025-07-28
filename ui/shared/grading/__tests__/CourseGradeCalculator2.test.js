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

let submissions
let assignments
let assignmentGroups
let gradingPeriodSet
let effectiveDueDates

function calculateWithoutGradingPeriods(weightingScheme, ignoreUnpostedAnonymous = true) {
  return CourseGradeCalculator.calculate(
    submissions,
    assignmentGroups,
    weightingScheme,
    ignoreUnpostedAnonymous,
  )
}

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

describe('CourseGradeCalculator.calculate with no submissions and no assignments', () => {
  beforeEach(() => {
    submissions = []
    assignmentGroups = [{id: 301, rules: {}, group_weight: 100, assignments: []}]
  })

  test('includes assignment group grades', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.assignmentGroups[301].current.score, 0)
    equal(grades.assignmentGroups[301].final.score, 0)
    equal(grades.assignmentGroups[301].current.possible, 0)
    equal(grades.assignmentGroups[301].final.possible, 0)
  })

  test('returns a current and final score of 0 when weighting scheme is points', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.current.score, 0, 'current score is 0 when there are no submissions')
    equal(grades.final.score, 0, 'final score is 0 when there are no submissions')
  })

  test('includes 0 points possible when weighting scheme is points', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.current.possible, 0, 'current possible is sum of all assignment points')
    equal(grades.final.possible, 0, 'final possible is sum of all assignment points')
  })

  test('returns a current and final score of null when weighting scheme is percent', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.current.score, null, 'current score cannot be calculated when there is no data')
    equal(grades.final.score, null, 'final score cannot be calculated when there is no data')
  })

  test('sets possible to 0 for current grade when weighting scheme is percent', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.current.possible, 0, 'current possible is 0 when there are no assignments')
    equal(grades.final.possible, 100, 'percent possible is 100')
  })

  test('uses a score unit of "points" when weighting scheme is not percent', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.scoreUnit, 'points')
  })

  test('uses a score unit of "percentage" when weighting scheme is percent', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.scoreUnit, 'percentage')
  })
})

describe('CourseGradeCalculator.calculate with some assignments and submissions', () => {
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
    assignmentGroups = [
      {id: 301, rules: {}, group_weight: 50, assignments: assignments.slice(0, 2)},
      {id: 302, rules: {}, group_weight: 50, assignments: assignments.slice(2, 5)},
    ]
  })

  test('avoids floating point errors in current and final score when assignment groups are weighted', () => {
    submissions = [
      {assignment_id: 201, score: 194.5},
      {assignment_id: 202, score: 100.0},
      {assignment_id: 203, score: 94.5},
      {assignment_id: 204, score: 89.5},
    ]

    assignments = [
      {id: 201, points_possible: 200, anonymize_students: false},
      {id: 202, points_possible: 100, anonymize_students: false},
      {id: 203, points_possible: 100, anonymize_students: false},
      {id: 204, points_possible: 100, anonymize_students: false},
    ]

    assignmentGroups = [
      {id: 301, rules: {}, group_weight: 10, assignments: assignments.slice(0, 1)},
      {id: 302, rules: {}, group_weight: 10, assignments: assignments.slice(1, 2)},
      {id: 303, rules: {}, group_weight: 50, assignments: assignments.slice(2, 3)},
      {id: 304, rules: {}, group_weight: 30, assignments: assignments.slice(3, 4)},
    ]

    // 9.725 + 10 + 47.25 + 26.85 === 93.82499999999999
    const grades = calculateWithoutGradingPeriods('percent')
    strictEqual(grades.current.score, 93.83)
    strictEqual(grades.final.score, 93.83)
  })

  test('avoids floating point errors in current and final score when assignment groups are not weighted', () => {
    submissions = [
      {assignment_id: 201, score: 110.1},
      {assignment_id: 202, score: 170.7},
    ]

    assignments = [
      {id: 201, points_possible: 120},
      {id: 202, points_possible: 180},
    ]

    assignmentGroups = [
      {id: 301, rules: {}, group_weight: 10, assignments: assignments.slice(0, 1)},
      {id: 302, rules: {}, group_weight: 10, assignments: assignments.slice(1, 2)},
    ]

    // 110.1 + 170.7 === 280.79999999999995
    const grades = calculateWithoutGradingPeriods('points')
    strictEqual(grades.current.score, 280.8)
    strictEqual(grades.final.score, 280.8)
  })

  test('avoids floating point errors in points possible when assignment groups are not weighted', () => {
    submissions = [
      {assignment_id: 201, score: 100},
      {assignment_id: 202, score: 150},
    ]

    assignments = [
      {id: 201, points_possible: 110.1},
      {id: 202, points_possible: 170.7},
    ]

    assignmentGroups = [
      {id: 301, rules: {}, group_weight: 10, assignments: assignments.slice(0, 1)},
      {id: 302, rules: {}, group_weight: 10, assignments: assignments.slice(1, 2)},
    ]

    // 110.1 + 170.7 === 280.79999999999995
    const grades = calculateWithoutGradingPeriods('points')
    strictEqual(grades.current.possible, 280.8)
    strictEqual(grades.final.possible, 280.8)
  })

  test('avoids floating point errors in assignment group weights', () => {
    submissions = [
      {assignment_id: 201, score: 124.46},
      {assignment_id: 202, score: 144.53},
    ]
    assignments = [
      {id: 201, points_possible: 148},
      {id: 202, points_possible: 148},
    ]
    assignmentGroups = [
      {id: 301, group_weight: 50, rules: {}, assignments: assignments.slice(0, 1)},
      {id: 302, group_weight: 50, rules: {}, assignments: assignments.slice(1, 2)},
    ]

    //   124.46 / 148 * 0.5 (weight)
    // + 144.53 / 148 * 0.5 (weight)
    // = 90.87499999999999 (expected 90.875)
    const grades = calculateWithGradingPeriods('percent')
    strictEqual(grades.current.score, 90.88)
    strictEqual(grades.final.score, 90.88)
  })

  test('avoids floating point errors when up-scaling assignment group weights', () => {
    submissions = [
      {assignment_id: 201, score: 81.01},
      {assignment_id: 202, score: 96.08},
    ]
    assignments = [
      {id: 201, points_possible: 100},
      {id: 202, points_possible: 100},
    ]
    assignmentGroups = [
      {id: 301, group_weight: 40, rules: {}, assignments: assignments.slice(0, 1)},
      {id: 302, group_weight: 40, rules: {}, assignments: assignments.slice(1, 2)},
    ]

    //   81.01 / 100 * 0.4 (weight)
    // + 96.08 / 100 * 0.4 (weight)
    // = 0.7083600000000001 (weighted sum, expected 70.836)
    //
    // weighted sum * 100 / 80 (total possible)
    // = 88.54499999999999 (expected 88.545)
    const grades = calculateWithGradingPeriods('percent')
    strictEqual(grades.current.score, 88.55)
    strictEqual(grades.final.score, 88.55)
  })

  test('includes assignment group grades', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.assignmentGroups[301].current.score, 142)
    equal(grades.assignmentGroups[301].final.score, 142)
    equal(grades.assignmentGroups[301].current.possible, 191)
    equal(grades.assignmentGroups[301].final.possible, 191)
    equal(grades.assignmentGroups[302].current.score, 17)
    equal(grades.assignmentGroups[302].final.score, 17)
    equal(grades.assignmentGroups[302].current.possible, 93)
    equal(grades.assignmentGroups[302].final.possible, 1093)
  })

  test('excludes assignments that are anonymizing students in total calculations', () => {
    assignments[0].anonymize_students = true
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.assignmentGroups[301].current.score, 42)
    equal(grades.assignmentGroups[301].final.score, 42)
    equal(grades.assignmentGroups[301].current.possible, 91)
    equal(grades.assignmentGroups[301].final.possible, 91)
  })

  test('includes assignments that are anonymizing students in total calculations when' +
    '"grade calc ignore unposted anonymous" flag is disabled', () => {
    assignments[0].anonymize_students = true
    const grades = calculateWithoutGradingPeriods('points', false)
    equal(grades.assignmentGroups[301].current.score, 142)
    equal(grades.assignmentGroups[301].final.score, 142)
    equal(grades.assignmentGroups[301].current.possible, 191)
    equal(grades.assignmentGroups[301].final.possible, 191)
    equal(grades.assignmentGroups[302].current.score, 17)
    equal(grades.assignmentGroups[302].final.score, 17)
    equal(grades.assignmentGroups[302].current.possible, 93)
    equal(grades.assignmentGroups[302].final.possible, 1093)
  })

  test('includes all assignment group grades regardless of weight', () => {
    assignmentGroups[0].group_weight = 200
    assignmentGroups[1].group_weight = null
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.assignmentGroups[301].current.score, 142)
    equal(grades.assignmentGroups[301].final.score, 142)
    equal(grades.assignmentGroups[301].current.possible, 191)
    equal(grades.assignmentGroups[301].final.possible, 191)
    equal(grades.assignmentGroups[302].current.score, 17)
    equal(grades.assignmentGroups[302].final.score, 17)
    equal(grades.assignmentGroups[302].current.possible, 93)
    equal(grades.assignmentGroups[302].final.possible, 1093)
  })

  test('adds all scores for current and final grades when weighting scheme is points', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.current.score, 159, 'current score is sum of all graded submission scores')
    equal(grades.final.score, 159, 'final score is sum of all graded submission scores')
  })

  test('excludes ungraded assignments for the current grade when weighting scheme is points', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.current.possible, 284, 'current possible excludes points for ungraded assignments')
    equal(grades.final.possible, 1284, 'final possible includes points for ungraded assignments')
  })

  test('sets current and final scores as percentages when weighting scheme is percent', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(
      grades.current.score,
      46.31,
      'current score is weighted using points from graded assignments',
    )
    equal(grades.final.score, 37.95, 'final score is weighted using points from all assignments')
  })

  test('excludes ungraded assignments for the current grade when weighting scheme is percent', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('up-scales group weights which do not add up to exactly 100 percent', () => {
    // 5 / (5+5) = 50%
    assignmentGroups[0].group_weight = 5
    assignmentGroups[1].group_weight = 5
    const grades = calculateWithoutGradingPeriods('percent')
    equal(
      grades.current.score,
      46.31,
      'current score is weighted using points from graded assignments',
    )
    equal(grades.final.score, 37.95, 'final score is weighted using points from all assignments')
  })

  test('does not down-scale group weights which add up to over 100 percent', () => {
    assignmentGroups[0].group_weight = 100
    assignmentGroups[1].group_weight = 100
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.current.score, 92.63, 'current score is effectively double the weight')
    equal(grades.final.score, 75.9, 'final score is effectively double the weight')
    equal(grades.current.possible, 100, 'current possible remains 100 percent')
    equal(grades.final.possible, 100, 'final possible remains 100 percent')
  })

  test('weights each assignment group score according to its group weight', () => {
    assignmentGroups[0].group_weight = 75
    assignmentGroups[1].group_weight = 25
    const grades = calculateWithoutGradingPeriods('percent')
    equal(
      grades.current.score,
      60.33,
      'current score is weighted using points from graded assignments',
    )
    equal(grades.final.score, 56.15, 'final score is weighted using points from all assignments')
  })

  test('rounds percent scores to two decimal places', () => {
    assignmentGroups[0].group_weight = 33.33
    const grades = calculateWithoutGradingPeriods('percent')
    equal(
      grades.current.score,
      40.7,
      'current score is weighted using points from graded assignments',
    )
    equal(grades.final.score, 30.67, 'final score is weighted using points from all assignments')
  })

  // This behavior was explicitly written into the grade calculator. While
  // possibly unintended, this test is here to ensure this behavior is protected
  // until a decision is made to change it.
  test('sets scores to null when assignment groups have no weight', () => {
    assignmentGroups[0].group_weight = null
    assignmentGroups[1].group_weight = null
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.current.score, null, 'assignment groups must have a defined group weight')
    equal(grades.final.score, null, 'assignment groups must have a defined group weight')
  })
})

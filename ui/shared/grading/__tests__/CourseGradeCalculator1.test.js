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

let submissions
let assignments
let assignmentGroups

function calculateWithoutGradingPeriods(weightingScheme, ignoreUnpostedAnonymous = true) {
  return CourseGradeCalculator.calculate(
    submissions,
    assignmentGroups,
    weightingScheme,
    ignoreUnpostedAnonymous,
  )
}

describe('CourseGradeCalculator.calculate with zero-point assignments', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 10},
      {assignment_id: 202, score: 5},
      {assignment_id: 203, score: 20},
      {assignment_id: 204, score: 0},
    ]
    assignments = [
      {id: 201, points_possible: 0, omit_from_final_grade: false},
      {id: 202, points_possible: 0, omit_from_final_grade: false},
      {id: 203, points_possible: 0, omit_from_final_grade: false},
      {id: 204, points_possible: 0, omit_from_final_grade: false},
    ]
    assignmentGroups = [
      {id: 301, rules: {}, group_weight: 50, assignments: assignments.slice(0, 2)},
      {id: 302, rules: {}, group_weight: 50, assignments: assignments.slice(2, 4)},
    ]
  })

  test('includes all assignment group grades regardless of points possible', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.assignmentGroups[301].current.score, 15)
    equal(grades.assignmentGroups[301].final.score, 15)
    equal(grades.assignmentGroups[301].current.possible, 0)
    equal(grades.assignmentGroups[301].final.possible, 0)
    equal(grades.assignmentGroups[302].current.score, 20)
    equal(grades.assignmentGroups[302].final.score, 20)
    equal(grades.assignmentGroups[302].current.possible, 0)
    equal(grades.assignmentGroups[302].final.possible, 0)
  })

  test('adds all scores for current and final grades when weighting scheme is points', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.current.score, 35, 'current score is sum of all submission scores')
    equal(grades.final.score, 35, 'final score is sum of all submission scores')
  })

  test('sets all possible to 0 when weighting scheme is points', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.current.possible, 0, 'current possible is sum of all assignment points')
    equal(grades.final.possible, 0, 'final possible is sum of all assignment points')
  })

  test('sets scores to null when weighting scheme is percent', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.current.score, null, 'current score cannot be calculated without points possible')
    equal(grades.final.score, null, 'final score cannot be calculated without points possible')
  })

  test('sets current possible to 0 when weighting scheme is percent', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.current.possible, 0, 'current possible is 0 when all assignment points total 0')
    equal(grades.final.possible, 100, 'percent possible is 100 when submissions are counted')
  })
})

describe('CourseGradeCalculator.calculate with only ungraded submissions', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: null},
      {assignment_id: 202, score: null},
      {assignment_id: 203, score: null},
    ]
    assignments = [
      {id: 201, points_possible: 5, omit_from_final_grade: false},
      {id: 202, points_possible: 10, omit_from_final_grade: false},
      {id: 203, points_possible: 20, omit_from_final_grade: false},
    ]
    assignmentGroups = [{id: 301, group_weight: 100, rules: {}, assignments}]
  })

  test('includes all assignment group grades regardless of submissions graded', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.assignmentGroups[301].current.score, 0)
    equal(grades.assignmentGroups[301].final.score, 0)
    equal(grades.assignmentGroups[301].current.possible, 0)
    equal(grades.assignmentGroups[301].final.possible, 35)
  })

  test('sets current score to 0 when weighting scheme is points', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.current.score, 0, 'current score is 0 points when all submissions are excluded')
    equal(
      grades.current.possible,
      0,
      'current possible is 0 when all assignment points are excluded',
    )
  })

  test('sets final score to 0 when weighting scheme is points', () => {
    const grades = calculateWithoutGradingPeriods('points')
    equal(grades.final.score, 0, 'final score is 0 points when all submissions are excluded')
    equal(grades.final.possible, 35, 'final possible is sum of all assignment points')
  })

  test('sets current score to null when weighting scheme is percent', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(
      grades.current.score,
      null,
      'current score cannot be calculated when all submissions are excluded',
    )
    equal(
      grades.current.possible,
      0,
      'current possible is 0 when all assignment points are excluded',
    )
  })

  test('sets final score to null when weighting scheme is percent', () => {
    const grades = calculateWithoutGradingPeriods('percent')
    equal(
      grades.final.score,
      0,
      'final score cannot be calculated when all submissions are excluded',
    )
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('sets scores to 0 when weighting scheme is percent and group weight is not defined', () => {
    assignmentGroups[0].group_weight = null
    const grades = calculateWithoutGradingPeriods('percent')
    equal(grades.current.score, null, 'current score cannot be calculated without group weight')
    equal(grades.final.score, null, 'final score cannot be calculated without group weight')
  })
})

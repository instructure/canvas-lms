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

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toBe(y)
const strictEqual = (x, y) => expect(x).toStrictEqual(y)

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

describe('CourseGradeCalculator.calculate with weighted grading periods', () => {
  beforeEach(() => {
    submissions = [
      {assignment_id: 201, score: 10},
      {assignment_id: 202, score: 5},
      {assignment_id: 203, score: 12},
      {assignment_id: 204, score: 16},
    ]
    assignments = [
      {id: 201, points_possible: 10, omit_from_final_grade: false},
      {id: 202, points_possible: 10, omit_from_final_grade: false},
      {id: 203, points_possible: 20, omit_from_final_grade: false},
      {id: 204, points_possible: 40, omit_from_final_grade: false},
    ]
    assignmentGroups = [
      {id: 301, group_weight: 60, rules: {}, assignments: assignments.slice(0, 2)},
      {id: 302, group_weight: 20, rules: {}, assignments: assignments.slice(2, 3)},
      {id: 303, group_weight: 20, rules: {}, assignments: assignments.slice(3, 4)},
    ]
    gradingPeriods = [
      {id: '701', weight: 50},
      {id: '702', weight: 50},
    ]
    gradingPeriodSet = {gradingPeriods, weighted: true}
    effectiveDueDates = {
      201: {grading_period_id: '701'},
      202: {grading_period_id: '701'},
      203: {grading_period_id: '702'},
      204: {grading_period_id: '702'},
    }
  })

  test('includes grading period attributes in gradingPeriods', () => {
    const grades = calculateWithGradingPeriods('percent')
    ok(grades.gradingPeriods)
    equal(grades.gradingPeriods[701].gradingPeriodId, '701')
    equal(grades.gradingPeriods[702].gradingPeriodId, '702')
    equal(grades.gradingPeriods[701].gradingPeriodWeight, 50)
    equal(grades.gradingPeriods[702].gradingPeriodWeight, 50)
  })

  test('includes assignment groups point scores in grading period grades', () => {
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.gradingPeriods[701].assignmentGroups[301].current.score, 15)
    equal(grades.gradingPeriods[701].assignmentGroups[301].final.score, 15)
    equal(grades.gradingPeriods[702].assignmentGroups[302].current.score, 12)
    equal(grades.gradingPeriods[702].assignmentGroups[302].final.score, 12)
    equal(grades.gradingPeriods[702].assignmentGroups[303].current.score, 16)
    equal(grades.gradingPeriods[702].assignmentGroups[303].final.score, 16)
  })

  test('calculates current and final percent grades within grading periods', () => {
    const grades = calculateWithGradingPeriods('percent')
    equal(
      grades.gradingPeriods[701].current.score,
      75,
      'one assignment group is in this grading period',
    )
    equal(
      grades.gradingPeriods[701].final.score,
      75,
      'one assignment group is in this grading period',
    )
    equal(grades.gradingPeriods[701].current.possible, 100, 'current possible is 100 percent')
    equal(grades.gradingPeriods[701].final.possible, 100, 'final possible is 100 percent')
    equal(
      grades.gradingPeriods[702].current.score,
      50,
      'two assignment groups are in this grading period',
    )
    equal(
      grades.gradingPeriods[702].final.score,
      50,
      'two assignment groups are in this grading period',
    )
    equal(grades.gradingPeriods[702].current.possible, 100, 'current possible is 100 percent')
    equal(grades.gradingPeriods[702].final.possible, 100, 'final possible is 100 percent')
  })

  test('does not weight assignment groups within grading periods when weighting scheme is not percent', () => {
    const grades = calculateWithGradingPeriods('points')
    equal(
      grades.gradingPeriods[701].current.score,
      15,
      'current score is sum of scores in grading period 701',
    )
    equal(
      grades.gradingPeriods[701].final.score,
      15,
      'final score is sum of scores in grading period 701',
    )
    equal(
      grades.gradingPeriods[701].current.possible,
      20,
      'current possible is sum of points in grading period 701',
    )
    equal(
      grades.gradingPeriods[701].final.possible,
      20,
      'final possible is sum of points in grading period 701',
    )
    equal(
      grades.gradingPeriods[702].current.score,
      28,
      'current score is sum of scores in grading period 702',
    )
    equal(
      grades.gradingPeriods[702].final.score,
      28,
      'final score is sum of scores in grading period 702',
    )
    equal(
      grades.gradingPeriods[702].current.possible,
      60,
      'current possible is sum of points in grading period 702',
    )
    equal(
      grades.gradingPeriods[702].final.possible,
      60,
      'final possible is sum of points in grading period 702',
    )
  })

  test('weights percent grades of assignment groups for the course grade', () => {
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 62.5, 'each assignment group is half the grade')
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.score, 62.5, 'each assignment group is half the grade')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('does not weight assignment groups for course grade when weighting scheme is not percent', () => {
    const grades = calculateWithGradingPeriods('points')
    equal(
      grades.current.score,
      60.83,
      'assignment group scores are totaled per grading period as points',
    )
    equal(
      grades.final.score,
      60.83,
      'assignment group scores are totaled per grading period as points',
    )
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('up-scales grading period weights which do not add up to exactly 100 percent', () => {
    // 5 / (5+5) = 50%
    gradingPeriods[0].weight = 5
    gradingPeriods[1].weight = 5
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 62.5)
    equal(grades.current.possible, 100)
    equal(grades.final.score, 62.5)
    equal(grades.final.possible, 100)
  })

  test('does not down-scale grading period weights which add up to over 100 percent', () => {
    gradingPeriods[0].weight = 100
    gradingPeriods[1].weight = 100
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 125, 'current score is effectively double the weight')
    equal(grades.current.possible, 100, 'current possible remains 100 percent')
    equal(grades.final.score, 125, 'final score is effectively double the weight')
    equal(grades.final.possible, 100, 'final possible remains 100 percent')
  })

  test('uses zero weight for grading periods with null weight', () => {
    // 5 / (0+5) = 100%
    gradingPeriods[0].weight = null
    gradingPeriods[1].weight = 5
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 50, 'grading period 702 has a current score of 50 percent')
    equal(grades.current.possible, 100)
    equal(grades.final.score, 50, 'grading period 702 has a final score of 50 percent')
    equal(grades.final.possible, 100)
  })

  test('sets scores to zero when all grading period weights are zero', () => {
    gradingPeriods[0].weight = 0
    gradingPeriods[1].weight = 0
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 0, 'all grading periods have zero weight')
    equal(grades.current.possible, 100, 'current possible remains 100 percent')
    equal(grades.final.score, 0, 'all grading periods have zero weight')
    equal(grades.final.possible, 100, 'final possible remains 100 percent')
  })

  test('sets scores to zero when all grading period weights are null', () => {
    gradingPeriods[0].weight = null
    gradingPeriods[1].weight = null
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 0, 'all grading periods have zero weight')
    equal(grades.current.possible, 100, 'current possible remains 100 percent')
    equal(grades.final.score, 0, 'all grading periods have zero weight')
    equal(grades.final.possible, 100, 'final possible remains 100 percent')
  })

  test('excludes assignments outside of grading periods', () => {
    effectiveDueDates[201].grading_period_id = null
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 50, 'assignment 201 is excluded')
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.score, 50, 'assignment 201 is excluded')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('excludes assignments outside of grading periods for assignment group grades', () => {
    effectiveDueDates[201].grading_period_id = null
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.assignmentGroups[301].current.score, 5)
    equal(grades.assignmentGroups[301].final.score, 5)
    equal(grades.assignmentGroups[301].current.possible, 10)
    equal(grades.assignmentGroups[301].final.possible, 10)
  })

  test('excludes grades for assignment groups outside of grading periods', () => {
    effectiveDueDates[203].grading_period_id = null
    const grades = calculateWithGradingPeriods('percent')
    equal(typeof grades.assignmentGroups[302], 'undefined')
  })

  test('weights grading periods with unequal grading period weights', () => {
    gradingPeriods[0].weight = 25
    gradingPeriods[1].weight = 75
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 56.25)
    equal(grades.final.score, 56.25)
  })

  test('current score excludes grading periods with no assignments groups', () => {
    assignmentGroups = [assignmentGroups[0]]
    const grades = calculateWithGradingPeriods('percent')
    equal(
      grades.current.score,
      75.0,
      'the grading period with a score is weighted as 100% of the overall score',
    )
    equal(grades.current.possible, 100)
  })

  test('final score includes grading periods with no assignments groups', () => {
    assignmentGroups = [assignmentGroups[0]]
    const grades = calculateWithGradingPeriods('percent')
    equal(
      grades.final.score,
      37.5,
      'the grading period with a score is weighted as 50% of the overall score',
    )
    equal(grades.final.possible, 100)
  })

  // Empty assignment groups are not associated with any grading period.
  test('ignores empty assignments groups', () => {
    assignmentGroups[1].assignments = []
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 57.5)
    equal(grades.final.score, 57.5)
  })

  test('evaluates null grading period weights as 0 when some grading periods have weight', () => {
    gradingPeriods[0].weight = null
    gradingPeriods[1].weight = 50
    const grades = calculateWithGradingPeriods('percent')
    equal(
      grades.current.score,
      50,
      'grading period 702 score of 50 effectively has 100 percent weight',
    )
    equal(grades.current.possible, 100, 'current possible remains 100 percent')
    equal(
      grades.final.score,
      50,
      'grading period 702 score of 50 effectively has 100 percent weight',
    )
    equal(grades.final.possible, 100, 'final possible remains 100 percent')
  })

  test('evaluates null grading period weights as 0 when no grading periods have weight', () => {
    gradingPeriods[0].weight = null
    gradingPeriods[1].weight = null
    const grades = calculateWithGradingPeriods('percent')
    equal(
      grades.current.score,
      0,
      'grading period 702 score of 50 effectively has 0 percent weight',
    )
    equal(grades.current.possible, 100, 'current possible remains 100 percent')
    equal(grades.final.score, 0, 'grading period 702 score of 50 effectively has 0 percent weight')
    equal(grades.final.possible, 100, 'final possible remains 100 percent')
  })

  test('sets null weights as 0 in gradingPeriods', () => {
    gradingPeriods[0].weight = null
    gradingPeriods[1].weight = null
    const grades = calculateWithGradingPeriods('percent')
    ok(grades.gradingPeriods)
    equal(grades.gradingPeriods[701].gradingPeriodWeight, 0)
    equal(grades.gradingPeriods[702].gradingPeriodWeight, 0)
  })

  test('combines weighted assignment group scores as percent in grading periods without weight', () => {
    gradingPeriods[0].weight = null
    gradingPeriods[1].weight = null
    const grades = calculateWithGradingPeriods('percent')
    equal(
      grades.gradingPeriods[701].current.score,
      75,
      'one assignment group is in grading period 701',
    )
    equal(grades.gradingPeriods[701].current.possible, 100, 'current possible is 100 percent')
    equal(
      grades.gradingPeriods[701].final.score,
      75,
      'one assignment group is in grading period 701',
    )
    equal(grades.gradingPeriods[701].final.possible, 100, 'final possible is 100 percent')
    equal(
      grades.gradingPeriods[702].current.score,
      50,
      'two assignment groups are in grading period 702',
    )
    equal(grades.gradingPeriods[702].current.possible, 100, 'current possible is 100 percent')
    equal(
      grades.gradingPeriods[702].final.score,
      50,
      'two assignment groups are in grading period 702',
    )
    equal(grades.gradingPeriods[702].final.possible, 100, 'final possible is 100 percent')
  })

  test('includes assignment group grades regardless of grading period weight', () => {
    gradingPeriods[0].weight = 200
    gradingPeriods[1].weight = null
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.assignmentGroups[301].current.score, 15)
    equal(grades.assignmentGroups[301].final.score, 15)
    equal(grades.assignmentGroups[301].current.possible, 20)
    equal(grades.assignmentGroups[301].final.possible, 20)
    equal(grades.assignmentGroups[302].current.score, 12)
    equal(grades.assignmentGroups[302].final.score, 12)
    equal(grades.assignmentGroups[302].current.possible, 20)
    equal(grades.assignmentGroups[302].final.possible, 20)
    equal(grades.assignmentGroups[303].current.score, 16)
    equal(grades.assignmentGroups[303].final.score, 16)
    equal(grades.assignmentGroups[303].current.possible, 40)
    equal(grades.assignmentGroups[303].final.possible, 40)
  })

  test('uses a score unit of "percentage" for course grade', () => {
    let grades = calculateWithGradingPeriods('points')
    equal(grades.scoreUnit, 'percentage')
    grades = calculateWithGradingPeriods('percent')
    equal(grades.scoreUnit, 'percentage')
  })

  test('uses a score unit of "points" for grading period grades when weighting scheme is not percent', () => {
    const grades = calculateWithGradingPeriods('points')
    equal(grades.gradingPeriods[701].scoreUnit, 'points')
    equal(grades.gradingPeriods[702].scoreUnit, 'points')
  })

  test('uses a score unit of "percentage" for grading period grades when weighting scheme is percent', () => {
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.gradingPeriods[701].scoreUnit, 'percentage')
    equal(grades.gradingPeriods[702].scoreUnit, 'percentage')
  })

  test('avoids floating point errors in current and final score', () => {
    submissions = [
      {assignment_id: 201, score: 45.9},
      {assignment_id: 202, score: 38.25},
    ]
    assignments = [
      {id: 201, points_possible: 60},
      {id: 202, points_possible: 40},
    ]
    assignmentGroups = [
      {id: 301, group_weight: 50, rules: {}, assignments: assignments.slice(0, 1)},
      {id: 302, group_weight: 50, rules: {}, assignments: assignments.slice(1, 2)},
    ]
    effectiveDueDates = {
      201: {grading_period_id: '701'},
      202: {grading_period_id: '702'},
    }
    gradingPeriods = [
      {id: '701', weight: 40},
      {id: '702', weight: 50},
    ]
    gradingPeriodSet = {gradingPeriods, weighted: true}

    //   45.9  / 60 * 0.4 (weight)
    // + 38.25 / 40 * 0.5 (weight)
    // = 0.7841250000000001 (weighted sum, expected 0.784125)
    //
    // weighted sum * 100 / 90 (scaling up for grading period weights)
    // = 87.12499999999999 (expected 87.125, rounded)
    const grades = calculateWithGradingPeriods('points')
    strictEqual(grades.current.score, 87.13)
    strictEqual(grades.final.score, 87.13)
  })
})

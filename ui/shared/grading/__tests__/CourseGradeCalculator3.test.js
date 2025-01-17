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

describe('CourseGradeCalculator.calculate with unweighted grading periods', () => {
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
    gradingPeriodSet = {gradingPeriods, weighted: false}
    effectiveDueDates = {
      201: {grading_period_id: '701'},
      202: {grading_period_id: '701'},
      203: {grading_period_id: '702'},
      204: {grading_period_id: '702'},
    }
  })

  test('includes assignment group grades', () => {
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

  test('includes grading period weights in gradingPeriods', () => {
    const grades = calculateWithGradingPeriods('percent')
    ok(grades.gradingPeriods)
    equal(grades.gradingPeriods[701].gradingPeriodWeight, 50)
    equal(grades.gradingPeriods[702].gradingPeriodWeight, 50)
  })

  test('excludes assignments that are anonymizing students in total calculations', () => {
    assignments[0].anonymize_students = true
    const ignoreUnpostedAnonymous = true
    const grades = calculateWithGradingPeriods('percent', ignoreUnpostedAnonymous)
    equal(grades.assignmentGroups[301].current.score, 5)
    equal(grades.assignmentGroups[301].final.score, 5)
    equal(grades.assignmentGroups[301].current.possible, 10)
    equal(grades.assignmentGroups[301].final.possible, 10)
  })

  test('includes assignments that are anonymizing students when the feature flag is disabled', () => {
    assignments[0].anonymize_students = true
    const ignoreUnpostedAnonymous = false
    const grades = calculateWithGradingPeriods('percent', ignoreUnpostedAnonymous)
    equal(grades.assignmentGroups[301].current.score, 15)
    equal(grades.assignmentGroups[301].final.score, 15)
    equal(grades.assignmentGroups[301].current.possible, 20)
    equal(grades.assignmentGroups[301].final.possible, 20)
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

  test('combines all assignment groups for the course grade', () => {
    // 15/20 * 60% = 45%
    // 12/20 * 20% = 12%
    // 16/40 * 20% = 8%
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 65, 'each assignment group is weighted only by its group_weight')
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.score, 65, 'each assignment group is weighted only by its group_weight')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('ignores grading period weights', () => {
    // 15/20 * 60% = 45%
    // 12/20 * 20% = 12%
    // 16/40 * 20% = 8%
    gradingPeriods[0].weight = 25
    gradingPeriods[1].weight = 75
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 65, 'each assignment group is weighted only by its group_weight')
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.score, 65, 'each assignment group is weighted only by its group_weight')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('does not weight assignment groups for course grade when weighting scheme is not percent', () => {
    const grades = calculateWithGradingPeriods('points')
    equal(
      grades.current.score,
      43,
      'assignment group scores are totaled per grading period as points',
    )
    equal(grades.current.possible, 80, 'current possible is sum of all assignment points')
    equal(
      grades.final.score,
      43,
      'assignment group scores are totaled per grading period as points',
    )
    equal(grades.final.possible, 80, 'final possible is sum of all assignment points')
  })

  test('up-scales group weights which do not add up to exactly 100 percent', () => {
    // 6 / (6+2+2) = 60%
    // 2 / (6+2+2) = 20%
    assignmentGroups[0].group_weight = 6
    assignmentGroups[1].group_weight = 2
    assignmentGroups[2].group_weight = 2
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 65, 'each assignment group is weighted only by its group_weight')
    equal(grades.final.score, 65, 'each assignment group is weighted only by its group_weight')
  })

  test('does not down-scale group weights which add up to over 100 percent', () => {
    assignmentGroups[0].group_weight = 120
    assignmentGroups[1].group_weight = 40
    assignmentGroups[2].group_weight = 40
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 130, 'current score is effectively double the weight')
    equal(grades.final.score, 130, 'final score is effectively double the weight')
    equal(grades.current.possible, 100, 'current possible remains 100 percent')
    equal(grades.final.possible, 100, 'final possible remains 100 percent')
  })

  test('includes assignment groups outside of grading periods', () => {
    effectiveDueDates[201].grading_period_id = null
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 65, 'assignment 201 is included')
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.score, 65, 'assignment 201 is included')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('does not divide assignment groups crossing grading periods', () => {
    effectiveDueDates[202].grading_period_id = '702'
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.current.score, 65, 'assignment group 302 is not divided')
    equal(grades.current.possible, 100, 'current possible is 100 percent')
    equal(grades.final.score, 65, 'assignment group 302 is not divided')
    equal(grades.final.possible, 100, 'final possible is 100 percent')
  })

  test('includes assignment group grades without division', () => {
    effectiveDueDates[202].grading_period_id = '702'
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

  test('uses a score unit of "points" when weighting scheme is not percent', () => {
    const grades = calculateWithGradingPeriods('points')
    equal(grades.scoreUnit, 'points')
    equal(grades.gradingPeriods[701].scoreUnit, 'points')
    equal(grades.gradingPeriods[702].scoreUnit, 'points')
  })

  test('uses a score unit of "percentage" when weighting scheme is percent', () => {
    const grades = calculateWithGradingPeriods('percent')
    equal(grades.scoreUnit, 'percentage')
    equal(grades.gradingPeriods[701].scoreUnit, 'percentage')
    equal(grades.gradingPeriods[702].scoreUnit, 'percentage')
  })
})

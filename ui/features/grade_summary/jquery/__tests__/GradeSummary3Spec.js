/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import $ from 'jquery'
import 'jquery-migrate'
import {useScope as createI18nScope} from '@canvas/i18n'
import fakeENV from '@canvas/test-utils/fakeENV'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import GradeSummary from '../index'
import {createCourseGradesWithGradingPeriods} from '@canvas/grading/GradeCalculatorSpecHelper'

const I18n = createI18nScope('gradingGradeSummary')

const $fixtures = $('#fixtures')

let exampleGrades

function createAssignmentGroups() {
  return [
    {
      id: '301',
      assignments: [
        {id: '201', muted: false, points_possible: 20},
        {id: '202', muted: true, points_possible: 20},
      ],
    },
    {id: '302', assignments: [{id: '203', muted: true, points_possible: 20}]},
  ]
}

function createSubmissions() {
  return [{assignment_id: '201', score: 10}]
}

function createSubtotalsByAssignmentGroup() {
  ENV.assignment_groups = [{id: 1}, {id: 2}]
  ENV.grading_periods = []
  const calculatedGrades = {
    assignmentGroups: {
      1: {current: {score: 6, possible: 10}},
      2: {current: {score: 7, possible: 10}},
    },
  }
  const byGradingPeriod = false
  return GradeSummary.calculateSubtotals(byGradingPeriod, calculatedGrades, 'current')
}

function createSubtotalsByGradingPeriod() {
  ENV.assignment_groups = []
  ENV.grading_periods = [{id: 1}, {id: 2}]
  const calculatedGrades = {
    gradingPeriods: {
      1: {final: {score: 8, possible: 10}},
      2: {final: {score: 9, possible: 10}},
    },
  }
  const byGradingPeriod = true
  return GradeSummary.calculateSubtotals(byGradingPeriod, calculatedGrades, 'final')
}

function commonSetup() {
  fakeENV.setup({grade_calc_ignore_unposted_anonymous_enabled: true})
  $fixtures.html('')
}

function commonTeardown() {
  fakeENV.teardown()
  $fixtures.html('')
}

QUnit.module('GradeSummary.calculateSubtotalsByGradingPeriod', {
  setup() {
    this.subtotals = createSubtotalsByGradingPeriod()
  },
})

test('calculates subtotals by grading period', function () {
  equal(this.subtotals.length, 2, 'calculates a subtotal for each period')
})

test('creates teaser text for subtotals by grading period', function () {
  equal(this.subtotals[0].teaserText, '8.00 / 10.00', 'builds teaser text for first period')
  equal(this.subtotals[1].teaserText, '9.00 / 10.00', 'builds teaser text for second period')
})

test('creates grade text for subtotals by grading period', function () {
  equal(this.subtotals[0].gradeText, '80%', 'builds grade text for first period')
  equal(this.subtotals[1].gradeText, '90%', 'builds grade text for second period')
})

test('assigns row element ids for subtotals by grading period', function () {
  equal(
    this.subtotals[0].rowElementId,
    '#submission_period-1',
    'builds row element id for first period'
  )
  equal(
    this.subtotals[1].rowElementId,
    '#submission_period-2',
    'builds row element id for second period'
  )
})

QUnit.module('GradeSummary.calculateSubtotalsByAssignmentGroup', {
  setup() {
    this.subtotals = createSubtotalsByAssignmentGroup()
  },
})

test('calculates subtotals by assignment group', function () {
  equal(this.subtotals.length, 2, 'calculates a subtotal for each group')
})

test('calculates teaser text for subtotals by assignment group', function () {
  equal(this.subtotals[0].teaserText, '6.00 / 10.00', 'builds teaser text for first group')
  equal(this.subtotals[1].teaserText, '7.00 / 10.00', 'builds teaser text for second group')
})

test('calculates grade text for subtotals by assignment group', function () {
  equal(this.subtotals[0].gradeText, '60%', 'builds grade text for first group')
  equal(this.subtotals[1].gradeText, '70%', 'builds grade text for second group')
})

test('calculates row element ids for subtotals by assignment group', function () {
  equal(
    this.subtotals[0].rowElementId,
    '#submission_group-1',
    'builds row element id for first group'
  )
  equal(
    this.subtotals[1].rowElementId,
    '#submission_group-2',
    'builds row element id for second group'
  )
})

QUnit.module('GradeSummary.canBeConvertedToGrade')

test('returns false when possible is nonpositive', () => {
  notOk(GradeSummary.canBeConvertedToGrade(1, 0))
})

test('returns false when score is NaN', () => {
  notOk(GradeSummary.canBeConvertedToGrade(NaN, 1))
})

test('returns true when score is a number and possible is positive', () => {
  ok(GradeSummary.canBeConvertedToGrade(1, 1))
})

QUnit.module('GradeSummary.calculatePercentGrade')

test('returns properly computed and rounded value', () => {
  const percentGrade = GradeSummary.calculatePercentGrade(1, 3)
  strictEqual(percentGrade, 33.33)
})

test('avoids floating point calculation issues', () => {
  const percentGrade = GradeSummary.calculatePercentGrade(946.65, 1000)
  strictEqual(percentGrade, 94.67)
})

QUnit.module('GradeSummary.formatPercentGrade')

test('returns an internationalized number value', () => {
  sandbox.stub(I18n.constructor.prototype, 'n').withArgs(1234).returns('1,234%')
  equal(GradeSummary.formatPercentGrade(1234), '1,234%')
})

QUnit.module('GradeSummary.calculateGrade')

test('returns an internationalized percentage when given a score and nonzero points possible', () => {
  sandbox.stub(I18n.constructor.prototype, 'n').callsFake(number => `${number}%`)
  equal(GradeSummary.calculateGrade(97, 100), '97%')
  equal(I18n.n.getCall(0).args[1].percentage, true)
})

test('returns "N/A" when given a numerical score and zero points possible', () => {
  equal(GradeSummary.calculateGrade(1, 0), 'N/A')
})

test('returns "N/A" when given a non-numerical score and nonzero points possible', () => {
  equal(GradeSummary.calculateGrade(undefined, 1), 'N/A')
})

QUnit.module('GradeSummary.calculateGrades', {
  setup() {
    commonSetup()
    ENV.submissions = createSubmissions()
    ENV.assignment_groups = createAssignmentGroups()
    ENV.group_weighting_scheme = 'points'
    ENV.grading_period_set = {
      id: '1501',
      grading_periods: [
        {id: '701', weight: 50},
        {id: '702', weight: 50},
      ],
      weighted: true,
    }
    ENV.effective_due_dates = {201: {101: {grading_period_id: '701'}}}
    ENV.student_id = '101'
    exampleGrades = createCourseGradesWithGradingPeriods()
    sandbox.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
  },

  teardown() {
    commonTeardown()
  },
})

test('calculates grades using data in the env', () => {
  GradeSummary.calculateGrades()
  const args = CourseGradeCalculator.calculate.getCall(0).args
  equal(args[0], ENV.submissions)
  deepEqual(_.map(args[1], 'id'), ['301', '302'])
  equal(args[2], ENV.group_weighting_scheme)
})

test('normalizes the grading period set before calculation', () => {
  GradeSummary.calculateGrades()
  const gradingPeriodSet = CourseGradeCalculator.calculate.getCall(0).args[4]
  deepEqual(gradingPeriodSet.id, '1501')
  equal(gradingPeriodSet.gradingPeriods.length, 2)
  deepEqual(_.map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702'])
})

test('scopes effective due dates to the user', () => {
  GradeSummary.calculateGrades()
  const dueDates = CourseGradeCalculator.calculate.getCall(0).args[5]
  deepEqual(dueDates, {201: {grading_period_id: '701'}})
})

test('calculates grades without grading period data when the grading period set is not defined', () => {
  delete ENV.grading_period_set
  GradeSummary.calculateGrades()
  const args = CourseGradeCalculator.calculate.getCall(0).args
  equal(args[0], ENV.submissions)
  equal(args[1], ENV.assignment_groups)
  equal(args[2], ENV.group_weighting_scheme)
  equal(typeof args[4], 'undefined')
  equal(typeof args[5], 'undefined')
})

test('calculates grades without grading period data when effective due dates are not defined', () => {
  delete ENV.effective_due_dates
  GradeSummary.calculateGrades()
  const args = CourseGradeCalculator.calculate.getCall(0).args
  equal(args[0], ENV.submissions)
  equal(args[1], ENV.assignment_groups)
  equal(args[2], ENV.group_weighting_scheme)
  equal(typeof args[4], 'undefined')
  equal(typeof args[5], 'undefined')
})

test('returns course grades when no grading period id is provided', () => {
  sandbox.stub(GradeSummary, 'getSelectedGradingPeriodId').returns(null)
  const grades = GradeSummary.calculateGrades()
  equal(grades, exampleGrades)
})

test('scopes grades to the provided grading period id', () => {
  sandbox.stub(GradeSummary, 'getSelectedGradingPeriodId').returns('701')
  const grades = GradeSummary.calculateGrades()
  equal(grades, exampleGrades.gradingPeriods[701])
})

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
import 'jquery-migrate'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import {useScope as createI18nScope} from '@canvas/i18n'
import fakeENV from '@canvas/test-utils/fakeENV'
import GradeSummary from '../index'

const I18n = createI18nScope('gradingGradeSummary')

describe('GradeSummary', () => {
  let $fixtures

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

  beforeEach(() => {
    $fixtures = document.createElement('div')
    $fixtures.id = 'fixtures'
    document.body.appendChild($fixtures)
    fakeENV.setup({grade_calc_ignore_unposted_anonymous_enabled: true})
  })

  afterEach(() => {
    fakeENV.teardown()
    $fixtures.remove()
  })

  describe('calculateSubtotalsByGradingPeriod', () => {
    let subtotals

    beforeEach(() => {
      subtotals = createSubtotalsByGradingPeriod()
    })

    it('calculates subtotals by grading period', () => {
      expect(subtotals).toHaveLength(2)
    })

    it('creates teaser text for subtotals by grading period', () => {
      expect(subtotals[0].teaserText).toBe('8.00 / 10.00')
      expect(subtotals[1].teaserText).toBe('9.00 / 10.00')
    })

    it('creates grade text for subtotals by grading period', () => {
      expect(subtotals[0].gradeText).toBe('80%')
      expect(subtotals[1].gradeText).toBe('90%')
    })

    it('assigns row element ids for subtotals by grading period', () => {
      expect(subtotals[0].rowElementId).toBe('#submission_period-1')
      expect(subtotals[1].rowElementId).toBe('#submission_period-2')
    })
  })

  describe('calculateSubtotalsByAssignmentGroup', () => {
    let subtotals

    beforeEach(() => {
      subtotals = createSubtotalsByAssignmentGroup()
    })

    it('calculates subtotals by assignment group', () => {
      expect(subtotals).toHaveLength(2)
    })

    it('calculates teaser text for subtotals by assignment group', () => {
      expect(subtotals[0].teaserText).toBe('6.00 / 10.00')
      expect(subtotals[1].teaserText).toBe('7.00 / 10.00')
    })

    it('calculates grade text for subtotals by assignment group', () => {
      expect(subtotals[0].gradeText).toBe('60%')
      expect(subtotals[1].gradeText).toBe('70%')
    })

    it('calculates row element ids for subtotals by assignment group', () => {
      expect(subtotals[0].rowElementId).toBe('#submission_group-1')
      expect(subtotals[1].rowElementId).toBe('#submission_group-2')
    })
  })

  describe('canBeConvertedToGrade', () => {
    it('returns false when possible is nonpositive', () => {
      expect(GradeSummary.canBeConvertedToGrade(1, 0)).toBeFalsy()
    })

    it('returns false when score is NaN', () => {
      expect(GradeSummary.canBeConvertedToGrade(NaN, 1)).toBeFalsy()
    })

    it('returns true when score is a number and possible is positive', () => {
      expect(GradeSummary.canBeConvertedToGrade(1, 1)).toBeTruthy()
    })
  })

  describe('calculatePercentGrade', () => {
    it('returns properly computed and rounded value', () => {
      const percentGrade = GradeSummary.calculatePercentGrade(1, 3)
      expect(percentGrade).toBe(33.33)
    })

    it('avoids floating point calculation issues', () => {
      const percentGrade = GradeSummary.calculatePercentGrade(946.65, 1000)
      expect(percentGrade).toBe(94.67)
    })
  })

  describe('formatPercentGrade', () => {
    it('returns an internationalized number value', () => {
      jest.spyOn(I18n.constructor.prototype, 'n').mockReturnValue('1,234%')
      expect(GradeSummary.formatPercentGrade(1234)).toBe('1,234%')
    })
  })

  describe('calculateGrade', () => {
    it('returns an internationalized percentage when given a score and nonzero points possible', () => {
      jest.spyOn(I18n.constructor.prototype, 'n').mockImplementation(number => `${number}%`)
      expect(GradeSummary.calculateGrade(97, 100)).toBe('97%')
      expect(I18n.n.mock.calls[0][1].percentage).toBeTruthy()
    })

    it('returns "N/A" when given a numerical score and zero points possible', () => {
      expect(GradeSummary.calculateGrade(1, 0)).toBe('N/A')
    })

    it('returns "N/A" when given a non-numerical score and nonzero points possible', () => {
      expect(GradeSummary.calculateGrade(undefined, 1)).toBe('N/A')
    })
  })

  describe('calculateGrades', () => {
    it('calculates grades using data in the env', () => {
      jest.spyOn(CourseGradeCalculator, 'calculate')
      GradeSummary.calculateGrades()
      const args = CourseGradeCalculator.calculate.mock.calls[0]
      expect(args[0]).toEqual(ENV.submissions)
      expect(args[1]).toEqual(ENV.assignment_groups)
      expect(args[2]).toEqual(ENV.group_weighting_scheme)
      expect(args[3]).toEqual(ENV.grade_calc_ignore_unposted_anonymous_enabled)
    })
  })
})

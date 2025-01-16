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

import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import GradeSummary from '../index'

describe('GradeSummary', () => {
  let $fixtures

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

  describe('getGradingPeriodSet', () => {
    it('normalizes the grading period set from the env', () => {
      ENV.grading_period_set = {
        id: '1501',
        grading_periods: [
          {id: '701', weight: 50},
          {id: '702', weight: 50},
        ],
        weighted: true,
      }
      const gradingPeriodSet = GradeSummary.getGradingPeriodSet()
      expect(gradingPeriodSet.id).toBe('1501')
      expect(gradingPeriodSet.gradingPeriods).toHaveLength(2)
      expect(gradingPeriodSet.gradingPeriods.map(period => period.id)).toEqual(['701', '702'])
    })

    it('returns null when the grading period set is not defined in the env', () => {
      ENV.grading_period_set = undefined
      const gradingPeriodSet = GradeSummary.getGradingPeriodSet()
      expect(gradingPeriodSet).toBeNull()
    })
  })

  describe('parseScoreText', () => {
    it('sets "numericalValue" to the parsed value', () => {
      const score = GradeSummary.parseScoreText('1,234')
      expect(score.numericalValue).toBe(1234)
    })

    it('sets "formattedValue" to the formatted value', () => {
      const score = GradeSummary.parseScoreText('1234')
      expect(score.formattedValue).toBe('1,234')
    })

    it('sets "numericalValue" to null when given an empty string', () => {
      const score = GradeSummary.parseScoreText('')
      expect(score.numericalValue).toBeNull()
    })

    it('sets "numericalValue" to null when given null', () => {
      const score = GradeSummary.parseScoreText(null)
      expect(score.numericalValue).toBeNull()
    })

    it('sets "numericalValue" to null when given undefined', () => {
      const score = GradeSummary.parseScoreText(undefined)
      expect(score.numericalValue).toBeNull()
    })

    it('sets "numericalValue" to the "numericalDefault" when "numericalDefault" is a number', () => {
      const score = GradeSummary.parseScoreText(undefined, 5)
      expect(score.numericalValue).toBe(5)
    })

    it('sets "numericalValue" to null when "numericalDefault" is a string', () => {
      const score = GradeSummary.parseScoreText(undefined, '5')
      expect(score.numericalValue).toBeNull()
    })

    it('sets "numericalValue" to null when "numericalDefault" is null', () => {
      const score = GradeSummary.parseScoreText(undefined, null)
      expect(score.numericalValue).toBeNull()
    })

    it('sets "numericalValue" to null when "numericalDefault" is undefined', () => {
      const score = GradeSummary.parseScoreText(undefined, undefined)
      expect(score.numericalValue).toBeNull()
    })

    it('sets "formattedValue" to "-" when given an empty string', () => {
      const score = GradeSummary.parseScoreText('')
      expect(score.formattedValue).toBe('-')
    })

    it('sets "formattedValue" to "-" when given null', () => {
      const score = GradeSummary.parseScoreText(null)
      expect(score.formattedValue).toBe('-')
    })

    it('sets "formattedValue" to "-" when given undefined', () => {
      const score = GradeSummary.parseScoreText(undefined)
      expect(score.formattedValue).toBe('-')
    })

    it('sets "formattedValue" to the "formattedDefault" when "formattedDefault" is a string', () => {
      const score = GradeSummary.parseScoreText(undefined, null, 'default')
      expect(score.formattedValue).toBe('default')
    })

    it('sets "formattedValue" to "-" when "formattedDefault" is a number', () => {
      const score = GradeSummary.parseScoreText(undefined, null, 5)
      expect(score.formattedValue).toBe('-')
    })

    it('sets "formattedValue" to "-" when "formattedDefault" is null', () => {
      const score = GradeSummary.parseScoreText(undefined, null, null)
      expect(score.formattedValue).toBe('-')
    })

    it('sets "formattedValue" to "-" when "formattedDefault" is undefined', () => {
      const score = GradeSummary.parseScoreText(undefined, null, undefined)
      expect(score.formattedValue).toBe('-')
    })
  })
})

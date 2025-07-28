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

import {useScope as createI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import GradeFormatHelper from '../GradeFormatHelper'

const I18n = createI18nScope('sharedGradeFormatHelper')

describe('GradeFormatHelper', () => {
  const translateString = I18n.t

  beforeEach(() => {
    jest.resetModules()
    jest.clearAllMocks()
    jest.spyOn(numberHelper, 'validate').mockImplementation(val => !Number.isNaN(parseFloat(val)))
    jest.spyOn(I18n.constructor.prototype, 't').mockImplementation(translateString)
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
  })

  describe('.isExcused', () => {
    const testCases = [
      {input: 'EX', expected: true, desc: 'returns true when given "EX"'},
      {input: '7', expected: false, desc: 'returns false when given point values'},
      {input: '7%', expected: false, desc: 'returns false when given percentage values'},
      {input: 'A', expected: false, desc: 'returns false when given letter grades'},
    ]

    testCases.forEach(({input, expected, desc}) => {
      it(desc, () => {
        expect(GradeFormatHelper.isExcused(input)).toBe(expected)
      })
    })
  })

  describe('.formatPointsOutOf()', () => {
    it('returns the score and points possible as a fraction', () => {
      expect(GradeFormatHelper.formatPointsOutOf('7', '10')).toBe('7/10')
    })

    it('rounds the score and points possible to two decimal places', () => {
      expect(GradeFormatHelper.formatPointsOutOf('7.123', '10.456')).toBe('7.12/10.46')
    })

    it('returns null when grade is null', () => {
      expect(GradeFormatHelper.formatPointsOutOf(null, '10')).toBeNull()
    })

    it('returns grade if pointsPossible is null', () => {
      expect(GradeFormatHelper.formatPointsOutOf('7', null)).toBe('7')
    })
  })

  describe('.formatGradeInfo()', () => {
    it('returns the grade when the pending grade is valid', () => {
      const gradeInfo = {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: true}
      expect(GradeFormatHelper.formatGradeInfo(gradeInfo)).toBe('A')
    })

    it('returns the grade when the pending grade is invalid', () => {
      const gradeInfo = {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: false}
      expect(GradeFormatHelper.formatGradeInfo(gradeInfo)).toBe('A')
    })

    it('returns "–" (en dash) when the pending grade is null', () => {
      const gradeInfo = {enteredAs: null, excused: false, grade: null, score: null, valid: true}
      expect(GradeFormatHelper.formatGradeInfo(gradeInfo)).toBe('–')
    })

    it('returns the given default value when the pending grade is null', () => {
      const gradeInfo = {enteredAs: null, excused: false, grade: null, score: null, valid: true}
      const options = {defaultValue: 'default'}
      expect(GradeFormatHelper.formatGradeInfo(gradeInfo, options)).toBe('default')
    })

    it('returns "Excused" when the pending grade info includes excused', () => {
      const gradeInfo = {enteredAs: 'excused', excused: true, grade: null, score: null, valid: true}
      expect(GradeFormatHelper.formatGradeInfo(gradeInfo)).toBe('Excused')
    })
  })
})

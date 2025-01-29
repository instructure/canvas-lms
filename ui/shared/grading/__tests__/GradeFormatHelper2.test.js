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
    jest.spyOn(numberHelper, 'validate').mockImplementation(val => !Number.isNaN(parseFloat(val)))
    jest.spyOn(I18n.constructor.prototype, 't').mockImplementation(translateString)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('.isExcused', () => {
    it('returns true when given "EX"', () => {
      expect(GradeFormatHelper.isExcused('EX')).toBe(true)
    })

    it('returns false when given point values', () => {
      expect(GradeFormatHelper.isExcused('7')).toBe(false)
    })

    it('returns false when given percentage values', () => {
      expect(GradeFormatHelper.isExcused('7%')).toBe(false)
    })

    it('returns false when given letter grades', () => {
      expect(GradeFormatHelper.isExcused('A')).toBe(false)
    })
  })

  describe('.formatPointsOutOf()', () => {
    let grade
    let pointsPossible

    beforeEach(() => {
      grade = '7'
      pointsPossible = '10'
    })

    const formatPointsOutOf = () => GradeFormatHelper.formatPointsOutOf(grade, pointsPossible)

    it('returns the score and points possible as a fraction', () => {
      expect(formatPointsOutOf()).toBe('7/10')
    })

    it('rounds the score and points possible to two decimal places', () => {
      grade = '7.123'
      pointsPossible = '10.456'
      expect(formatPointsOutOf()).toBe('7.12/10.46')
    })

    it('returns null when grade is null', () => {
      grade = null
      expect(formatPointsOutOf()).toBeNull()
    })

    it('returns grade if pointsPossible is null', () => {
      pointsPossible = null
      expect(formatPointsOutOf()).toBe(grade)
    })
  })

  describe('.formatGradeInfo()', () => {
    let options
    let gradeInfo

    beforeEach(() => {
      gradeInfo = {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: true}
    })

    const formatGradeInfo = () => GradeFormatHelper.formatGradeInfo(gradeInfo, options)

    it('returns the grade when the pending grade is valid', () => {
      expect(formatGradeInfo()).toBe('A')
    })

    it('returns the grade when the pending grade is invalid', () => {
      gradeInfo.valid = false
      expect(formatGradeInfo()).toBe('A')
    })

    it('returns "–" (en dash) when the pending grade is null', () => {
      gradeInfo = {enteredAs: null, excused: false, grade: null, score: null, valid: true}
      expect(formatGradeInfo()).toBe('–')
    })

    it('returns the given default value when the pending grade is null', () => {
      options = {defaultValue: 'default'}
      gradeInfo = {enteredAs: null, excused: false, grade: null, score: null, valid: true}
      expect(formatGradeInfo()).toBe('default')
    })

    it('returns "Excused" when the pending grade info includes excused', () => {
      gradeInfo = {enteredAs: 'excused', excused: true, grade: null, score: null, valid: true}
      expect(formatGradeInfo()).toBe('Excused')
    })
  })
})

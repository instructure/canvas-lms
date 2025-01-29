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

describe('GradeFormatHelper#formatGrade', () => {
  let translateString

  beforeEach(() => {
    translateString = I18n.t
    jest.spyOn(numberHelper, 'validate').mockImplementation(val => !Number.isNaN(parseFloat(val)))
    jest.spyOn(I18n.constructor.prototype, 't').mockImplementation(translateString)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('formats numerical integer grades using I18n#n', () => {
    jest.spyOn(I18n.constructor.prototype, 'n').mockImplementation(() => '* 1,000')
    expect(GradeFormatHelper.formatGrade(1000)).toBe('* 1,000')
    expect(I18n.n).toHaveBeenCalledTimes(1)
  })

  it('formats points grade type using formatPointsOutOf', () => {
    expect(
      GradeFormatHelper.formatGrade('4', {
        gradingType: 'points',
        pointsPossible: '7',
        formatType: 'points_out_of_fraction',
      }),
    ).toBe('4/7')
  })

  it('formats numerical decimal grades using I18n#n', () => {
    jest.spyOn(I18n.constructor.prototype, 'n').mockImplementation(() => '* 123.45')
    expect(GradeFormatHelper.formatGrade(123.45)).toBe('* 123.45')
    expect(I18n.n).toHaveBeenCalledTimes(1)
  })

  it('formats pass_fail grades: complete', () => {
    jest.spyOn(I18n, 't').mockImplementation(() => '* complete')
    expect(GradeFormatHelper.formatGrade('complete')).toBe('* complete')
  })

  it('formats pass_fail grades: pass', () => {
    jest.spyOn(I18n, 't').mockImplementation(() => '* complete')
    expect(GradeFormatHelper.formatGrade('pass')).toBe('* complete')
  })

  it('formats pass_fail grades: incomplete', () => {
    jest.spyOn(I18n, 't').mockImplementation(() => '* incomplete')
    expect(GradeFormatHelper.formatGrade('incomplete')).toBe('* incomplete')
  })

  it('formats pass_fail grades: fail', () => {
    jest.spyOn(I18n, 't').mockImplementation(() => '* incomplete')
    expect(GradeFormatHelper.formatGrade('fail')).toBe('* incomplete')
  })

  it('returns "Excused" when the grade is "EX"', () => {
    expect(GradeFormatHelper.formatGrade('EX')).toBe('Excused')
  })

  it('parses stringified integer percentage grade when valid', () => {
    jest.spyOn(numberHelper, 'parse')
    GradeFormatHelper.formatGrade('32%')
    expect(numberHelper.parse).toHaveBeenCalledWith('32')
  })

  it('returns the given grade when not a valid number', () => {
    expect(GradeFormatHelper.formatGrade('!32%')).toBe('!32%')
  })

  it('returns the given grade when it is a letter grade', () => {
    expect(GradeFormatHelper.formatGrade('A')).toBe('A')
  })

  it('replaces trailing en-dash with minus characters', () => {
    expect(GradeFormatHelper.formatGrade('B-', {gradingType: 'letter_grade'})).toBe('B−')
  })

  it('does not transform en-dash characters that are not trailing', () => {
    expect(GradeFormatHelper.formatGrade('smarty-pants', {gradingType: 'letter_grade'})).toBe(
      'smarty-pants',
    )
  })

  it('returns the given grade when it is a mix of letters and numbers', () => {
    expect(GradeFormatHelper.formatGrade('A3')).toBe('A3')
  })

  it('returns the given grade when it is numbers followed by letters', () => {
    expect(GradeFormatHelper.formatGrade('1E', {delocalize: false})).toBe('1E')
  })

  it('does not format letter grades', () => {
    jest.spyOn(I18n.constructor.prototype, 'n')
    GradeFormatHelper.formatGrade('A')
    expect(I18n.n).not.toHaveBeenCalled()
  })

  it('returns defaultValue when grade is undefined', () => {
    expect(GradeFormatHelper.formatGrade(undefined, {defaultValue: 'no grade'})).toBe('no grade')
  })

  it('returns defaultValue when grade is null', () => {
    expect(GradeFormatHelper.formatGrade(null, {defaultValue: 'no grade'})).toBe('no grade')
  })

  it('returns defaultValue when grade is empty string', () => {
    expect(GradeFormatHelper.formatGrade('', {defaultValue: 'no grade'})).toBe('no grade')
  })

  it('returns undefined when grade is undefined without defaultValue', () => {
    expect(GradeFormatHelper.formatGrade(undefined)).toBeUndefined()
  })

  it('returns null when grade is null without defaultValue', () => {
    expect(GradeFormatHelper.formatGrade(null)).toBeNull()
  })

  it('returns empty string when grade is empty without defaultValue', () => {
    expect(GradeFormatHelper.formatGrade('')).toBe('')
  })

  it('formats numerical grades as percent with gradingType percent', () => {
    jest.spyOn(I18n.constructor.prototype, 'n')
    GradeFormatHelper.formatGrade(10, {gradingType: 'percent'})
    expect(I18n.n).toHaveBeenCalledWith(10, {percentage: true})
  })

  it('formats decimal grades as percent with gradingType percent', () => {
    jest.spyOn(I18n.constructor.prototype, 'n')
    GradeFormatHelper.formatGrade(10.1, {gradingType: 'percent'})
    expect(I18n.n).toHaveBeenCalledWith(10.1, {percentage: true})
  })

  it('formats string percentage as points with gradingType points', () => {
    jest.spyOn(I18n.constructor.prototype, 'n')
    GradeFormatHelper.formatGrade('10%', {gradingType: 'points'})
    expect(I18n.n).toHaveBeenCalledWith(10, {percentage: false})
  })

  it('rounds grades to two decimal places', () => {
    expect(GradeFormatHelper.formatGrade(10.321)).toBe('10.32')
    expect(GradeFormatHelper.formatGrade(10.325)).toBe('10.33')
  })

  it('rounds very small scores to two decimal places', () => {
    expect(GradeFormatHelper.formatGrade('.00000001', {gradingType: 'points'})).toBe('0')
  })

  it('formats scientific notation grades as rounded numeric grades', () => {
    expect(GradeFormatHelper.formatGrade('1e-8', {gradingType: 'points'})).toBe('0')
  })

  it('optionally rounds to a given precision', () => {
    expect(GradeFormatHelper.formatGrade(10.321, {precision: 3})).toBe('10.321')
  })

  it('optionally parses grades as non-localized', () => {
    jest.spyOn(numberHelper, 'parse').mockImplementation(() => 32459)
    const formatted = GradeFormatHelper.formatGrade('32.459', {delocalize: false})
    expect(numberHelper.parse).not.toHaveBeenCalled()
    expect(formatted).toBe('32.46')
  })
})

describe('GradeFormatHelper#delocalizeGrade', () => {
  it('returns input value when input is not a string', () => {
    expect(GradeFormatHelper.delocalizeGrade(1)).toBe(1)
    expect(GradeFormatHelper.delocalizeGrade(NaN)).toBeNaN()
    expect(GradeFormatHelper.delocalizeGrade(null)).toBeNull()
    expect(GradeFormatHelper.delocalizeGrade(undefined)).toBeUndefined()
    expect(GradeFormatHelper.delocalizeGrade(true)).toBe(true)
  })

  it('returns input value when not percent or point value', () => {
    expect(GradeFormatHelper.delocalizeGrade('A+')).toBe('A+')
    expect(GradeFormatHelper.delocalizeGrade('F')).toBe('F')
    expect(GradeFormatHelper.delocalizeGrade('Pass')).toBe('Pass')
  })

  it('returns non-localized point value for point value', () => {
    jest.spyOn(numberHelper, 'parse').mockImplementation(() => 123.45)
    expect(GradeFormatHelper.delocalizeGrade('123,45')).toBe('123.45')
    expect(numberHelper.parse).toHaveBeenCalledWith('123,45')
  })

  it('returns non-localized percent value for percent value', () => {
    jest.spyOn(numberHelper, 'parse').mockImplementation(() => 12.34)
    expect(GradeFormatHelper.delocalizeGrade('12,34%')).toBe('12.34%')
    expect(numberHelper.parse).toHaveBeenCalledWith('12,34')
  })
})

describe('GradeFormatHelper#parseGrade', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('parses stringified grades', () => {
    expect(GradeFormatHelper.parseGrade('123')).toBe(123)
    expect(GradeFormatHelper.parseGrade('123.456')).toBe(123.456)
  })

  it('parses stringified percentages', () => {
    expect(GradeFormatHelper.parseGrade('123%')).toBe(123)
    expect(GradeFormatHelper.parseGrade('123.456%')).toBe(123.456)
  })

  it('uses numberHelper.parse for stringified grades', () => {
    jest.spyOn(numberHelper, 'parse')
    GradeFormatHelper.parseGrade('123')
    GradeFormatHelper.parseGrade('123.456')
    expect(numberHelper.parse).toHaveBeenCalledTimes(2)
  })

  it('uses numberHelper.parse for stringified percentages', () => {
    jest.spyOn(numberHelper, 'parse')
    GradeFormatHelper.parseGrade('123%')
    GradeFormatHelper.parseGrade('123.456%')
    expect(numberHelper.parse).toHaveBeenCalledTimes(2)
  })

  it('returns numerical grades without parsing', () => {
    expect(GradeFormatHelper.parseGrade(123.45)).toBe(123.45)
  })

  it('returns letter grades without parsing', () => {
    expect(GradeFormatHelper.parseGrade('A')).toBe('A')
  })

  it('returns other string values without parsing', () => {
    expect(GradeFormatHelper.parseGrade('!123')).toBe('!123')
  })

  it('handles undefined, null, and empty string', () => {
    expect(GradeFormatHelper.parseGrade(undefined)).toBeUndefined()
    expect(GradeFormatHelper.parseGrade(null)).toBeNull()
    expect(GradeFormatHelper.parseGrade('')).toBe('')
  })

  it('parses grades without delocalizing when specified', () => {
    jest.spyOn(numberHelper, 'parse')
    GradeFormatHelper.parseGrade('123', {delocalize: false})
    expect(numberHelper.parse).not.toHaveBeenCalled()
  })

  it('parses various grade formats without delocalizing', () => {
    expect(GradeFormatHelper.parseGrade('123', {delocalize: false})).toBe(123)
    expect(GradeFormatHelper.parseGrade('123.456', {delocalize: false})).toBe(123.456)
    expect(GradeFormatHelper.parseGrade('123%', {delocalize: false})).toBe(123)
    expect(GradeFormatHelper.parseGrade('123.456%', {delocalize: false})).toBe(123.456)
  })
})

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
import numberHelper from '../numberHelper'
import I18nStubber from '@canvas/test-utils/I18nStubber'

describe('Number Helper Tests', () => {
  let input, output, delimiter, separator

  beforeEach(() => {
    delimiter = ' '
    separator = ','
    I18nStubber.pushFrame()
    I18nStubber.stub('foo', {
      'number.format.delimiter': delimiter,
      'number.format.separator': separator,
    })
    I18nStubber.setLocale('foo')

    input = '47'
    output = 47
    jest.spyOn(numberHelper, '_parseNumber').mockReturnValue(output)
  })

  afterEach(() => {
    I18nStubber.clear()
    if (numberHelper._parseNumber.mockRestore) {
      numberHelper._parseNumber.mockRestore()
    }
  })

  test('uses default parse function', () => {
    numberHelper._parseNumber.mockRestore()
    expect(numberHelper.parse(`1${delimiter}000${separator}2`)).toEqual(1000.2)
  })

  test('returns NaN for invalid numbers', () => {
    numberHelper._parseNumber.mockRestore()
    expect(Number.isNaN(numberHelper.parse('foo'))).toBe(true)
  })

  test('returns value of parse function', () => {
    expect(numberHelper.parse('1')).toEqual(output)
  })

  test('uses delimiter and separator from current locale', () => {
    numberHelper.parse(input)
    expect(numberHelper._parseNumber).toHaveBeenCalledWith(input, {
      thousands: delimiter,
      decimal: separator,
    })
  })

  test('uses default delimiter and separator if not a valid number', () => {
    numberHelper._parseNumber.mockReturnValueOnce(NaN)
    const ret = numberHelper.parse(input)
    expect(numberHelper._parseNumber).toHaveBeenCalledWith(input)
    expect(ret).toEqual(output)
  })

  test('returns NaN for null and undefined values', () => {
    expect(Number.isNaN(numberHelper.parse(null))).toBe(true)
    expect(Number.isNaN(numberHelper.parse(undefined))).toBe(true)
  })

  test('returns input if already a number', () => {
    input = 4.7
    expect(numberHelper.parse(input)).toEqual(input)
  })

  test('supports e notation', () => {
    numberHelper._parseNumber.mockRestore()
    expect(numberHelper.parse('3e2')).toEqual(300)
  })

  test('supports a negative exponent', () => {
    numberHelper._parseNumber.mockRestore()
    expect(numberHelper.parse('3e-1')).toEqual(0.3)
  })

  test('supports a negative scientific notation value', () => {
    numberHelper._parseNumber.mockRestore()
    expect(numberHelper.parse('-3e1')).toEqual(-30)
  })

  test('does not support an invalid scientific notation format', () => {
    numberHelper._parseNumber.mockRestore()
    expect(Number.isNaN(numberHelper.parse('19 will e'))).toBe(true)
  })

  test('parses toString value of objects', () => {
    numberHelper._parseNumber.mockRestore()
    const obj = {toString: () => `2${separator}3`}
    expect(numberHelper.parse(obj)).toEqual(2.3)
  })

  test('parses positive numbers beginning with "+"', () => {
    numberHelper._parseNumber.mockRestore()
    expect(numberHelper.parse('+4')).toEqual(4)
  })

  test('validate returns false if parse returns NaN', () => {
    numberHelper._parseNumber.mockReturnValue(NaN)
    expect(numberHelper.validate('1')).toBe(false)
  })

  test('validate returns true if parse returns a number', () => {
    numberHelper._parseNumber.mockReturnValue(1)
    expect(numberHelper.validate('1')).toBe(true)
  })
})

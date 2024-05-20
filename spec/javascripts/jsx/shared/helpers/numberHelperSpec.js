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

import numberHelper from '@canvas/i18n/numberHelper'
import I18nStubber from 'helpers/I18nStubber'

let input, output, delimiter, separator

QUnit.module('Number Helper Parse and Validate', {
  setup() {
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
    sinon.stub(numberHelper, '_parseNumber').returns(output)
  },

  teardown() {
    I18nStubber.clear()
    if (numberHelper._parseNumber.restore) {
      numberHelper._parseNumber.restore()
    }
  },
})

test('uses default parse function', () => {
  numberHelper._parseNumber.restore()
  equal(numberHelper.parse(`1${delimiter}000${separator}2`), 1000.2)
})

test('returns NaN for invalid numbers', () => {
  numberHelper._parseNumber.restore()
  ok(Number.isNaN(numberHelper.parse('foo')))
})

test('returns value of parse function', () => {
  equal(numberHelper.parse('1'), output)
})

test('uses delimiter and separator from current locale', () => {
  numberHelper.parse(input)
  ok(
    numberHelper._parseNumber.calledWithMatch(input, {
      thousands: delimiter,
      decimal: separator,
    })
  )
})

test('uses default delimiter and separator if not a valid number', () => {
  numberHelper._parseNumber.onFirstCall().returns(NaN)
  const ret = numberHelper.parse(input)
  ok(numberHelper._parseNumber.secondCall.calledWithExactly, input)
  equal(ret, output)
})

test('returns NaN for null and undefined values', () => {
  ok(Number.isNaN(numberHelper.parse(null)))
  ok(Number.isNaN(numberHelper.parse(undefined)))
})

test('returns input if already a number', () => {
  input = 4.7
  equal(numberHelper.parse(input), input)
})

test('supports e notation', () => {
  numberHelper._parseNumber.restore()
  equal(numberHelper.parse('3e2'), 300)
})

test('supports a negative exponent', () => {
  numberHelper._parseNumber.restore()
  equal(numberHelper.parse('3e-1'), 0.3)
})

test('supports a negative scientific notation value', () => {
  numberHelper._parseNumber.restore()
  equal(numberHelper.parse('-3e1'), -30)
})

test('does not support an invalid scientific notation format', () => {
  numberHelper._parseNumber.restore()
  ok(Number.isNaN(numberHelper.parse('19 will e')))
})

test('parses toString value of objects', () => {
  numberHelper._parseNumber.restore()
  const obj = {toString: () => `2${separator}3`}
  equal(numberHelper.parse(obj), 2.3)
})

test('parses positive numbers beginning with "+"', () => {
  numberHelper._parseNumber.restore()
  equal(numberHelper.parse('+4'), 4)
})

test('validate returns false if parse returns NaN', () => {
  numberHelper._parseNumber.returns(NaN)
  equal(numberHelper.validate('1'), false)
})

test('validate returns true if parse returns a number', () => {
  numberHelper._parseNumber.returns(1)
  equal(numberHelper.validate('1'), true)
})

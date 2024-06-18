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

import numberFormat from '../numberFormat'
import I18n from '@canvas/i18n'

describe('numberFormat _format', () => {
  afterEach(() => {
    if (I18n.n.restore) {
      I18n.n.restore()
    }
  })

  test('passes through non-numbers', () => {
    expect(numberFormat._format('foo')).toBe('foo')
    // eslint-disable-next-line no-restricted-globals
    expect(isNaN(numberFormat._format(NaN))).toBe(true)
  })

  test('proxies to I18n for numbers', () => {
    jest.spyOn(I18n, 'n').mockReturnValue('1,23')
    expect(numberFormat._format(1.23, {foo: 'bar'})).toBe('1,23')
    expect(I18n.n).toHaveBeenCalledWith(1.23, {foo: 'bar'})
  })
})

describe('numberFormat outcomeScore', () => {
  test('requests precision 2', () => {
    expect(numberFormat.outcomeScore(1.234)).toBe('1.23')
  })

  test('requests strip insignificant zeros', () => {
    expect(numberFormat.outcomeScore(1.00001)).toBe('1')
  })
})

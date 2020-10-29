/* Copyright (C) 2020 - present Instructure, Inc.
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

import {installIntlPolyfills} from '../IntlPolyFills'

describe('IntlPolyFills::', () => {
  let f

  beforeAll(installIntlPolyfills)

  describe('RelativeTimeFormat', () => {
    it('implements format', () => {
      f = new Intl.RelativeTimeFormat()
      expect(f.format).toBeInstanceOf(Function)
    })

    it('throws on a bad unit', () => {
      f = new Intl.RelativeTimeFormat()
      expect(() => f.format(1, 'nonsense')).toThrow(RangeError)
    })

    describe('for numeric=always', () => {
      beforeEach(() => {
        f = new Intl.RelativeTimeFormat()
      })

      it('handles singular units in the past and future', () => {
        expect(f.format(1, 'hour')).toBe('in 1 hour')
        expect(f.format(-1, 'hour')).toBe('1 hour ago')
      })

      it('handles plural units in the past and future', () => {
        expect(f.format('5', 'week')).toBe('in 5 weeks')
        expect(f.format(-5, 'week')).toBe('5 weeks ago')
      })

      it('rounds off to 3 decimal places', () => {
        expect(f.format(2.34567, 'day')).toBe('in 2.346 days')
        expect(f.format(-9.87654, 'week')).toBe('9.877 weeks ago')
        expect(f.format(0.0002, 'day')).toBe('in 0 days')
        expect(f.format(-0.0002, 'day')).toBe('0 days ago')
      })
    })

    describe('for numeric=auto', () => {
      beforeEach(() => {
        f = new Intl.RelativeTimeFormat('en-US', {numeric: 'auto'})
      })

      it('handles plural units in the past and future', () => {
        expect(f.format('5', 'year')).toBe('in 5 years')
        expect(f.format(-5, 'year')).toBe('5 years ago')
      })

      it('switches to relative phrases for -1, 0, and 1', () => {
        expect(f.format(-1, 'day')).toBe('yesterday')
        expect(f.format(0, 'day')).toBe('today')
        expect(f.format(1, 'day')).toBe('tomorrow')
      })

      it('sticks with singular units when there is no relative phrase', () => {
        expect(f.format(-1, 'second')).toBe('1 second ago')
        expect(f.format(0, 'second')).toBe('now')
        expect(f.format(1, 'second')).toBe('in 1 second')
      })

      it('is not tempted by things that are close to 1 or 0', () => {
        expect(f.format(-1.2, 'week')).toBe('1.2 weeks ago')
        expect(f.format(0.5, 'day')).toBe('in 0.5 days')
        expect(f.format(1.01, 'week')).toBe('in 1.01 weeks')
      })

      it('deals with roundoff of stuff VERY close to 1 or 0', () => {
        expect(f.format(0.0002, 'second')).toBe('now')
        expect(f.format(1.0002, 'day')).toBe('tomorrow')
        expect(f.format(-1.0002, 'week')).toBe('last week')
      })
    })
  })
})

/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import Big from 'big.js'
import {
  add,
  divide,
  multiply,
  scoreToPercentage,
  sum,
  sumBy,
  toNumber,
  weightedPercent,
  bigSum,
  totalGradeRound,
} from '../GradeCalculationHelper'

describe('GradeCalculationHelper', () => {
  describe('.add()', () => {
    test('adds two positive numbers', () => {
      expect(toNumber(add(5, 3))).toBe(8)
    })

    test('adds two negative numbers', () => {
      expect(toNumber(add(-5, -3))).toBe(-8)
    })

    test('adds positive and negative numbers', () => {
      expect(toNumber(add(5, -3))).toBe(2)
    })

    test('adds decimal numbers', () => {
      expect(toNumber(add(1.5, 2.3))).toBeCloseTo(3.8)
    })

    test('avoids floating point calculation issues', () => {
      expect(toNumber(add(0.1, 0.2))).toBeCloseTo(0.3)
    })

    test('treats null first argument as 0', () => {
      expect(toNumber(add(null, 5))).toBe(5)
    })

    test('treats null second argument as 0', () => {
      expect(toNumber(add(5, null))).toBe(5)
    })

    test('treats both null arguments as 0', () => {
      expect(toNumber(add(null, null))).toBe(0)
    })

    test('treats undefined first argument as 0', () => {
      expect(toNumber(add(undefined, 5))).toBe(5)
    })

    test('treats undefined second argument as 0', () => {
      expect(toNumber(add(5, undefined))).toBe(5)
    })

    test('returns Big instance', () => {
      expect(add(5, 3)).toBeInstanceOf(Big)
    })
  })

  describe('.divide()', () => {
    test('divides two positive numbers', () => {
      expect(toNumber(divide(10, 2))).toBe(5)
    })

    test('divides with decimal result', () => {
      expect(toNumber(divide(10, 3))).toBeCloseTo(3.333333)
    })

    test('divides negative numbers', () => {
      expect(toNumber(divide(-10, 2))).toBe(-5)
    })

    test('divides positive by negative', () => {
      expect(toNumber(divide(10, -2))).toBe(-5)
    })

    test('avoids floating point calculation issues', () => {
      expect(toNumber(divide(0.3, 0.1))).toBeCloseTo(3)
    })

    test('treats null dividend as 0', () => {
      expect(toNumber(divide(null, 5))).toBe(0)
    })

    test('treats undefined dividend as 0', () => {
      expect(toNumber(divide(undefined, 5))).toBe(0)
    })

    test('throws error when dividing by 0', () => {
      expect(() => divide(10, 0)).toThrow('[big.js] Division by zero')
    })

    test('throws error when dividing by null', () => {
      expect(() => divide(10, null)).toThrow('[big.js] Division by zero')
    })

    test('throws error when dividing by undefined', () => {
      expect(() => divide(10, undefined)).toThrow('[big.js] Division by zero')
    })

    test('returns Big instance', () => {
      expect(divide(10, 2)).toBeInstanceOf(Big)
    })
  })

  describe('.multiply()', () => {
    test('multiplies two positive numbers', () => {
      expect(toNumber(multiply(5, 3))).toBe(15)
    })

    test('multiplies two negative numbers', () => {
      expect(toNumber(multiply(-5, -3))).toBe(15)
    })

    test('multiplies positive and negative numbers', () => {
      expect(toNumber(multiply(5, -3))).toBe(-15)
    })

    test('multiplies decimal numbers', () => {
      expect(toNumber(multiply(1.5, 2))).toBeCloseTo(3)
    })

    test('avoids floating point calculation issues', () => {
      expect(toNumber(multiply(0.1, 0.2))).toBeCloseTo(0.02)
    })

    test('treats null first argument as 0', () => {
      expect(toNumber(multiply(null, 5))).toBe(0)
    })

    test('treats null second argument as 0', () => {
      expect(toNumber(multiply(5, null))).toBe(0)
    })

    test('treats both null arguments as 0', () => {
      expect(toNumber(multiply(null, null))).toBe(0)
    })

    test('treats undefined first argument as 0', () => {
      expect(toNumber(multiply(undefined, 5))).toBe(0)
    })

    test('treats undefined second argument as 0', () => {
      expect(toNumber(multiply(5, undefined))).toBe(0)
    })

    test('returns Big instance', () => {
      expect(multiply(5, 3)).toBeInstanceOf(Big)
    })
  })

  describe('.toNumber()', () => {
    test('converts Big to number', () => {
      const bigValue = new Big(42)
      expect(toNumber(bigValue)).toBe(42)
    })

    test('converts decimal Big to number', () => {
      const bigValue = new Big(3.14159)
      expect(toNumber(bigValue)).toBeCloseTo(3.14159)
    })

    test('converts negative Big to number', () => {
      const bigValue = new Big(-42)
      expect(toNumber(bigValue)).toBe(-42)
    })

    test('converts zero Big to number', () => {
      const bigValue = new Big(0)
      expect(toNumber(bigValue)).toBe(0)
    })

    test('preserves precision from Big calculation', () => {
      const bigValue = new Big(0.1).plus(0.2)
      expect(toNumber(bigValue)).toBeCloseTo(0.3)
    })
  })

  describe('.bigSum()', () => {
    test('sums multiple Big values', () => {
      const values = [new Big(1), new Big(2), new Big(3)]
      expect(toNumber(bigSum(values))).toBe(6)
    })

    test('sums decimal Big values', () => {
      const values = [new Big(1.5), new Big(2.3), new Big(0.7)]
      expect(toNumber(bigSum(values))).toBeCloseTo(4.5)
    })

    test('handles empty array', () => {
      expect(toNumber(bigSum([]))).toBe(0)
    })

    test('handles array with single value', () => {
      const values = [new Big(42)]
      expect(toNumber(bigSum(values))).toBe(42)
    })

    test('treats null values as 0', () => {
      const values = [new Big(5), null, new Big(3)]
      expect(toNumber(bigSum(values))).toBe(8)
    })

    test('avoids floating point calculation issues', () => {
      const values = [new Big(0.1), new Big(0.2), new Big(0.3)]
      expect(toNumber(bigSum(values))).toBeCloseTo(0.6)
    })

    test('handles negative values', () => {
      const values = [new Big(10), new Big(-3), new Big(-2)]
      expect(toNumber(bigSum(values))).toBe(5)
    })

    test('returns Big instance', () => {
      const values = [new Big(1), new Big(2)]
      expect(bigSum(values)).toBeInstanceOf(Big)
    })
  })

  describe('.sum()', () => {
    test('sums up values', () => {
      expect(sum([1.25, 2])).toBeCloseTo(3.25)
    })

    test('treats null as 0', () => {
      expect(sum([1.25, null])).toBeCloseTo(1.25)
    })

    test('handles being passed only null values', () => {
      expect(sum([null, null])).toBe(0)
    })

    test('treats undefined as 0', () => {
      expect(sum([1.25, undefined])).toBeCloseTo(1.25)
    })

    test('handles being passed only undefined values', () => {
      expect(sum([undefined, undefined])).toBe(0)
    })

    test('handles being passed a mix of null and undefined values', () => {
      expect(sum([null, 1.25, undefined])).toBeCloseTo(1.25)
    })

    test('avoids floating point calculation issues', () => {
      const values = [7, 6.1, 7, 6.9, 6.27]
      expect(sum(values)).toBeCloseTo(33.27)
    })
  })

  describe('.sumBy()', () => {
    let collection: Array<{price: number | null | undefined; weight?: number}>

    beforeEach(() => {
      collection = [
        {price: 1.25, weight: 5},
        {price: 2, weight: 3.5},
      ]
    })

    test('sums up the items in the collection by the specified attribute', () => {
      expect(sumBy(collection, 'price')).toBeCloseTo(3.25)
    })

    test('treats null as 0', () => {
      collection[1].price = null
      expect(sumBy(collection, 'price')).toBeCloseTo(1.25)
    })

    test('handles being passed only null values', () => {
      collection[0].price = null
      collection[1].price = null
      expect(sumBy(collection, 'price')).toBe(0)
    })

    test('treats undefined as 0', () => {
      collection[1].price = undefined
      expect(sumBy(collection, 'price')).toBeCloseTo(1.25)
    })

    test('handles being passed only undefined values', () => {
      collection[0].price = undefined
      collection[1].price = undefined
      expect(sumBy(collection, 'price')).toBe(0)
    })

    test('handles being passed a mix of null and undefined values', () => {
      collection.push({price: null})
      collection.push({price: undefined})
      expect(sumBy(collection, 'price')).toBeCloseTo(3.25)
    })

    test('avoids floating point calculation issues', () => {
      collection = [7, 6.1, 7, 6.9, 6.27].map(price => ({price}))
      expect(sumBy(collection, 'price')).toBeCloseTo(33.27)
    })
  })

  describe('.scoreToPercentage()', () => {
    test('returns the score/points possible as a percentage', () => {
      expect(scoreToPercentage(5, 8)).toBeCloseTo(62.5)
    })

    test('avoids floating point calculation issues', () => {
      expect(scoreToPercentage(946.65, 1000)).toBeCloseTo(94.665)
    })

    describe('when points possible is 0', () => {
      test('returns Infinity when score is > 0', () => {
        expect(scoreToPercentage(5, 0)).toBe(Infinity)
      })

      test('returns -Infinity when score is < 0', () => {
        expect(scoreToPercentage(-5, 0)).toBe(-Infinity)
      })

      test('returns NaN when score is 0', () => {
        expect(scoreToPercentage(0, 0)).toBeNaN()
      })

      test('returns NaN when score is null', () => {
        expect(scoreToPercentage(null, 0)).toBeNaN()
      })

      test('returns NaN when score is undefined', () => {
        expect(scoreToPercentage(undefined, 0)).toBeNaN()
      })
    })

    describe('when points possible is null', () => {
      test('returns Infinity when score is > 0', () => {
        expect(scoreToPercentage(5, null)).toBe(Infinity)
      })

      test('returns -Infinity when score is < 0', () => {
        expect(scoreToPercentage(-5, null)).toBe(-Infinity)
      })

      test('returns NaN when score is 0', () => {
        expect(scoreToPercentage(0, null)).toBeNaN()
      })

      test('returns NaN when score is null', () => {
        expect(scoreToPercentage(null, null)).toBeNaN()
      })

      test('returns NaN when score is undefined', () => {
        expect(scoreToPercentage(undefined, null)).toBeNaN()
      })
    })

    describe('when points possible is undefined', () => {
      test('returns NaN when score is > 0', () => {
        expect(scoreToPercentage(5, undefined)).toBeNaN()
      })

      test('returns NaN when score is < 0', () => {
        expect(scoreToPercentage(-5, undefined)).toBeNaN()
      })

      test('returns NaN when score is 0', () => {
        expect(scoreToPercentage(0, undefined)).toBeNaN()
      })

      test('returns NaN when score is null', () => {
        expect(scoreToPercentage(null, undefined)).toBeNaN()
      })

      test('returns NaN when score is undefined', () => {
        expect(scoreToPercentage(undefined, undefined)).toBeNaN()
      })
    })

    describe('when score is null', () => {
      test('returns 0 when points possible is > 0', () => {
        expect(scoreToPercentage(null, 10)).toBe(0)
      })

      test('returns NaN when points possible is 0', () => {
        expect(scoreToPercentage(null, 0)).toBeNaN()
      })
    })

    describe('when score is undefined', () => {
      test('returns NaN when points possible is > 0', () => {
        expect(scoreToPercentage(undefined, 10)).toBeNaN()
      })

      test('returns NaN when points possible is 0', () => {
        expect(scoreToPercentage(undefined, 0)).toBeNaN()
      })
    })
  })

  describe('.weightedPercent()', () => {
    test('returns the score divided by possible, times weight', () => {
      expect(toNumber(weightedPercent({score: 9, possible: 10, weight: 3}))).toBeCloseTo(2.7)
    })

    test('avoids floating point errors', () => {
      expect(toNumber(weightedPercent({score: 5.13, possible: 10, weight: 100}))).toBeCloseTo(51.3)
    })

    test('returns 0 when the score is 0', () => {
      expect(toNumber(weightedPercent({score: 0, possible: 10, weight: 1}))).toBe(0)
    })

    test('returns 0 when the weight is 0', () => {
      expect(toNumber(weightedPercent({score: 10, possible: 10, weight: 0}))).toBe(0)
    })

    test('returns 0 when score and weight are > 0 and possible is 0', () => {
      expect(toNumber(weightedPercent({score: 10, possible: 0, weight: 25}))).toBe(0)
    })
  })

  describe('.totalGradeRound()', () => {
    test('correctly handles a sum of irrational Big.js values', () => {
      // matches test found in spec/lib/grade_calculator_spec.rb to check rounding consistency
      // We want to move to a rounding strategy that will keep value as a fraction using rationals.
      // Remove/Edit this comment and update the test when we do that.
      const group1 = Big(11.8).div(12).times(12)
      const group2 = Big(82).div(82).times(10)
      const group3 = Big(89.5).div(100).times(15)
      const group4 = Big(85).div(100).times(21)
      const group5 = Big(85).div(100).times(21)
      const group6 = Big(83).div(100).times(21)
      const sum = bigSum([group1, group2, group3, group4, group5, group6])

      expect(totalGradeRound(sum, 2)).toBe(88.36)
    })
  })
})

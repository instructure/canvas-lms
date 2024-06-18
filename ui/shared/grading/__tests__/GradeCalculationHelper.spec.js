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

import {scoreToPercentage, sum, sumBy, toNumber, weightedPercent} from '../GradeCalculationHelper'

describe('GradeCalculationHelper', () => {
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
    let collection

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
})

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

import {
  scoreToPercentage,
  sum,
  sumBy,
  toNumber,
  weightedPercent
} from 'jsx/gradebook/shared/helpers/GradeCalculationHelper'

QUnit.module('GradeCalculationHelper', () => {
  QUnit.module('.sum()', () => {
    test('sums up values', () => {
      strictEqual(sum([1.25, 2]), 3.25)
    })

    test('treats null as 0', () => {
      strictEqual(sum([1.25, null]), 1.25)
    })

    test('handles being passed only null values', () => {
      strictEqual(sum([null, null]), 0)
    })

    test('treats undefined as 0', () => {
      strictEqual(sum([1.25, undefined]), 1.25)
    })

    test('handles being passed only undefined values', () => {
      strictEqual(sum([undefined, undefined]), 0)
    })

    test('handles being passed a mix of null and undefined values', () => {
      strictEqual(sum([null, 1.25, undefined]), 1.25)
    })

    test('handles being passed a collection of exclusively null and undefined values', () => {
      strictEqual(sum([null, undefined]), 0)
    })

    test('avoids floating point calculation issues', () => {
      const values = [7, 6.1, 7, 6.9, 6.27]
      // 7 + 6.1 + 7 + 6.9 + 6.27 === 33.269999999999996
      strictEqual(sum(values), 33.27)
    })
  })

  QUnit.module('.sumBy()', hooks => {
    let collection

    hooks.beforeEach(() => {
      collection = [{price: 1.25, weight: 5}, {price: 2, weight: 3.5}]
    })

    test('sums up the items in the collection by the specified attribute', () => {
      strictEqual(sumBy(collection, 'price'), 3.25)
    })

    test('treats null as 0', () => {
      collection[1].price = null
      strictEqual(sumBy(collection, 'price'), 1.25)
    })

    test('handles being passed only null values', () => {
      collection[0].price = null
      collection[1].price = null
      strictEqual(sumBy(collection, 'price'), 0)
    })

    test('treats undefined as 0', () => {
      collection[1].price = undefined
      strictEqual(sumBy(collection, 'price'), 1.25)
    })

    test('handles being passed only undefined values', () => {
      collection[0].price = undefined
      collection[1].price = undefined
      strictEqual(sumBy(collection, 'price'), 0)
    })

    test('handles being passed a mix of null and undefined values', () => {
      collection.push({price: null})
      collection.push({price: undefined})
      strictEqual(sumBy(collection, 'price'), 3.25)
    })

    test('handles being passed a collection of exclusively null and undefined values', () => {
      collection[0].price = null
      collection[1].price = undefined
      strictEqual(sumBy(collection, 'price'), 0)
    })

    test('avoids floating point calculation issues', () => {
      collection = [7, 6.1, 7, 6.9, 6.27].map(price => ({price}))
      // 7 + 6.1 + 7 + 6.9 + 6.27 === 33.269999999999996
      strictEqual(sumBy(collection, 'price'), 33.27)
    })
  })

  QUnit.module('.scoreToPercentage()', () => {
    test('returns the score/points possible as a percentage', () => {
      strictEqual(scoreToPercentage(5, 8), 62.5)
    })

    test('avoids floating point calculation issues', () => {
      // 946.65 / 1000 * 100 === 94.66499999999999
      strictEqual(scoreToPercentage(946.65, 1000), 94.665)
    })

    QUnit.module('when points possible is 0', () => {
      test('returns Infinity when score is > 0', () => {
        strictEqual(scoreToPercentage(5, 0), Infinity)
      })

      test('returns -Infinity when score is < 0', () => {
        strictEqual(scoreToPercentage(-5, 0), -Infinity)
      })

      test('returns NaN when score is 0', () => {
        ok(Number.isNaN(scoreToPercentage(0, 0)))
      })

      test('returns NaN when score is null', () => {
        ok(Number.isNaN(scoreToPercentage(null, 0)))
      })

      test('returns NaN when score is undefined', () => {
        ok(Number.isNaN(scoreToPercentage(undefined, 0)))
      })
    })

    QUnit.module('when points possible is null', () => {
      test('returns Infinity when score is > 0', () => {
        strictEqual(scoreToPercentage(5, null), Infinity)
      })

      test('returns -Infinity when score is < 0', () => {
        strictEqual(scoreToPercentage(-5, null), -Infinity)
      })

      test('returns NaN when score is 0', () => {
        ok(Number.isNaN(scoreToPercentage(0, null)))
      })

      test('returns NaN when score is null', () => {
        ok(Number.isNaN(scoreToPercentage(null, null)))
      })

      test('returns NaN when score is undefined', () => {
        ok(Number.isNaN(scoreToPercentage(undefined, null)))
      })
    })

    QUnit.module('when points possible is undefined', () => {
      test('returns NaN when score is > 0', () => {
        ok(Number.isNaN(scoreToPercentage(5, undefined)))
      })

      test('returns NaN when score is < 0', () => {
        ok(Number.isNaN(scoreToPercentage(-5, undefined)))
      })

      test('returns NaN when score is 0', () => {
        ok(Number.isNaN(scoreToPercentage(0, undefined)))
      })

      test('returns NaN when score is null', () => {
        ok(Number.isNaN(scoreToPercentage(null, undefined)))
      })

      test('returns NaN when score is undefined', () => {
        ok(Number.isNaN(scoreToPercentage(undefined, undefined)))
      })
    })

    QUnit.module('when score is null', () => {
      test('returns 0 when points possible is > 0', () => {
        strictEqual(scoreToPercentage(null, 10), 0)
      })

      test('returns NaN when points possible is 0', () => {
        ok(Number.isNaN(scoreToPercentage(null, 0)))
      })
    })

    QUnit.module('when score is undefined', () => {
      test('returns NaN when points possible is > 0', () => {
        ok(Number.isNaN(scoreToPercentage(undefined, 10)))
      })

      test('returns NaN when points possible is 0', () => {
        ok(Number.isNaN(scoreToPercentage(undefined, 0)))
      })
    })
  })

  QUnit.module('.weightedPercent()', () => {
    test('returns the score divided by possible, times weight', () => {
      strictEqual(toNumber(weightedPercent({score: 9, possible: 10, weight: 3})), 2.7)
    })

    test('avoids floating point errors', () => {
      // 5.13 / 10 * 100 === 51.300000000000004
      strictEqual(toNumber(weightedPercent({score: 5.13, possible: 10, weight: 100})), 51.3)
    })

    test('returns 0 when the score is 0', () => {
      strictEqual(toNumber(weightedPercent({score: 0, possible: 10, weight: 1})), 0)
    })

    test('returns 0 when the weight is 0', () => {
      strictEqual(toNumber(weightedPercent({score: 10, possible: 10, weight: 0})), 0)
    })
  })
})

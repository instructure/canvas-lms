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

import makePromisePool from '../index'

describe('makePromisePool', () => {
  let activeWorkers = 0

  afterEach(() => {
    activeWorkers = 0
  })

  test('makePromisePool respects the pool size', async () => {
    const dataList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    const options = {
      internvalTime: 50,
      poolSize: 2,
    }

    function makePromise() {
      activeWorkers++
      expect(activeWorkers).toBeLessThanOrEqual(options.poolSize)

      return new Promise(resolve => {
        setTimeout(() => {
          expect(activeWorkers).toBeLessThanOrEqual(options.poolSize)
          activeWorkers--
          resolve()
        }, 20)
      })
    }

    await makePromisePool(dataList, makePromise, options)
    expect(activeWorkers).toBe(0)
  })

  test('makePromisePool reports successes and failures correctly', async () => {
    const dataList = [1, 2, 3, 4, 5]
    const options = {
      internvalTime: 100,
      poolSize: 3,
    }

    function makePromise(num) {
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          if (num % 2 === 0) {
            resolve({})
          } else {
            reject(new Error('odd number'))
          }
        }, 20)
      })
    }

    const results = await makePromisePool(dataList, makePromise, options)
    expect(results.successes).toHaveLength(2)
    expect(results.failures).toHaveLength(3)
    expect(results.successes.map(s => s.data)).toEqual([2, 4])
    expect(results.failures.map(f => f.data)).toEqual([1, 3, 5])
    expect(results.failures.every(f => f.err instanceof Error)).toBe(true)
    expect(results.failures.every(f => f.err.message === 'odd number')).toBe(true)
  })
})

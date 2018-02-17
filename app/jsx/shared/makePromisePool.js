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

/**
 * Create a pool that executes a promise-returning function for each item in an array, limiting the
 * number of concurrent promises to the pool size. Essentially combines a bunch of promise operations
 * into a single promise and limits the number of concurrent promises.
 *
 * Useful for when you need to execute a large number of promises in a single operation, but you want
 * to limit the number of promises running at the same time.
 *
 * For example, if you need to make 100 API calls to update 100 different items, but don't want to
 * overload the application by doing them all at once, you can use a promise pool of size 5 to only
 * run a maximum of 5 API calls at the same time.
 *
 * @param {array} dataList list of items for which we need to run a promise task for
 * @param {function} makePromise function that takes in an item from dataList and returns a promise
 * @param {poolSize, intervalTime} opts optional options for the promise pool
 * poolSize: maximum number of promises to run at the same time
 * intervalTime: how often to check on the progress of the promises
 *
 * @returns Promise that resolves when all tasks are done. Promise result contains successes and
 * failures properties representing which tasks succeeded and failed
 *
 * @example
 * const dataList = ['1', '2', '3', '4', '5']
 *
 * function deleteItem (id) {
 *  return axios.delete('/api/v1/items/' + id)
 * }
 *
 * const opts = { poolSize: 2 }
 *
 * // in this example we have to delete a bunch of items, but we don't wanna overload the backend
 * // with a bunch of simultaneous requests so we use makePromisePool to execute a max of 2 at a time
 * makePromisePool(dataList, deleteItem, opts)
 *   .then(results => {
 *      console.log(results.successes.length, 'items successfully deleted')
 *      console.log(results.failures.length, 'failed to delete')
 *   })
 */
export default function makePromisePool (dataList, makePromise, opts = {}) {
  const poolSize = opts.poolSize || 5
  const intervalTime = opts.intervalTime || 300

  return new Promise((resolve) => {
    const successes = []
    const failures = []
    let activeWorkers = 0
    let dataIndex = 0

    function queueNextPromise () {
      const data = dataList[dataIndex++]
      activeWorkers++
      makePromise(data)
        .then(res => {
          successes.push({ data, res })
          activeWorkers--
        })
        .catch(err => {
          failures.push({ data, err })
          activeWorkers--
        })
    }

    function evaluateProgress () {
      // if there are still items to process
      if (dataIndex < dataList.length) {
        // while there are items to process and we have room in our pool..
        while (dataIndex < dataList.length && activeWorkers < poolSize) {
          queueNextPromise()
        }

        // check on the progress again after an interval timeout
        setTimeout(evaluateProgress, intervalTime)
      } else  {
        // check that all workers are actually done
        if (activeWorkers === 0) {
          // looks like all our promises finished executing, so lets return results
          resolve({ successes, failures })
        } else {
          // check on the progress again after an interval timeout
          setTimeout(evaluateProgress, intervalTime)
        }
      }
    }

    // startup the promise pool
    evaluateProgress()
  })
}
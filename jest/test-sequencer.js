/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

const Sequencer = require('@jest/test-sequencer').default

class ParallelSequencer extends Sequencer {
  jobsCount = parseInt(process.env.CI_NODE_TOTAL, 10)

  jobIndex = parseInt(process.env.CI_NODE_INDEX, 10)

  sort(tests) {
    if (!process.env.CI) return tests

    const stats = {}
    const fileSize = ({path, context: {hasteFS}}) =>
      stats[path] || (stats[path] = hasteFS.getSize(path) || 0)
    const hasFailed = (cache, test) => cache[test.path] && cache[test.path][0] === 0
    const time = (cache, test) => cache[test.path] && cache[test.path][1]
    const chunkSize = Math.ceil(tests.length / this.jobsCount)
    const minIndex = this.jobIndex * chunkSize
    const maxIndex = minIndex + chunkSize

    tests.forEach(test => (test.duration = time(this._getCache(test), test)))
    return tests
      .sort((testA, testB) => {
        const cacheA = this._getCache(testA)

        const cacheB = this._getCache(testB)

        const failedA = hasFailed(cacheA, testA)
        const failedB = hasFailed(cacheB, testB)
        const hasTime = testA.duration != null

        if (failedA !== failedB) {
          return failedA ? -1 : 1
          // eslint-disable-next-line eqeqeq
        } else if (hasTime != (testB.duration != null)) {
          // If only one of two tests has timing information, run it last
          return hasTime ? 1 : -1
        } else if (testA.duration != null && testB.duration != null) {
          return testA.duration < testB.duration ? 1 : -1
        } else {
          return fileSize(testA) < fileSize(testB) ? 1 : -1
        }
      })
      .slice(minIndex, maxIndex)
  }
}

module.exports = ParallelSequencer

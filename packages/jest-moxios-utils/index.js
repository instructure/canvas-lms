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

const moxios = require('moxios')

function isPromise(subject) {
  return (
    typeof subject !== 'undefined' &&
    typeof subject.then !== 'undefined' &&
    typeof subject.then === 'function'
  )
}

function moxiosWait(fn) {
  return new Promise((resolve, reject) => {
    moxios.wait(() => {
      try {
        resolve(fn(moxios.requests.mostRecent()))
      } catch (e) {
        reject(e)
      }
    })
  })
}

function moxiosRespond(response, requestPromise, opts = {}) {
  if (!isPromise(requestPromise)) throw new Error('moxiosResult requires a promise for the request')
  const waitPromise = moxiosWait(request => {
    request.respondWith({status: 200, headers: {}, response, ...opts})
  })
  return Promise.all([waitPromise, requestPromise]).then(
    ([_waitResult, requestResult]) => requestResult
  )
}

module.exports = {
  isPromise,
  moxiosWait,
  moxiosRespond
}

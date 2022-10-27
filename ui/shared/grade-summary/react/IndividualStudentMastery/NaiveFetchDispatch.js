/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

const ACTIVE_REQUEST_LIMIT = 12 // naive limit

export default class NaiveFetchDispatch {
  constructor(options = {}) {
    this.options = {
      activeRequestLimit: ACTIVE_REQUEST_LIMIT,
      ...options,
    }
    this.requests = []
  }

  get activeRequestCount() {
    // Return the count of active requests currently in the queue.
    return this.requests.filter(request => request.active).length
  }

  get nextPendingRequest() {
    // Return the first request in the queue which has not been started.
    return this.requests.find(request => !request.active)
  }

  addRequest(request) {
    this.requests.push(request)
    this.fillQueue()
  }

  clearRequest(request) {
    this.requests = this.requests.filter(r => r !== request)
    this.fillQueue()
  }

  fillQueue() {
    let nextRequest = this.nextPendingRequest
    while (nextRequest != null && this.activeRequestCount < this.options.activeRequestLimit) {
      nextRequest.start()
      nextRequest = this.nextPendingRequest
    }
  }

  fetch(...args) {
    const request = {
      active: false,
    }

    request.promise = new Promise((resolve, reject) => {
      request.resolve = resolve
      request.reject = reject
    })

    request.start = () => {
      /*
       * Update the request as "active" so that it is counted as an active
       * request in the queue and is not restarted when filling the queue.
       */
      request.active = true

      fetch(...args)
        .then(request.resolve)
        .catch(request.reject)
        .finally(() => {
          this.clearRequest(request)
        })
    }

    this.addRequest(request)

    return request.promise
  }
}

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

import $ from 'jquery'
import 'jquery.ajaxJSON'
import cheaterDepaginate from '../../../shared/CheatDepaginator'

const ACTIVE_REQUEST_LIMIT = 8 // naive limit

export default class NaiveRequestDispatch {
  constructor() {
    this.requests = []
  }

  get activeRequestCount() {
    return this.requests.reduce((sum, request) => sum + (request.started ? request.count : 0), 0)
  }

  get nextPendingRequest() {
    return this.requests.find(request => !request.started)
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
    while (nextRequest != null && this.activeRequestCount < ACTIVE_REQUEST_LIMIT) {
      nextRequest.start()
      nextRequest = this.nextPendingRequest
    }
  }

  getDepaginated(url, params, pageCallback = () => {}, pagesEnqueuedCallback = () => {}) {
    const request = {
      count: 1, // initial request
      deferred: new $.Deferred(),
      started: false
    }

    const perPage = (...args) => {
      request.count--
      return pageCallback(...args)
    }

    const allEnqueued = deferreds => {
      request.count = request.count + deferreds.length - 1 // -1 for initial request
      return pagesEnqueuedCallback(deferreds)
    }

    /* eslint-disable promise/catch-or-return */
    request.start = () => {
      request.started = true
      cheaterDepaginate(url, params, perPage, allEnqueued)
        .then((...args) => {
          this.clearRequest(request)
          request.deferred.resolve(...args)
        })
        .fail((...args) => {
          this.clearRequest(request)
          request.deferred.reject(...args)
        })
    }
    /* eslint-enable promise/catch-or-return */

    this.addRequest(request)

    return request.deferred
  }

  getJSON(url, params, resolve, reject) {
    const request = {
      count: 1,
      deferred: new $.Deferred(),
      started: false
    }

    /* eslint-disable promise/catch-or-return */
    request.start = () => {
      request.started = true
      $.ajaxJSON(url, 'GET', params, resolve, reject)
        .then((...args) => {
          this.clearRequest(request)
          request.deferred.resolve(...args)
        })
        .fail((...args) => {
          this.clearRequest(request)
          request.deferred.reject(...args)
        })
    }
    /* eslint-enable promise/catch-or-return */

    this.addRequest(request)

    return request.deferred
  }
}

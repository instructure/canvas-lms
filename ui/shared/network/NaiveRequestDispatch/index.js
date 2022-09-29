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
import '@canvas/jquery/jquery.ajaxJSON'

import cheaterDepaginate from './CheatDepaginator'

export const DEFAULT_ACTIVE_REQUEST_LIMIT = 12 // naive limit
export const MAX_ACTIVE_REQUEST_LIMIT = 100
export const MIN_ACTIVE_REQUEST_LIMIT = process.env.NODE_ENV !== 'production' ? 1 : 10

function ensureValidRequestLimit(value) {
  let cleanValue = Number.parseInt(value, 10)
  cleanValue = Number.isNaN(cleanValue) ? DEFAULT_ACTIVE_REQUEST_LIMIT : cleanValue
  cleanValue = Math.min(MAX_ACTIVE_REQUEST_LIMIT, cleanValue)
  return Math.max(MIN_ACTIVE_REQUEST_LIMIT, cleanValue)
}

export default class NaiveRequestDispatch {
  constructor(options = {}) {
    this.options = {
      ...options,
      activeRequestLimit: ensureValidRequestLimit(options.activeRequestLimit),
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

  getDepaginated(url, params, pageCallback = () => {}, pagesEnqueuedCallback = () => {}) {
    const request = {
      deferred: new $.Deferred(),
      active: false,
    }

    const allEnqueued = deferreds => {
      /*
       * The initial request to get the first page and page link headers has
       * completed, so the corresponding request object in this queue can be
       * removed. Any additional page requests will have been added to the queue
       * and will be responsible for removing themselves upon completion.
       */
      this.clearRequest(request)
      return pagesEnqueuedCallback(deferreds)
    }

    /* eslint-disable promise/catch-or-return */
    request.start = () => {
      /*
       * Update the request as "active" so that it is counted as an active
       * request in the queue and is not restarted when filling the queue.
       */
      request.active = true

      cheaterDepaginate(url, params, pageCallback, allEnqueued, this)
        .then(request.deferred.resolve)
        .fail(request.deferred.reject)
        .always(() => {
          /*
           * If there is ever a problem with the initial request, there is
           * likely a larger problem with Canvas/Gradebook or the user
           * attempting to load the page. It will not call the "pages enqueued
           * callback," and will need to be cleared here.
           */
          this.clearRequest(request)
        })
    }
    /* eslint-enable promise/catch-or-return */

    this.addRequest(request)

    return request.deferred
  }

  getJSON(url, params, resolve, reject) {
    const request = {
      deferred: new $.Deferred(),
      active: false,
    }

    /* eslint-disable promise/catch-or-return */
    request.start = () => {
      /*
       * Update the request as "active" so that it is counted as an active
       * request in the queue and is not restarted when filling the queue.
       */
      request.active = true

      $.ajaxJSON(url, 'GET', params, resolve, reject)
        .then(request.deferred.resolve)
        .fail(request.deferred.reject)
        .always(() => {
          this.clearRequest(request)
        })
    }
    /* eslint-enable promise/catch-or-return */

    this.addRequest(request)

    return request.deferred
  }
}

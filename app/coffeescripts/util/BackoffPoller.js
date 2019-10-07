//
// Copyright (C) 2011 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// AJAX Backoff poller
//
// Repeatedly do a given AJAX call until a condition is met or the max number
// of attempts has been reached. Each subsequent call will back off further and
// further.
//
// stop/continue/restart behavior is controlled by the return value of the
// handler function (just return the appropriate string).

import jQuery from 'jquery'
import 'jquery.ajaxJSON'

export default class BackoffPoller {
  constructor(url, handler, opts = {}) {
    this.url = url
    this.handler = handler
    this.baseInterval = opts.baseInterval != null ? opts.baseInterval : 1000
    this.backoffFactor = opts.backoffFactor != null ? opts.backoffFactor : 1.5
    this.maxAttempts = opts.maxAttempts != null ? opts.maxAttempts : 8
    this.handleErrors = opts.handleErrors != null ? opts.handleErrors : false
    this.initialDelay = opts.initialDelay != null ? opts.initialDelay : true
  }

  start() {
    if (this.running) {
      this.reset()
    } else {
      this.nextPoll(true)
    }
    return this
  }

  then(callback) {
    ;(this.callbacks || (this.callbacks = [])).push(callback)
  }

  reset() {
    this.nextInterval = this.baseInterval
    this.attempts = 0
  }

  stop(success = false) {
    if (this.running) clearTimeout(this.running)
    delete this.running
    if (success && this.callbacks) this.callbacks.forEach(callback => callback())
    delete this.callbacks
  }

  poll = () => {
    this.running = true
    this.attempts++
    return jQuery.ajaxJSON(this.url, 'GET', {}, this.handle, (data, xhr) =>
      this.handleErrors ? this.handle(data, xhr) : this.stop()
    )
  }

  handle = (data, xhr) => {
    switch (this.handler(data, xhr)) {
      case 'continue':
        return this.nextPoll()
      case 'reset':
        return this.nextPoll(true)
      case 'stop':
        return this.stop(true)
      default:
        return this.stop()
    }
  }

  nextPoll(reset = false) {
    if (reset) {
      this.reset()
      if (!this.initialDelay) return this.poll()
    } else {
      this.nextInterval = parseInt(this.nextInterval * this.backoffFactor, 10)
    }
    if (this.attempts >= this.maxAttempts) return this.stop()

    return (this.running = setTimeout(this.poll, this.nextInterval))
  }
}

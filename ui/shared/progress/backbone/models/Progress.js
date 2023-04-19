/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import {Model} from '@canvas/backbone'
import $ from 'jquery'

const indexOf = [].indexOf

extend(Progress, Model)

// Works with the progress API. Will poll its url until the `workflow_state`
// is completed.
//
// Has a @pollDfd object that you can use to do things when the job is
// complete.
//
// @event complete - triggered when the polling stops and the job is
// complete.

function Progress() {
  this.onPoll = this.onPoll.bind(this)
  this.poll = this.poll.bind(this)
  return Progress.__super__.constructor.apply(this, arguments)
}

Progress.prototype.defaults = {
  completion: 0,
  // The url to poll
  url: null,
  // How long after a response to fetch again
  timeout: 1000,
}

// Array of states to continue polling for progress
Progress.prototype.pollStates = ['queued', 'running']

Progress.prototype.isPolling = function () {
  const ref = this.get('workflow_state')
  return indexOf.call(this.pollStates, ref) >= 0
}

Progress.prototype.isSuccess = function () {
  return this.get('workflow_state') === 'completed'
}

Progress.prototype.initialize = function () {
  this.pollDfd = new $.Deferred()
  this.on(
    'change:url',
    (function (_this) {
      return function () {
        if (_this.isPolling()) {
          return _this.poll()
        }
      }
    })(this)
  )
  // don't try to do any ajax when we're leaving the page
  // workaround for https://code.google.com/p/chromium/issues/detail?id=263981
  return $(window).on(
    'beforeunload',
    (function (_this) {
      return function () {
        return clearTimeout(_this.timeout)
      }
    })(this)
  )
}

Progress.prototype.url = function () {
  return this.get('url')
}

// Fetches the model from the server on an interval, will trigger
// 'complete' event when finished. Returns a deferred that resolves
// when the server side job finishes
//
// @returns {Deferred}
// @api public
Progress.prototype.poll = function () {
  // eslint-disable-next-line promise/catch-or-return
  this.fetch().then(
    this.onPoll,
    (function (_this) {
      return function () {
        return _this.pollDfd.rejectWith(_this, arguments)
      }
    })(this)
  )
  return this.pollDfd
}

// Called on each poll fetch
//
// @api private
Progress.prototype.onPoll = function (response) {
  this.pollDfd.notify(response)
  if (this.isPolling()) {
    return (this.timeout = setTimeout(this.poll, this.get('timeout')))
  } else {
    this.pollDfd[this.isSuccess() ? 'resolve' : 'reject'](response)
    return this.trigger('complete')
  }
}

export default Progress

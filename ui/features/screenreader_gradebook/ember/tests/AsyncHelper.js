//
// Copyright (C) 2018 - present Instructure, Inc.
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
//

import Ember from 'ember'

export default class AsyncHelper {
  constructor() {
    this.pendingRequests = 0
  }

  start = () => {
    Ember.RSVP.configure('instrument', true)
    Ember.RSVP.on('created', this.incrementRequest)
    Ember.RSVP.on('fulfilled', this.decrementRequest)
    return Ember.RSVP.on('rejected', this.decrementRequest)
  }

  stop = () => {
    Ember.RSVP.off('created', this.incrementRequest)
    Ember.RSVP.off('fulfilled', this.decrementRequest)
    Ember.RSVP.off('rejected', this.decrementRequest)
    Ember.RSVP.configure('instrument', false)
    return (this.pendingRequests = 0)
  }

  incrementRequest = () => {
    return this.pendingRequests++
  }

  decrementRequest = () => {
    return this.pendingRequests--
  }

  waitForRequests = () => {
    return new Promise(resolve => {
      const defer = () =>
        Ember.run.later(() => {
          if (this.pendingRequests) {
            return defer()
          } else {
            return resolve()
          }
        })

      return defer()
    })
  }
}

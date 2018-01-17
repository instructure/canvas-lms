#
# Copyright (C) 2018 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

import Ember from 'ember'

export default class AsyncHelper
  constructor: () ->
    @pendingRequests = 0

  start: () =>
    Ember.RSVP.configure('instrument', true)
    Ember.RSVP.on 'created', @incrementRequest
    Ember.RSVP.on 'fulfilled', @decrementRequest
    Ember.RSVP.on 'rejected', @decrementRequest

  stop: () =>
    Ember.RSVP.off 'created', @incrementRequest
    Ember.RSVP.off 'fulfilled', @decrementRequest
    Ember.RSVP.off 'rejected', @decrementRequest
    Ember.RSVP.configure('instrument', false)
    @pendingRequests = 0

  incrementRequest: () =>
    @pendingRequests++

  decrementRequest: () =>
    @pendingRequests--

  waitForRequests: () =>
    new Promise (resolve) =>
      defer = () =>
        Ember.run.later =>
          if @pendingRequests
            defer()
          else
            resolve()

      defer()

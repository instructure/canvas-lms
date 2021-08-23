#
# Copyright (C) 2013 - present Instructure, Inc.
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

import {Model} from '@canvas/backbone'
import $ from 'jquery'

# Works with the progress API. Will poll its url until the `workflow_state`
# is completed.
#
# Has a @pollDfd object that you can use to do things when the job is
# complete.
#
# @event complete - triggered when the polling stops and the job is
# complete.

export default class Progress extends Model

  defaults:

    completion: 0

    # The url to poll
    url: null

    # How long after a response to fetch again
    timeout: 1000

  # Array of states to continue polling for progress
  pollStates: ['queued', 'running']

  isPolling: ->
    @get('workflow_state') in @pollStates

  isSuccess: ->
    @get('workflow_state') is 'completed'

  initialize: ->
    @pollDfd = new $.Deferred
    @on 'change:url', => @poll() if @isPolling()
    # don't try to do any ajax when we're leaving the page
    # workaround for https://code.google.com/p/chromium/issues/detail?id=263981
    $(window).on 'beforeunload', => clearTimeout(@timeout)

  url: ->
    @get 'url'

  # Fetches the model from the server on an interval, will trigger
  # 'complete' event when finished. Returns a deferred that resolves
  # when the server side job finishes
  #
  # @returns {Deferred}
  # @api public

  poll: =>
    @fetch().then @onPoll, =>
      @pollDfd.rejectWith this, arguments
    @pollDfd

  # Called on each poll fetch
  #
  # @api private

  onPoll: (response) =>
    @pollDfd.notify(response)
    if @isPolling()
      @timeout = setTimeout(@poll, @get('timeout'))
    else
      @pollDfd[if @isSuccess() then 'resolve' else 'reject'](response)
      @trigger 'complete'

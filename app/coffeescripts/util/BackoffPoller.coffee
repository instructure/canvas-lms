#
# Copyright (C) 2011 - present Instructure, Inc.
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

# AJAX Backoff poller
#
# Repeatedly do a given AJAX call until a condition is met or the max number
# of attempts has been reached. Each subsequent call will back off further and
# further.
#
# stop/continue/restart behavior is controlled by the return value of the
# handler function (just return the appropriate string).

define [
  'jquery'
  'jquery.ajaxJSON'
], (jQuery) ->

  class BackoffPoller
    constructor: (@url, @handler, opts={}) ->
      @baseInterval  = opts.baseInterval  ? 1000
      @backoffFactor = opts.backoffFactor ? 1.5
      @maxAttempts   = opts.maxAttempts   ? 8
      @handleErrors  = opts.handleErrors  ? false
      @initialDelay  = opts.initialDelay  ? true

    start: ->
      if @running
        @reset()
      else
        @nextPoll(true)
      this

    'then': (callback) ->
      @callbacks ?= []
      @callbacks.push callback

    reset: ->
      @nextInterval = @baseInterval
      @attempts = 0

    stop: (success=false) ->
      clearTimeout(@running) if @running
      delete @running
      callback() for callback in @callbacks if success and @callbacks
      delete @callbacks

    poll: =>
      @running = true
      @attempts++
      jQuery.ajaxJSON @url, 'GET', {}, @handle, (data, xhr) =>
        if @handleErrors
          @handle(data, xhr)
        else
          @stop()

    handle: (data, xhr) =>
      switch @handler(data, xhr)
        when 'continue'
          @nextPoll()
        when 'reset'
          @nextPoll(true)
        when 'stop'
          @stop(true)
        else
          @stop()

    nextPoll: (reset=false) ->
      if reset
        @reset()
        return @poll() if not @initialDelay
      else
        @nextInterval = parseInt(@nextInterval * @backoffFactor)
      return @stop() if @attempts >= @maxAttempts

      @running = setTimeout @poll, @nextInterval


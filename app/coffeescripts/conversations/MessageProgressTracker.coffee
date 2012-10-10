#
# Copyright (C) 2012 Instructure, Inc.
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

define [
  'i18n!conversations'
  'underscore'
  'compiled/conversations/MessageProgressBar'
  'jquery.ajaxJSON'
], (I18n, _, MessageProgressBar) ->

  class MessageProgressTracker
    constructor: (@app) ->
      @batchItems = {}
      @$list = $('#message_status')

    track: (data, deferred) ->
      item = new MessageProgressBar(this, data)
      @$list.append(item.$node)
      item.$bar.focus()

      # when the formSubmit deferred is done, we're done, unless this is a bulk
      # private message, in which case we kick of the poller/updater fu to
      # track its progress
      if deferred
        $.when(deferred).then (data, submitParam, xhr) =>
          if xhr.status is 202
            if batchId = xhr.getResponseHeader('X-Conversation-Batch-Id')
              @batchItems[batchId] = item
            @batchPoller() unless @polling
          else
            item.complete()
        , (data) =>
          if data.isRejected?() # e.g. refreshed the page, thus aborting the request
            item.complete()
          else
            error = if data[0]?.attribute is 'recipients' and data[0].message is 'invalid'
              I18n.t('recipient_error', 'The course or group you have selected has no valid recipients')
            else
              I18n.t('unspecified_error', 'An unexpected error occurred, please try again')
            item.error(error)

      item

    batchPoller: =>
      @polling = true
      $.ajaxJSON '/conversations/batches', 'GET', {}, (data) =>
        @updateItems(data)
        if data.length > 0
          setTimeout(@batchPoller, 3000)
        else
          @polling = false

    updateItems: (data) ->
      dataHash = _.reduce(data, (h, i) ->
        h[i.id] = i
        h
      , {})
      for id, data of dataHash
        @batchItems[id]?.update(data) ? @batchItems[id] = @track(data)

      # remove stuff that has finished
      completed = for id, item of @batchItems when not dataHash[id]
        item.complete()
        delete @batchItems[id]
      if completed.length
        @app.updateView(true)

    height: ->
      @$list.outerHeight(true)

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
  'jst/conversations/MessageProgressBarText'
  'compiled/str/TextHelper'
  'jquery.ajaxJSON'
], (I18n, _, messageProgressBarTextTemplate, {truncateText}) ->

  class MessageProgressBar
    constructor: (@tracker, @data) ->
      @$node = $('<li class="progress-bar" />')
      messageId = _.uniqueId('progress_')
      @$message = $('<span />', id: messageId)
      @$bar = $('<div />',
        tabIndex: -1
        role: 'progressbar'
        'aria-valuemin': 0
        'aria-valuemax': 1
        'aria-valuenow': @data.completion
        'aria-describedby': messageId
      )
      @$completion = $('<b />').appendTo(@$bar)
      @$node.append(@$message, @$bar)
      @update(@data)

    update: (@data) ->
      @data.status = if @data.error
        'error'
      else if @data.completion?
        if @data.completion is 1 then 'complete' else 'determinate'
      else
        'indeterminate'
      @data.num_people = I18n.t('people_count', 'person', {count: @data.recipient_count})
      @data.message_preview = truncateText(@data.message.body, max: 20)

      @$node.attr('class', "progress-bar progress-bar-#{@data.status}")
      @$message.html messageProgressBarTextTemplate(@data)
      @$message.attr title: @data.message_preview
      @$bar.showIf(@data.status isnt 'error')
      percent = parseInt(100 * (@data.completion ? 0)) + "%"
      @$bar.attr('aria-valuenow', @data.completion)
      @$completion.css width: percent

    error: (error) ->
      @update _.extend(@data, error: error, completion: 1)
      @destroy()

    complete: () ->
      @update _.extend(@data, completion: 1)
      @destroy()

    destroy: () ->
      setTimeout =>
        @$node.fadeTo('fast', 0).animate(width: 0, 'fast', => @$node.remove())
      , 5000
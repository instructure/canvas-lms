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
  'jquery'
  'underscore'
  'compiled/util/shortcut'
  'compiled/conversations/MessageForm'
  'compiled/conversations/MessageProgressTracker'
  'compiled/fn/preventDefault'
], (I18n, $, _, shortcut, MessageForm, MessageProgressTracker, preventDefault) ->

  class MessageFormPane
    shortcut this, 'form',
      'refresh'
      'toggle'
      'resetForParticipant'
    shortcut this, 'app',
      'resize'

    constructor: (@app, @formOptions) ->
      @$node = $('#create_message_form')
      @initializeActions()
      @tracker = new MessageProgressTracker(@app)
      @tracker.batchPoller()

    height: ->
      (@form?.height() ? 0) + @tracker.height()

    reset: (@options) ->
      @form?.destroy()
      @form = new MessageForm(this, @app.canAddNotesFor, _.defaults(@options, @formOptions))
      @$node.append(@form.$form)
      @app.addedMessageForm(@form.$form)
      @form.initialize()

    initializeActions: ->
      @$node.click => @app.toggleMessageActions off

      @$node.on 'click', '.action_add_attachment', preventDefault =>
        @form.addAttachment()
      @$node.on 'click', '.attachment a.remove_link', preventDefault (e) =>
        @form.removeAttachment($(e.currentTarget))

      @$node.on 'click', '.action_media_comment', preventDefault =>
        @form.addMediaComment()
      @$node.on 'click', '.media_comment a.remove_link', preventDefault =>
        @form.removeMediaComment()

      @$node.on 'click', '.action_add_recipients', preventDefault (e) =>
        @app.addRecipients($(e.currentTarget))

    addingMessage: (data, deferred) ->
      @reset(@options)
      @tracker.track(data, deferred)

      $.when(deferred).then (data) =>
        data = [data] unless data.length?
        @app.updatedConversation(data)


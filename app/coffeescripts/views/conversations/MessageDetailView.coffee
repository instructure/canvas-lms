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

define [
  'i18n!conversations'
  'jquery'
  'underscore'
  'Backbone'
  '../../models/Message'
  '../conversations/MessageItemView'
  'jst/conversations/messageDetail'
  'jst/conversations/noMessage'
], (I18n, $, _, {View}, Message, MessageItemView, template, noMessage) ->

  class MessageDetailView extends View
    events:
      'click .message-detail-actions .reply-btn':         'onReply'
      'click .message-detail-actions .reply-all-btn':     'onReplyAll'
      'click .message-detail-actions .delete-btn':        'onDelete'
      'click .message-detail-actions .forward-btn':       'onForward'
      'click .message-detail-actions .archive-btn':       'onArchive'
      'click .message-detail-actions .star-toggle-btn':   'onStarToggle'
      'modelChange':              'onModelChange'
      'changed:starred':          'render'

    tagName: 'div'

    messages:
      star: I18n.t('star', 'Star')
      unstar: I18n.t('unstar', 'Unstar')
      archive: I18n.t('archive', 'Archive')
      unarchive: I18n.t('unarchive', 'Unarchive')

    render: (options = {})->
      super
      if @model
        context   = @model.toJSON().conversation
        context.starToggleMessage = if @model.starred() then @messages['unstar'] else @messages['star']
        context.archiveToggleMessage = if @model.get('workflow_state') == 'archived' then @messages['unarchive'] else @messages['archive']
        $template = $(template(context))
        @model.messageCollection.each (message) =>
          message.set('conversation_id', context.id) unless message.get('conversation_id')
          message.set('cannot_reply', context.cannot_reply) if context.cannot_reply
          childView = new MessageItemView(model: message).render()
          $template.find('.message-content').append(childView.$el)
          @listenTo(childView, 'reply',     => @trigger('reply', message, ".message-item-view[data-id=#{message.id}] .reply-btn"))
          @listenTo(childView, 'reply-all', => @trigger('reply-all', message, ".message-item-view[data-id=#{message.id}] .al-trigger"))
          @listenTo(childView, 'forward',   => @trigger('forward', message, ".message-item-view[data-id=#{message.id}] .al-trigger"))
      else
        $template = noMessage(options)
      @$el.html($template)

      @$archiveToggle = @$el.find('.archive-btn')
      @$starToggle = @$el.find('.star-toggle-btn')
      this

    onModelChange: (newModel) ->
      @detachModelEvents()
      @model = newModel
      @attachModelEvents()

    detachModelEvents: () ->
      @model.off(null, null, this) if @model

    attachModelEvents: () ->
      @model.on("change:starred change:workflow_state", _.debounce(@updateLabels, 90), this) if @model

    updateLabels: ->
      return unless @model
      @$starToggle.text(if @model.starred() then @messages['unstar'] else @messages['star'])
      @$archiveToggle.text(if @model.get('workflow_state') == 'archived' then @messages['unarchive'] else @messages['archive'])

    onStarToggle: (e) ->
      e.preventDefault()
      @$el.find('.message-detail-kyle-menu').focus()
      @trigger('star-toggle')

    onReply: (e) ->
      e.preventDefault()
      @trigger('reply', null, '.message-detail-actions .reply-btn')

    onReplyAll: (e) ->
      e.preventDefault()
      @trigger('reply-all', null, '.message-detail-actions .al-trigger')

    onForward: (e) ->
      e.preventDefault()
      @trigger('forward', null, '.message-detail-actions .al-trigger')

    onDelete: (e) ->
      e.preventDefault()
      @trigger('delete', '.conversations .message-actions:last .star-btn', '.message-detail-actions .al-trigger')

    onArchive: (e) ->
      e.preventDefault()
      @trigger('archive', '.conversations .message-actions:last .star-btn', '.message-detail-actions .al-trigger')

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
  'compiled/util/shortcut'
  'jst/conversations/MessageForm'
  'jst/conversations/addAttachment'
], (I18n, _, shortcut, messageFormTemplate, addAttachmentTemplate) ->

  class MessageForm
    shortcut this, 'pane',
      'resize'

    constructor: (@pane, @canAddNotesFor, @options) ->
      @$form = $(messageFormTemplate(@options))
      @$mediaComment = @$form.find('.media_comment')
      @$mediaCommentId = @$form.find("input[name=media_comment_id]")
      @$mediaCommentType = @$form.find("input[name=media_comment_type]")
      @$addMediaComment = @$form.find(".action_media_comment")
      @$attachments = @$form.find('.attachment_list')

    initialize: ->
      if @tokenInput = @$form.find('.recipients').data('token_input')
        # since it doesn't infer percentage widths, just whatever the current pixels are
        @tokenInput.$fakeInput.css('width', '100%')
        if @options.user_id
          query = { user_id: @options.user_id, from_conversation_id: @options.from_conversation_id }
          $.ajaxJSON @tokenInput.selector.url, 'GET', query, (data) =>
            if data.length
              @tokenInput.addToken
                value: data[0].id
                text: data[0].name
                data: data[0]

      @initializeActions()
      if !$(document.activeElement).filter(':input').length and window.location.hash isnt ''
        @$form.find(':input:visible:first').focus()

    initializeActions: ->
      if @tokenInput
        @tokenInput.change = @recipientIdsChanged

      @$form.formSubmit
        fileUpload: => (@$form.find(".file_input:visible").length > 0)
        preparedFileUpload: true
        context_code: "user_" + ENV.current_user_id
        folder_id: @options.folderId
        intent: 'message'
        formDataTarget: 'url'
        disableWhileLoading: true
        required: ['body']
        property_validations:
          token_capture: => I18n.t('errors.field_is_required', "This field is required") if @tokenInput and !@tokenInput.tokenValues().length
        handle_files: (attachments, data) ->
          data.attachment_ids = (a.attachment.id for a in attachments)
          data
        onSubmit: (@request, data) =>
          @pane.addingMessage(@messageData(data), @request)

    recipientIdsChanged: (recipientIds) =>
      if recipientIds.length > 1 or recipientIds[0]?.match(/^(course|group)_/)
        @toggleOptions(user_note: off, group_conversation: on)
      else
        @toggleOptions(user_note: @canAddNotesFor(recipientIds[0]), group_conversation: off)
      @resize()

    addAttachment: ->
      $attachment = $(addAttachmentTemplate())
      @$attachments.append($attachment)
      $attachment.slideDown "fast", => @resize() # shortcuts aren't bound to instance, so this don't "optimize" this :P

    removeAttachment: ($node) ->
      $attachment = $node.closest(".attachment")
      $attachment.slideUp "fast", =>
        @resize()
        $attachment.remove()

    addMediaComment: ->
      @$mediaComment.mediaComment 'create', 'any', (id, type) =>
        @$mediaCommentId.val(id)
        @$mediaCommentType.val(type)
        @$mediaComment.show()
        @$addMediaComment.hide()

    removeMediaComment: ->
      @$mediaCommentId.val('')
      @$mediaCommentType.val('')
      @$mediaComment.hide()
      @$addMediaComment.show()

    messageData: (data) ->
      numRecipients = if @options.conversation
        Math.max(@options.conversation.get('audience').length, 1)
      else
        # note: this number may be high, if users appear in multiple of the
        # specified recipient contexts. there's no way of knowing without going
        # to the server first, which is what we're trying to avoid.
        _.reduce @tokenInput.$tokens.find('input[name="recipients[]"]'),
          (memo, node) -> memo + ($(node).closest('li').data('user_count') ? 1),
          0
      {recipient_count: numRecipients, message: {body: data.body}}

    resetForParticipant: (user) ->
      @toggleOptions(user_note: on) if @canAddNotesFor(user)

    toggleOptions: (options) ->
      for key, enabled of options
        $node = @$form.find(".#{key}_info")
        $node.showIf(enabled)
        $node.find("input[name=#{key}]").prop('checked', false) unless enabled

    toggle: (state) ->
      @$form[if state then 'addClass' else 'removeClass']('disabled')

    height: ->
      @$form.outerHeight(true)

    refresh: (audienceHtml) ->
      @$form.find('.audience').html audienceHtml
      @resize()

    destroy: ->
      @$form.hideErrors()
      @$form.css(position: 'absolute', zIndex: -1)
      $.when(@request).then => @$form.remove()

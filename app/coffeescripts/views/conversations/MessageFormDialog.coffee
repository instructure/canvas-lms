#
# Copyright (C) 2013 Instructure, Inc.
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
  'i18n!conversation_dialog'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/DialogBaseView'
  'jst/conversations/MessageFormDialog'
  'compiled/fn/preventDefault'
  'jst/conversations/composeTitleBar'
  'jst/conversations/composeButtonBar'
  'jst/conversations/addAttachment'
  'compiled/models/Message'
  'compiled/views/conversations/AutocompleteView'
  'compiled/views/conversations/CourseSelectionView'
  'compiled/views/conversations/ContextMessagesView'
  'compiled/widget/ContextSearch'
  'vendor/jquery.elastic'
], (I18n, $, _, {Collection}, DialogBaseView, template, preventDefault, composeTitleBarTemplate, composeButtonBarTemplate, addAttachmentTemplate, Message, AutocompleteView, CourseSelectionView, ContextMessagesView) ->

  ##
  # reusable message composition dialog
  class MessageFormDialog extends DialogBaseView

    template: template

    els:
      '.message_course':                '$messageCourse'
      '.message_course_ro':             '$messageCourseRO'
      'input[name=context_code]':       '$contextCode'
      '.message_subject':               '$messageSubject'
      '.message_subject_ro':            '$messageSubjectRO'
      '.context_messages':              '$contextMessages'
      '.media_comment':                 '$mediaComment'
      'input[name=media_comment_id]':   '$mediaCommentId'
      'input[name=media_comment_type]': '$mediaCommentType'
      '.ac':                            '$recipients'
      '.attachment_list':               '$attachments'
      '.attachments-pane':              '$attachmentsPane'
      '.message-body':                  '$messageBody'
      '.conversation_body':             '$conversationBody'
      '.compose_form':                  '$form'
      '.user_note':                     '$userNote'
      '.user_note_info':                '$userNoteInfo'

    messages:
      flashSuccess: I18n.t('message_sent', 'Message sent!')

    dialogOptions: ->
      id: 'compose-new-message'
      autoOpen: false
      minWidth: 550
      width: 700
      minHeight: 500
      height: 550
      resizable: true
      # Event handler for catching when the dialog is closed.
      # Overridding @close() or @cancel() doesn't work alone since
      # hitting ESC doesn't trigger either of those events.
      close: =>
        @afterClose()
      resize: =>
        @resizeBody()
        @_limitContentSize()
      buttons: [
        text: I18n.t '#buttons.cancel', 'Cancel'
        click: @cancel
      ,
        text: I18n.t '#buttons.send', 'Send'
        'class' : 'btn-primary send-message'
        'data-track-category': "Compose Message"
        'data-track-action'  : "Edit"
        'data-track-label'   : "Send"
        click: (e) => @sendMessage(e)
      ]

    show: (model, options) ->
      if @model = model
        @message = options?.message || @model.messageCollection.at(0)
      @to            = options?.to
      @returnFocusTo = options.trigger if options.trigger
      @launchParams = _.pick(options, 'context', 'user') if options.remoteLaunch

      @render()
      super
      @initializeForm()
      @resizeBody()

    # this method handles a layout bug with jqueryUI that occurs when you
    # attempt to resize the modal beyond the viewport.
    _limitContentSize: ->
      @$el.width('100%') if @$el.width() > @$fullDialog.width()

    ##
    # detach events that were dynamically added when the dialog is closed.
    afterClose: ->
      @$fullDialog.off 'click', '.message-body'
      @$fullDialog.off 'click', '.attach-file'
      @$fullDialog.off 'click', '.attachment .remove_link'
      @$fullDialog.off 'keydown', '.attachment'
      @$fullDialog.off 'click', '.attachment'
      @$fullDialog.off 'dblclick', '.attachment'
      @$fullDialog.off 'change', '.file_input'
      @$fullDialog.off 'click', '.attach-media'
      @$fullDialog.off 'click', '.media-comment .remove_link'
      @trigger('close')
      if @returnFocusTo
        @returnFocusTo.focus()
        delete @returnFocusTo

    sendMessage: (e) ->
      e.preventDefault()
      e.stopPropagation()
      @removeEmptyAttachments()
      @$form.submit()

    initialize: ->
      super
      @$fullDialog = @$el.closest('.ui-dialog')
      # Customize titlebar
      $titlebar = @$fullDialog.find('.ui-dialog-titlebar')
      $closeBtn = $titlebar.find('.ui-dialog-titlebar-close')
      $closeBtn.html composeTitleBarTemplate()

      # add custom class to dialog container for
      @$fullDialog.addClass('compose-message-dialog')

      # add attachment and media buttons to bottom bar
      @$fullDialog.find('.ui-dialog-buttonpane').prepend composeButtonBarTemplate()

      @$addMediaComment = @$fullDialog.find('.attach-media')

    prepareTextarea: ($scope) ->
      $textArea = $scope.find('textarea')
      $textArea.elastic()

    onCourse: (course) =>
      @recipientView.setContext(course, true)
      @$contextCode.val(if course?.id then course.id else '')
      @$messageCourseRO.text(if course then course.name else I18n.t('no_course','No course'))

    defaultCourse: null
    setDefaultCourse: (course) ->
      @defaultCourse = course

    initializeForm: ->
      @prepareTextarea(@$el)
      @recipientView = new AutocompleteView(
        el: @$recipients
        disabled: @model?.get('private')
      ).render()
      @recipientView.on('changeToken', @recipientIdsChanged)

      @$messageCourse.prop('disabled', !!@model)
      @courseView = new CourseSelectionView(
        el: @$messageCourse,
        courses: @options.courses,
        defaultOption: I18n.t('select_course', 'Select course')
      )
      @courseView.on('course', @onCourse)
      if @model
        if @model.get('context_code')
          @courseView.setValue(@model.get('context_code'))
        else
          @courseView.setValue("course_" + _.keys(@model.get('audience_contexts').courses)[0])
      else if @launchParams
        @courseView.setValue(@launchParams.context) if @launchParams.context
      else
        @courseView.setValue(@defaultCourse)
      if @model
        @courseView.$picker.css('display', 'none')
        @recipientView.$input.focus()
      else
        @$messageCourseRO.css('display', 'none')
        @courseView.focus()

      if @tokenInput = @$el.find('.recipients').data('token_input')
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

      if @to && @to != 'forward' && @message
        tokens = [] 
        tokens.push(@message.get('author'))
        if @to == 'replyAll' || ENV.current_user_id == @message.get('author').id
          tokens = tokens.concat(@message.get('participants'))
          if tokens.length > 1
            tokens = _.filter(tokens, (t) -> t.id != ENV.current_user_id)
        @recipientView.setTokens(tokens)

      @recipientView.setTokens([@launchParams.user]) if @launchParams

      if @model
        @$messageSubject.css('display', 'none')
        @$messageSubject.prop('disabled', true)
      else
        @$messageSubjectRO.css('display', 'none')
      if @model?.get('subject')
        @$messageSubject.val(@model.get('subject'))
        @$messageSubjectRO.text(@model.get('subject'))

      if messages = @model?.messageCollection
        # include only messages which
        #   1) are older than @message
        #   2) have as participants a superset of the participants of @message
        date = new Date(@message.get('created_at'))
        participants = @message.get('participating_user_ids')
        includedMessages = new Collection messages.filter (m) ->
          new Date(m.get('created_at')) <= date &&
            !_.find(participants, (p) -> !_.contains(m.get('participating_user_ids'), p))
        contextView = new ContextMessagesView(el: @$contextMessages, collection: includedMessages)
        contextView.render()

      @$fullDialog.on 'click', '.message-body', @handleBodyClick
      @$fullDialog.on 'click', '.attach-file', preventDefault =>
        @addAttachment()
      @$fullDialog.on 'click', '.attachment .remove_link', preventDefault (e) =>
        @removeAttachment($(e.currentTarget))
      @$fullDialog.on 'keydown', '.attachment', @handleAttachmentKeyDown
      @$fullDialog.on 'click', '.attachment', @handleAttachmentClick
      @$fullDialog.on 'dblclick', '.attachment', @handleAttachmentDblClick
      @$fullDialog.on 'change', '.file_input', @handleAttachment

      @$fullDialog.on 'click', '.attach-media', preventDefault =>
        @addMediaComment()
      @$fullDialog.on 'click', '.media_comment .remove_link', preventDefault (e) =>
        @removeMediaComment($(e.currentTarget))
      @$addMediaComment[if !!INST.kalturaSettings then 'show' else 'hide']()

      @$form.formSubmit
        fileUpload: => (@$fullDialog.find(".attachment_list").length > 0)
        files: => (@$fullDialog.find(".file_input")) 
        preparedFileUpload: true
        context_code: "user_" + ENV.current_user_id
        folder_id: @options.folderId
        intent: 'message'
        formDataTarget: 'url'
        disableWhileLoading: true
        required: ['body']
        property_validations:
          token_capture: => I18n.t('errors.field_is_required', "This field is required") if @recipientView and !@recipientView.tokens.length
        handle_files: (attachments, data) ->
          data.attachment_ids = (a.attachment.id for a in attachments)
          data
        processData: (formData) =>
          unless formData.context_code
            formData.context_code = @options.account_context_code
          formData
        onSubmit: (@request, submitData) =>
          # close dialog after submitting the message
          dfd = $.Deferred()
          @trigger('submitting', dfd)
          @close()
          # update conversation when message confirmed sent
          # TODO: construct the new message object and pass it to the MessageDetailView which will need to create a MessageItemView for it
          # store @to for the closure in case there are multiple outstanding send requests
          localTo = @to
          @to = null
          $.when(@request).then (response) =>
            dfd.resolve()
            $.flashMessage(@messages.flashSuccess)
            if localTo
              message = response.messages[0]
              message.author =
                name: ENV.current_user.display_name
                avatar_url: ENV.current_user.avatar_image_url
              message = new Message(response, parse: true)
              @trigger('addMessage', message.toJSON().conversation.messages[0], response)
            else
              @trigger('newConversations', response)

    recipientIdsChanged: (recipientIds) =>
      if recipientIds.length > 1 or recipientIds[0]?.match(/^(course|group)_/)
        @toggleUserNote(false)
      else
        @toggleUserNote(@canAddNotesFor(@recipientView.tokenModels()[0]))
      @resizeBody()

    canAddNotesFor: (user) =>
      return false unless ENV.CONVERSATIONS.NOTES_ENABLED
      return false unless user?
      for id, roles of user.get('common_courses')
        return true if 'StudentEnrollment' in roles and
          (ENV.CONVERSATIONS.CAN_ADD_NOTES_FOR_ACCOUNT or ENV.CONVERSATIONS.CONTEXTS.courses[id]?.permissions?.manage_user_notes)
      false

    toggleUserNote: (state) ->
      @$userNoteInfo.toggle(state)
      @$userNote.prop('checked', false)

    resizeBody: =>
      @updateAttachmentOverflow()
      # Compute desired height of body
      @$messageBody.height( (@$el.offset().top + @$el.height()) - @$messageBody.offset().top - @$attachmentsPane.height())

    attachmentsShouldOverflow: ->
      $attachments = @$attachments.children()
      ($attachments.length * $attachments.outerWidth()) > @$attachmentsPane.width()

    addAttachment: ->
      $attachment = $(addAttachmentTemplate())
      @$attachments.append($attachment)
      $attachment.hide()
      $attachment.find('input').click()
      @updateAttachmentOverflow()
      @focusAddAttachment()

    setAttachmentClip: ($attachment) ->
      $name = $attachment.find( $('.attachment-name') )
      $clip = $attachment.find( $('.attachment-name-clip') )
      $clip.height( $name.height() )
      $clip.addClass('hidden') if $name.height() < 35

    imageTypes: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg']

    handleBodyClick: (e) =>
      @$conversationBody.focus() if e.target == e.currentTarget

    handleAttachmentClick: (e) =>
      # IE doesn't do this automatically
      $(e.currentTarget).focus()

    handleAttachmentDblClick: (e) =>
      $(e.currentTarget).find('input').click()

    handleAttachment: (e) =>
      input = e.currentTarget
      $attachment = $(input).closest('.attachment')
      @updateAttachmentPane()
      if !input.value
        $attachment.hide()
        return
      $attachment.slideDown "fast"
      $icon = $attachment.find('.attachment-icon i')
      $icon.empty()
      file = input.files[0]
      name = file.name
      $attachment.find('.attachment-name').text(name)
      @setAttachmentClip($attachment)
      remove = $attachment.find('.remove_link')
      remove.attr('aria-label', remove.attr('title')+': '+name)
      extension = name.split('.').pop().toLowerCase()
      if extension in @imageTypes && window.FileReader
        picReader = new FileReader()
        picReader.addEventListener("load", (e) ->
          picFile = e.target
          $icon.attr('class', '')
          $icon.append($('<img />').attr('src', picFile.result))
        )
        picReader.readAsDataURL(file)
        return
      icon = 'paperclip'
      if extension in @imageTypes then icon = 'image'
      else if extension == 'pdf' then icon = 'pdf'
      else if extension in ['doc', 'docx'] then icon = 'ms-word'
      else if extension in ['xls', 'xlsx'] then icon = 'ms-excel'
      $icon.attr('class', "icon-#{icon}")

    handleAttachmentKeyDown: (e) =>
      if e.keyCode == 37 # left
        return @focusPrevAttachment($(e.currentTarget))
      if e.keyCode == 39 # right
        return @focusNextAttachment($(e.currentTarget))
      if (e.keyCode == 13 || e.keyCode == 32) && !$(e.target).hasClass('remove_link') # enter, space
        @handleAttachmentDblClick(e)
        return false
      # delete, "d", enter, space
      if e.keyCode != 46 && e.keyCode != 68 && e.keyCode != 13 && e.keyCode != 32
        return
      @removeAttachment(e.currentTarget)
      return false

    removeEmptyAttachments: ->
      _.each(@$attachments.find('input[value=]'), @removeAttachment)

    removeAttachment: (node) =>
      $attachment = $(node).closest(".attachment")

      if !@focusNextAttachment($attachment)
        if !@focusPrevAttachment($attachment)
          @focusAddAttachment()

      $attachment.slideUp "fast", =>
        $attachment.remove()
        @updateAttachmentPane()

    focusPrevAttachment: ($attachment) =>
      $newTarget = $attachment.prevAll(':visible').first()
      if !$newTarget.length then return false
      $newTarget.focus()

    focusNextAttachment: ($attachment) =>
      $newTarget = $attachment.nextAll(':visible').first()
      if !$newTarget.length then return false
      $newTarget.focus()

    focusAddAttachment: () ->
      @$fullDialog.find('.attach-file').focus()

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

    updateAttachmentOverflow: ->
      @$attachmentsPane.toggleClass('overflowed', @attachmentsShouldOverflow())

    updateAttachmentPane: ->
      @$attachmentsPane[if @$attachmentsPane.find('input:not([value=])').length then 'addClass' else 'removeClass']('has-items')
      @resizeBody()

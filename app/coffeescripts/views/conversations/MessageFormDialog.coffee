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
#

define [
  'i18n!conversation_dialog'
  'jquery'
  'underscore'
  'Backbone'
  '../DialogBaseView'
  'jst/conversations/MessageFormDialog'
  '../../fn/preventDefault'
  'jst/conversations/composeTitleBar'
  'jst/conversations/composeButtonBar'
  'jst/conversations/addAttachment'
  '../../models/Message'
  '../conversations/AutocompleteView'
  '../conversations/CourseSelectionView'
  '../conversations/ContextMessagesView'
  'jquery.elastic'
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
      '#bulk_message':                  '$bulkMessage'
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
      title: I18n.t 'Compose Message'
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
        'data-text-while-loading' : I18n.t('Sending...')
        click: (e) => @sendMessage(e)
      ]

    show: (model, options) ->
      if @model = model
        @message = options?.message || @model.messageCollection.at(0)
      @to            = options?.to
      @returnFocusTo = options.trigger if options.trigger
      @launchParams = _.pick(options, 'context', 'user') if options.remoteLaunch

      @render()
      @appendAddAttachmentTemplate()

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

      @launchParams = null

      @trigger('close')
      if @returnFocusTo
        $(@returnFocusTo).focus()
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
      @$fullDialog.find('.ui-dialog-buttonpane').prepend composeButtonBarTemplate({isIE10: INST.browser.ie10})

      @$addMediaComment = @$fullDialog.find('.attach-media')

    prepareTextarea: ($scope) ->
      $textArea = $scope.find('textarea')
      $textArea.elastic()

    onCourse: (course) =>
      @recipientView.setContext(course, true)
      if course?.id
        @$contextCode.val(course.id)
        @recipientView.disable(false)
      else
        @$contextCode.val('')
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
      @recipientView.on('recipientTotalChange', @recipientTotalChanged)

      unless ENV.CONVERSATIONS.CAN_MESSAGE_ACCOUNT_CONTEXT
        @$messageCourse.attr('aria-required', true)
        @recipientView.disable(true)

      @$messageCourse.prop('disabled', !!@model)
      @courseView = new CourseSelectionView(
        el: @$messageCourse,
        courses: @options.courses,
        defaultOption: I18n.t('select_course', 'Select course')
        messageableOnly: true
      )
      if @model
        if @model.get('context_code')
          @onCourse({id: @model.get('context_code'), name: @model.get('context_name')})
        else
          @courseView.on('course', @onCourse)
          @courseView.setValue("course_" + _.keys(@model.get('audience_contexts').courses)[0])
        @recipientView.disable(false)
      else if @launchParams
        @courseView.on('course', @onCourse)
        @courseView.setValue(@launchParams.context) if @launchParams.context
        @recipientView.disable(false)
      else
        @courseView.on('course', @onCourse)
        @courseView.setValue(@defaultCourse)
      if @model
        @courseView.$picker.css('display', 'none')
      else
        @$messageCourseRO.css('display', 'none')

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
      @$fullDialog.on 'click', '.attach-file', =>
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
        required: ['body']
        property_validations:
          token_capture: => I18n.t("Invalid recipient name.") if @recipientView and !@recipientView.tokens.length
        handle_files: (attachments, data) ->
          data.attachment_ids = (a.id for a in attachments)
          data
        processData: (formData) =>
          formData.context_code ||= @launchParams?.context || @options.account_context_code
          formData
        onSubmit: (@request, submitData) =>
          dfd = $.Deferred()
          $(@el).parent().disableWhileLoading(dfd, buttons: ['[data-text-while-loading] .ui-button-text']);
          @trigger('submitting', dfd)
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
            @close() # close after DOM has been updated, so focus is properly restored
            # also don't close the dialog on failure, so the user's typed message isn't lost
          $.when(@request).fail ->
            dfd.reject()

    recipientIdsChanged: (recipientIds) =>
      if (_.isEmpty(recipientIds) || _.contains(recipientIds, /(teachers|tas|observers)$/))
        @toggleUserNote(false)
      else
        canAddNotes = _.map @recipientView.tokenModels(), (tokenModel) =>
          @canAddNotesFor(tokenModel)
        @toggleUserNote(_.every(canAddNotes))

    recipientTotalChanged: (lockBulkMessage) =>
      if lockBulkMessage && !@bulkMessageLocked
        @oldBulkMessageVal = @$bulkMessage.prop('checked')
        @$bulkMessage.prop('checked', true)
        @$bulkMessage.prop('disabled', true)
        @bulkMessageLocked = true
      else if !lockBulkMessage && @bulkMessageLocked
        @$bulkMessage.prop('checked', @oldBulkMessageVal)
        @$bulkMessage.prop('disabled', false)
        @bulkMessageLocked = false

    canAddNotesFor: (user) =>
      return false unless ENV.CONVERSATIONS.NOTES_ENABLED
      return false unless user?
      return true if(user.id.match(/students$/) || user.id.match(/^group/))
      for id, roles of user.get('common_courses')
        return true if 'StudentEnrollment' in roles and
          (ENV.CONVERSATIONS.CAN_ADD_NOTES_FOR_ACCOUNT or ENV.CONVERSATIONS.CAN_ADD_NOTES_FOR_COURSES[id])
      false

    toggleUserNote: (state) ->
      @$userNoteInfo.toggle(state)
      @$userNote.prop('checked', false) if state == false
      @resizeBody()

    resizeBody: =>
      @updateAttachmentOverflow()
      # Compute desired height of body
      @$messageBody.height( (@$el.offset().top + @$el.height()) - @$messageBody.offset().top - @$attachmentsPane.height())

    attachmentsShouldOverflow: ->
      $attachments = @$attachments.children()
      ($attachments.length * $attachments.outerWidth()) > @$attachmentsPane.width()

    addAttachment: ->
      $('#file_input').attr('id', _.uniqueId('file_input'))
      @appendAddAttachmentTemplate()
      @updateAttachmentOverflow()

      # Hacky crazyness for ie10.
      # If you try to use javascript to 'click' on a file input element,
      # when you go to submit the form it will give you an "access denied" error.
      # So, for IE10, we make the paperclip icon a <label>  that references the input it automatically open the file input.
      # But making it a <label> makes it so you can't tab to it. so for everyone else me make it a <button> and open the file
      # input dialog with a javascript "click"
      if INST.browser.ie10
        @focusAddAttachment()
      else
        @$fullDialog.find('.file_input:last').click()

    appendAddAttachmentTemplate: ->
      $attachment = $(addAttachmentTemplate())
      @$attachments.append($attachment)
      $attachment.hide()

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

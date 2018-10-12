#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'jst/conversations/SubmissionCommentFormDialog'
  '../../fn/preventDefault'
  'jst/conversations/composeTitleBar'
  'jst/conversations/composeButtonBar'
  '../../models/Message'
  '../conversations/AutocompleteView'
  '../conversations/CourseSelectionView'
  '../conversations/ContextMessagesView'
  'jquery.elastic'
], (I18n, $, _, {Collection}, DialogBaseView, template, preventDefault, composeTitleBarTemplate, composeButtonBarTemplate, Message, AutocompleteView, CourseSelectionView, ContextMessagesView) ->

  ##
  # reusable message composition dialog
  class SubmissionCommentFormDialog extends DialogBaseView

    template: template

    els:
      '.message-body':                  '$messageBody'
      '.reply_body':                    '$replyBody'
      '.reply_form':                    '$form'

    messages:
      flashSuccess: I18n.t('message_sent', 'Message sent!')

    dialogOptions: ->
      title: ''
      id: 'submission-comment-reply'
      autoOpen: false
      minWidth: 400
      width: 650
      minHeight: 350
      height: 400
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
      @model = model
      @dialog.dialog('option', 'title', @model.get('subject'))
      @returnFocusTo = options.trigger if options.trigger

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
      @trigger('close')
      if @returnFocusTo
        @returnFocusTo.focus()
        delete @returnFocusTo

    sendMessage: (e) ->
      e.preventDefault()
      e.stopPropagation()
      @$form.submit()

    initialize: ->
      super
      @$fullDialog = @$el.closest('.ui-dialog')
      # Customize titlebar
      $titlebar = @$fullDialog.find('.ui-dialog-titlebar')
      $closeBtn = $titlebar.find('.ui-dialog-titlebar-close')
      $closeBtn.html composeTitleBarTemplate()

      # add custom class to dialog container for
      @$fullDialog.addClass('submission-comment-reply-dialog')

    prepareTextarea: ($scope) ->
      $textArea = $scope.find('textarea')
      $textArea.elastic()

    initializeForm: ->
      @prepareTextarea(@$el)

      @$fullDialog.on 'click', '.message-body', @handleBodyClick

      @$form.formSubmit
        intent: 'message'
        formDataTarget: 'url'
        disableWhileLoading: true
        required: ['comment[text_comment]']
        onSubmit: (@request, submitData) =>
          # close dialog after submitting the message
          dfd = $.Deferred()
          @trigger('submitting', dfd)
          @close()
          $.when(@request).then (response) =>
            dfd.resolve()
            $.flashMessage(@messages.flashSuccess)
            message = new Message(_.extend(@model.attributes, {submission_comments: response.submission_comments}), parse: true)
            @trigger('addMessage', message.get('messages')[0], response)
          $.when(@request).fail ->
            dfd.reject()

    resizeBody: =>
      # Compute desired height of body
      @$messageBody.height( (@$el.offset().top + @$el.height()) - @$messageBody.offset().top)

    handleBodyClick: (e) =>
      @$replyBody.focus() if e.target == e.currentTarget

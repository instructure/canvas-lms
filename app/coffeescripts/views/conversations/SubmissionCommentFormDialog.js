//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import I18n from 'i18n!conversation_dialog'
import $ from 'jquery'
import _ from 'underscore'
import 'Backbone'
import DialogBaseView from '../DialogBaseView'
import template from 'jst/conversations/SubmissionCommentFormDialog'
import composeTitleBarTemplate from 'jst/conversations/composeTitleBar'
import composeButtonBarTemplate from 'jst/conversations/composeButtonBar'
import Message from '../../models/Message'
import AutocompleteView from './AutocompleteView'
import CourseSelectionView from './CourseSelectionView'
import ContextMessagesView from './ContextMessagesView'
import 'jquery.elastic'

// #
// reusable message composition dialog

export default class SubmissionCommentFormDialog extends DialogBaseView {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.resizeBody = this.resizeBody.bind(this)
    this.handleBodyClick = this.handleBodyClick.bind(this)
    super(...args)
  }

  static initClass() {
    this.prototype.template = template

    this.prototype.els = {
      '.message-body': '$messageBody',
      '.reply_body': '$replyBody',
      '.reply_form': '$form'
    }

    this.prototype.messages = {flashSuccess: I18n.t('message_sent', 'Message sent!')}
  }

  dialogOptions() {
    return {
      title: '',
      id: 'submission-comment-reply',
      autoOpen: false,
      minWidth: 400,
      width: 650,
      minHeight: 350,
      height: 400,
      resizable: true,
      // Event handler for catching when the dialog is closed.
      // Overridding @close() or @cancel() doesn't work alone since
      // hitting ESC doesn't trigger either of those events.
      close: () => this.afterClose(),
      resize: () => {
        this.resizeBody()
        return this._limitContentSize()
      },
      buttons: [
        {
          text: I18n.t('#buttons.cancel', 'Cancel'),
          click: this.cancel
        },
        {
          text: I18n.t('#buttons.send', 'Send'),
          class: 'btn-primary send-message',
          'data-track-category': 'Compose Message',
          'data-track-action': 'Edit',
          'data-track-label': 'Send',
          click: e => this.sendMessage(e)
        }
      ]
    }
  }

  show(model, options) {
    this.model = model
    this.dialog.dialog('option', 'title', this.model.get('subject'))
    if (options.trigger) this.returnFocusTo = options.trigger

    this.render()
    super.show(...arguments)
    this.initializeForm()
    return this.resizeBody()
  }

  // this method handles a layout bug with jqueryUI that occurs when you
  // attempt to resize the modal beyond the viewport.
  _limitContentSize() {
    if (this.$el.width() > this.$fullDialog.width()) return this.$el.width('100%')
  }

  // #
  // detach events that were dynamically added when the dialog is closed.
  afterClose() {
    this.$fullDialog.off('click', '.message-body')
    this.trigger('close')
    if (this.returnFocusTo) {
      this.returnFocusTo.focus()
      return delete this.returnFocusTo
    }
  }

  sendMessage(e) {
    e.preventDefault()
    e.stopPropagation()
    return this.$form.submit()
  }

  initialize() {
    super.initialize(...arguments)
    this.$fullDialog = this.$el.closest('.ui-dialog')
    // Customize titlebar
    const $titlebar = this.$fullDialog.find('.ui-dialog-titlebar')
    const $closeBtn = $titlebar.find('.ui-dialog-titlebar-close')
    $closeBtn.html(composeTitleBarTemplate())

    // add custom class to dialog container for
    return this.$fullDialog.addClass('submission-comment-reply-dialog')
  }

  prepareTextarea($scope) {
    const $textArea = $scope.find('textarea')
    return $textArea.elastic()
  }

  initializeForm() {
    this.prepareTextarea(this.$el)

    this.$fullDialog.on('click', '.message-body', this.handleBodyClick)

    return this.$form.formSubmit({
      intent: 'message',
      formDataTarget: 'url',
      disableWhileLoading: true,
      required: ['comment[text_comment]'],
      onSubmit: (request, submitData) => {
        // close dialog after submitting the message
        this.request = request
        const dfd = $.Deferred()
        this.trigger('submitting', dfd)
        this.close()
        $.when(this.request).then(response => {
          dfd.resolve()
          $.flashMessage(this.messages.flashSuccess)
          const message = new Message(
            _.extend(this.model.attributes, {submission_comments: response.submission_comments}),
            {parse: true}
          )
          return this.trigger('addMessage', message.get('messages')[0], response)
        })
        return $.when(this.request).fail(() => dfd.reject())
      }
    })
  }

  resizeBody() {
    // Compute desired height of body
    return this.$messageBody.height(
      this.$el.offset().top + this.$el.height() - this.$messageBody.offset().top
    )
  }

  handleBodyClick(e) {
    if (e.target === e.currentTarget) return this.$replyBody.focus()
  }
}
SubmissionCommentFormDialog.initClass()

/*
 * Copyright (C) 2011 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import sendForm from './jst/sendForm.handlebars'
import '@canvas/util/jquery/fixDialogButtons'
import 'jqueryui/dialog'
import 'jqueryui/tabs'

const I18n = useI18nScope('messages')

$('.tabs').tabs()

function showDialog(e) {
  e.preventDefault()
  const $message = $(e.target).parents('li.message:first')
  const modal = new MessageModal($message, $message.data())
  modal.open()
}

// Manage state on a new message modal.
class MessageModal {
  // Create a new MessageModal.
  //
  // $message - A wrapped li.message object.
  // {secureId, messageId} - An object containing secureId and messageId
  //   keys corresponding to the given message object.
  constructor($message, {secureId, messageId}) {
    this.tpl = sendForm({
      location: window.location.href,
      secureId,
      messageId,
      subject: `re: ${$message.find('.h6:first').text()}`,
      from: $message.find('.message-to').text(),
    })

    this.$el = $(this.tpl).dialog(this.dialogOptions)
    this.attachEvents()
  }

  // Internal: Manage event handlers on the new dialog.
  //
  // Returns nothing.
  attachEvents() {
    this.$el.on('submit', this.sendMessage)
  }

  // Public: Open the modal.
  //
  // Returns nothing.
  open() {
    this.$el.dialog('open').fixDialogButtons()
  }

  // Public: Close the modal.
  //
  // Returns nothing.
  close() {
    this.$el.dialog('close')
  }

  // Internal: Serialize the message form and send the request.
  //
  // e - Event object.
  //
  // Returns nothing.
  sendMessage = e => {
    e.preventDefault()
    this.close()
    $.post(this.$el.attr('action'), this.$el.serialize()).fail(() =>
      $.flashError(
        I18n.t(
          'messages.failure',
          'There was an error sending your email. Please reload the page and try again.'
        )
      )
    )
    $.flashMessage(I18n.t('messages.success', 'Your email is being delivered.'))
  }
}

// Options passed to $(...).dialog()
MessageModal.prototype.dialogOptions = {
  autoOpen: false,
  modal: true,
  title: I18n.t('dialog.title', 'Send a reply message'),
  zIndex: 1000,
}

$(() => $('.reply-button').on('click', showDialog))

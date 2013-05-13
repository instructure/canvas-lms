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

require [
  'i18n!messages'
  'jquery'
  'jst/messages/sendForm'
  'compiled/jquery/fixDialogButtons'
  'jqueryui/dialog'
  'jqueryui/tabs'
], (I18n, $, sendForm) ->

  $(".tabs").tabs()

  showDialog = (e) ->
    e.preventDefault()
    $message = $(e.target).parents('li.message:first')
    modal = new MessageModal($message, $message.data())
    modal.open()

  $(document).ready ->
    $('.reply-button').on('click', showDialog)

  # Manage state on a new message modal.
  class MessageModal
    # Options passed to $(...).dialog()
    dialogOptions:
      autoOpen: false
      modal: true
      title: I18n.t('dialog.title', 'Send a reply message')

    # Create a new MessageModal.
    #
    # $message - A wrapped li.message object.
    # {secureId, messageId} - An object containing secureId and messageId
    #   keys corresponding to the given message object.
    constructor: ($message, {secureId, messageId}) ->
      @tpl = sendForm
        location: window.location.href
        secureId: secureId
        messageId: messageId
        subject: "re: #{$message.find('.h6:first').text()}"
        from: $message.find('.message-to').text()

      @$el = $(@tpl).dialog(@dialogOptions)
      @attachEvents()

    # Internal: Manage event handlers on the new dialog.
    #
    # Returns nothing.
    attachEvents: ->
      @$el.on('submit', @sendMessage)

    # Public: Open the modal.
    #
    # Returns nothing.
    open: -> @$el.dialog('open').fixDialogButtons()

    # Public: Close the modal.
    #
    # Returns nothing.
    close: -> @$el.dialog('close')

    # Internal: Serialize the message form and send the request.
    #
    # e - Event object.
    #
    # Returns nothing.
    sendMessage: (e) =>
      e.preventDefault()
      @close()
      $.post(@$el.attr('action'), @$el.serialize()).fail ->
        $.flashError I18n.t('messages.failure', 'There was an error sending your email. Please reload the page and try again.')
      $.flashMessage I18n.t('messages.success', 'Your email is being delivered.')


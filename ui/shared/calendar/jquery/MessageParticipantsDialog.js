/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import messageParticipantsTemplate from '../jst/messageParticipants.handlebars'
import recipientListTemplate from '../jst/recipientList.handlebars'

const I18n = useI18nScope('calendar')

export default class MessageParticipantsDialog {
  constructor(opts) {
    let participantType
    this.opts = opts
    if (this.opts.timeslot) {
      this.recipients = this.opts.timeslot.child_events.map(e => e.user || e.group)
      participantType = this.recipients[0].short_name === undefined ? 'Group' : 'User'

      this.$form = $(messageParticipantsTemplate({participant_type: participantType}))
      this.$form.find('select.message_groups').remove()
    } else {
      this.group = this.opts.group
      this.$form = $(messageParticipantsTemplate({participant_type: this.group.participant_type}))
      this.dataSource = this.opts.dataSource

      this.$select = this.$form
        .find('select.message_groups')
        .change(this.loadParticipants)
        .val('unregistered')
    }

    this.$form.submit(this.sendMessage)

    this.$participantList = this.$form.find('ul')

    if (this.recipients) {
      this.$participantList.html(
        recipientListTemplate({recipientType: participantType, recipients: this.recipients})
      )
    }
  }

  show() {
    this.$form.dialog({
      width: 400,
      resizable: false,
      buttons: [
        {
          text: I18n.t('buttons.cancel', 'Cancel'),
          click() {
            $(this).dialog('close')
          },
        },
        {
          text: I18n.t('buttons.send_message', 'Send'),
          'data-text-while-loading': I18n.t('buttons.sending_message', 'Sending...'),
          class: 'btn-primary',
          click() {
            $(this).submit()
          },
        },
      ],
      close() {
        $(this).remove()
      },
      modal: true,
      zIndex: 1000,
    })
    return this.loadParticipants()
  }

  participantStatus(text = null) {
    const $status = $('<li class="status" />')
    this.$participantList.html($status)
    if (text) {
      $status.text(text)
    } else {
      $status.spin()
    }
  }

  loadParticipants = () => {
    if (this.recipients) return

    const registrationStatus = this.$select.val()
    this.loading = true
    this.participantStatus()

    return this.dataSource.getParticipants(this.group, registrationStatus, data => {
      delete this.loading
      if (data.length) {
        this.$participantList.html(
          recipientListTemplate({
            recipientType: this.group.participant_type,
            recipients: data,
          })
        )
      } else {
        const text =
          this.group.participant_type === 'Group'
            ? I18n.t('no_groups', 'No groups found')
            : I18n.t('no_users', 'No users found')
        this.participantStatus(text)
      }
    })
  }

  sendMessage = jsEvent => {
    jsEvent.preventDefault()

    if (this.loading) return

    const data = this.$form.getFormData()
    if (!data['recipients[]'] || !data.body) return

    // Setting bulk_message will always send individual messages regardless of group_conversation setting.
    // We're still setting group_conversation because that is required when there's more than 100 recipients.
    data.group_conversation = true
    data.bulk_message = true

    if (this.group) {
      data.tags = this.group.context_codes
      data.context_code = this.group.context_codes[0]
    } else if (this.opts.timeslot) {
      data.tags = this.opts.timeslot.all_context_codes.split(',')
    }

    const deferred = $.ajaxJSON(
      '/conversations',
      'POST',
      data,
      this.messageSent,
      this.messageFailed
    )
    return this.$form.disableWhileLoading(deferred, {
      buttons: ['[data-text-while-loading] .ui-button-text'],
    })
  }

  messageSent = () => {
    this.$form.dialog('close')
    $.flashMessage(I18n.t('messages_sent', 'Messages Sent'))
  }

  messageFailed = () => {
    this.$form
      .find('.error')
      .text(
        I18n.t(
          'errors.send_message_failed',
          'There was an error sending your message, please try again'
        )
      )
  }
}

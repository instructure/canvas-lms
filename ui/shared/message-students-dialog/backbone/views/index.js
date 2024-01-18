/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import {find, map} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView'
import template from '../../jst/messageStudentsDialog.handlebars'
import wrapperTemplate from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import ConversationCreator from '../models/ConversationCreator'
import recipientListTemplate from '../../jst/_messageStudentsWhoRecipientList.handlebars'
import '@canvas/serialize-form'

const I18n = useI18nScope('viewsMessageStudentsDialog')

extend(MessageStudentsDialog, DialogFormView)

function MessageStudentsDialog() {
  this.updateListOfRecipients = this.updateListOfRecipients.bind(this)
  this.getFormData = this.getFormData.bind(this)
  this._findRecipientGroupByName = this._findRecipientGroupByName.bind(this)
  this.validateBeforeSave = this.validateBeforeSave.bind(this)
  this.toJSON = this.toJSON.bind(this)
  return MessageStudentsDialog.__super__.constructor.apply(this, arguments)
}

// A list of "recipientGroups" that have two properties:
// name: String # Describes the group of users
// recipients: Array of Objects
//   These objects must have two keys:
//     id: String or Number # user's id
//     short_name: String # represents a short version of the user's name
MessageStudentsDialog.optionProperty('recipientGroups')

// The context of whatever the message is "for", renders the text as
// Message Students for <context> when the dialog is rendered.
MessageStudentsDialog.optionProperty('context')

MessageStudentsDialog.prototype.template = template

MessageStudentsDialog.prototype.wrapperTemplate = wrapperTemplate

MessageStudentsDialog.prototype.className = 'validated-form-view form-dialog'

MessageStudentsDialog.prototype.defaults = {
  height: 500,
  width: 500,
}

MessageStudentsDialog.prototype.els = {
  '[name=recipientGroupName]': '$recipientGroupName',
  '#message-recipients': '$messageRecipients',
  '[name=body]': '$messageBody',
}

MessageStudentsDialog.prototype.events = {
  ...DialogFormView.prototype.events,
  'change [name=recipientGroupName]': 'updateListOfRecipients',
  'click .dialog_closer': 'close',
  dialogclose: 'close',
}

MessageStudentsDialog.prototype.initialize = function (_opts) {
  MessageStudentsDialog.__super__.initialize.apply(this, arguments)
  this.options.title = this.context
    ? I18n.t('Message students for %{context}', {
        context: this.context,
      })
    : I18n.t('Message students')
  this.recipients = this.recipientGroups[0].recipients
  return (
    this.model ||
    (this.model = new ConversationCreator({
      chunkSize: ENV.MAX_GROUP_CONVERSATION_SIZE,
    }))
  )
}

MessageStudentsDialog.prototype.toJSON = function () {
  const json = {}
  const ref = ['title', 'recipients', 'recipientGroups']
  for (let i = 0, len = ref.length; i < len; i++) {
    const key = ref[i]
    json[key] = this[key]
  }
  return json
}

MessageStudentsDialog.prototype.validateBeforeSave = function (data, errors) {
  const errs = this.model.validate(data)
  if (errs) {
    if (errs.body) {
      errors.body = errs.body
    }
    if (errs.recipients) {
      errors.recipientGroupName = errs.recipients
    }
  }
  return errors
}

MessageStudentsDialog.prototype._findRecipientGroupByName = function (name) {
  return find(this.recipientGroups, function (grp) {
    return grp.name === name
  })
}

MessageStudentsDialog.prototype.getFormData = function () {
  const ref = this.$el.toJSON()
  const recipientGroupName = ref.recipientGroupName
  const body = ref.body
  const recipients = this._findRecipientGroupByName(recipientGroupName).recipients
  return {
    body,
    recipients: map(recipients, 'id'),
  }
}

MessageStudentsDialog.prototype.updateListOfRecipients = function () {
  const groupName = this.$recipientGroupName.val()
  const recipients = this._findRecipientGroupByName(groupName).recipients
  return this.$messageRecipients.html(
    recipientListTemplate({
      recipients,
    })
  )
}

MessageStudentsDialog.prototype.onSaveSuccess = function () {
  this.close()
  return $.flashMessage(I18n.t('Message Sent!'))
}

MessageStudentsDialog.prototype.close = function () {
  MessageStudentsDialog.__super__.close.apply(this, arguments)
  this.hideErrors()
  return this.remove()
}

export default MessageStudentsDialog

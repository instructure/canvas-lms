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

import I18n from 'i18n!viewsMessageStudentsDialog'
import $ from 'jquery'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView.coffee'
import template from '../../jst/messageStudentsDialog.handlebars'
import wrapperTemplate from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import ConversationCreator from '../models/ConversationCreator.coffee'
import recipientListTemplate from '../../jst/_messageStudentsWhoRecipientList.handlebars'
import _ from 'underscore'
import '@canvas/forms/jquery/serializeForm'

export default class MessageStudentsDialog extends DialogFormView

  # A list of "recipientGroups" that have two properties:
  # name: String # Describes the group of users
  # recipients: Array of Objects
  #   These objects must have two keys:
  #     id: String or Number # user's id
  #     short_name: String # represents a short version of the user's name
  @optionProperty 'recipientGroups'

  # The context of whatever the message is "for", renders the text as
  # Message Students for <context> when the dialog is rendered.
  @optionProperty 'context'

  template: template
  wrapperTemplate: wrapperTemplate
  className: 'validated-form-view form-dialog'

  defaults:
    height: 500
    width: 500

  els:
    '[name=recipientGroupName]': '$recipientGroupName'
    '#message-recipients': '$messageRecipients'
    '[name=body]': '$messageBody'

  events: _.extend {},
    DialogFormView::events
    'change [name=recipientGroupName]': 'updateListOfRecipients'
    'click .dialog_closer': 'close'
    'dialogclose': 'close'

  initialize: (opts) ->
    super
    @options.title = if @context
      I18n.t('Message students for %{context}', {@context})
    else
      I18n.t('Message students')

    @recipients = @recipientGroups[0].recipients
    @model or= new ConversationCreator(chunkSize: ENV.MAX_GROUP_CONVERSATION_SIZE)

  toJSON: =>
    json = {}
    json[key] = @[key] for key in [ 'title','recipients','recipientGroups' ]
    json

  validateBeforeSave: (data, errors) =>
    errs = @model.validate data
    if errs
      errors.body = errs.body if errs.body
      errors.recipientGroupName = errs.recipients if errs.recipients
    errors

  _findRecipientGroupByName: (name) =>
    _.detect @recipientGroups, (grp) -> grp.name is name

  getFormData: =>
    {recipientGroupName, body} = @$el.toJSON()
    {recipients} = @_findRecipientGroupByName recipientGroupName
    body: body, recipients: _.pluck(recipients,'id')

  updateListOfRecipients: =>
    groupName = @$recipientGroupName.val()
    {recipients} = @_findRecipientGroupByName groupName
    @$messageRecipients.html recipientListTemplate recipients: recipients

  onSaveSuccess: ->
    @close()
    $.flashMessage(I18n.t("Message Sent!"))

  close: ->
    super
    @hideErrors()
    @remove()

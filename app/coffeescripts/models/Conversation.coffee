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

define [
  'i18n!conversations'
  'Backbone'
  'jquery'
], (I18n, {Model}, $) ->

  class Conversation extends Model

    # This new class is here instead of reusing
    # coffeescripts/models/conversations/Conversation.coffee in order to
    # take advantage of the API.
    #
    # For a full list of supported attributes, see the Conversation API
    # documentation.

    url: '/api/v1/conversations'

    BLANK_BODY_ERR = I18n.t 'cannot_be_empty', 'Message cannot be blank'
    NO_RECIPIENTS_ERR = I18n.t('no_recipients_choose_another_group',
      'No recipients are in this group. Please choose another group.')

    validate: (attrs, options) ->
      errors = {}
      if !attrs.body or !$.trim(attrs.body.toString())
        errors.body = [ message: BLANK_BODY_ERR ]
      if !attrs.recipients || !attrs.recipients.length
        errors.recipients = [ message: NO_RECIPIENTS_ERR ]
      if Object.keys(errors).length
        errors
      else
        undefined


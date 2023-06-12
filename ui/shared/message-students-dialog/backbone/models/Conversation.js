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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Model} from '@canvas/backbone'
import $ from 'jquery'

const I18n = useI18nScope('models_conversations')

extend(Conversation, Model)

// This new class is here instead of reusing
// coffeescripts/models/conversations/Conversation.js in order to
// take advantage of the API.
//
// For a full list of supported attributes, see the Conversation API
// documentation.

function Conversation() {
  return Conversation.__super__.constructor.apply(this, arguments)
}

Conversation.prototype.url = '/api/v1/conversations'

const BLANK_BODY_ERR = I18n.t('cannot_be_empty', 'Message cannot be blank')

const NO_RECIPIENTS_ERR = I18n.t(
  'no_recipients_choose_another_group',
  'No recipients are in this group. Please choose another group.'
)

Conversation.prototype.validate = function (attrs, _options) {
  const errors = {}
  if (!attrs.body || !$.trim(attrs.body.toString())) {
    errors.body = [
      {
        message: BLANK_BODY_ERR,
      },
    ]
  }
  if (!attrs.recipients || !attrs.recipients.length) {
    errors.recipients = [
      {
        message: NO_RECIPIENTS_ERR,
      },
    ]
  }
  if (Object.keys(errors).length) {
    return errors
  } else {
    // eslint-disable-next-line no-void
    return void 0
  }
}

export default Conversation

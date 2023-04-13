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

import $ from 'jquery'
import _ from 'lodash'
import Conversation from './Conversation'

function ConversationCreator(opts) {
  this.chunkSize = opts.chunkSize || 100
}

ConversationCreator.prototype.save = function (data, saveOpts) {
  data.context_code = ENV.context_asset_string
  const xhrs = _.chunk(data.recipients, this.chunkSize).map(function (chunk) {
    const chunkData = {...data, recipients: chunk}
    return new Conversation().save(chunkData, saveOpts)
  })
  // eslint-disable-next-line prefer-spread
  return $.when.apply($, xhrs)
}

ConversationCreator.prototype.validate = function (attrs, options) {
  return new Conversation().validate(attrs, options)
}

export default ConversationCreator

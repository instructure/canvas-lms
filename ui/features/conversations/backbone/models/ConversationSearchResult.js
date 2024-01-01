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
import {Model} from '@canvas/backbone'
import {extend as lodashExtend} from 'lodash'

extend(ConversationSearchResult, Model)

function ConversationSearchResult() {
  return ConversationSearchResult.__super__.constructor.apply(this, arguments)
}

ConversationSearchResult.prototype.parse = function (data) {
  return lodashExtend(data, {
    isContext: data.type === 'context',
  })
}

export default ConversationSearchResult

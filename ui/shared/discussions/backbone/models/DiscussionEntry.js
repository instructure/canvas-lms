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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('discussions')

const UNKNOWN_AUTHOR = {
  avatar_image_url: null,
  display_name: I18n.t('unknown_author', 'Unknown Author'),
  id: null,
}

extend(DiscussionEntry, Backbone.Model)

function DiscussionEntry() {
  return DiscussionEntry.__super__.constructor.apply(this, arguments)
}

DiscussionEntry.prototype.author = function () {
  return this.findParticipant(this.get('user_id'))
}

DiscussionEntry.prototype.editor = function () {
  return this.findParticipant(this.get('editor_id'))
}

DiscussionEntry.prototype.findParticipant = function (user_id) {
  let ref, ref1, user
  if (
    user_id &&
    (user = (ref = this.collection) != null ? ref.participants.get(user_id) : void 0)
  ) {
    return user.toJSON()
  } else if (user_id === ((ref1 = ENV.current_user) != null ? ref1.id : void 0)) {
    return ENV.current_user
  } else {
    return UNKNOWN_AUTHOR
  }
}

export default DiscussionEntry

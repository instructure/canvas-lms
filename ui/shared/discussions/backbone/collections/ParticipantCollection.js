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
import Backbone from '@canvas/backbone'
import Participant from '../models/Participant'

const I18n = useI18nScope('discussions')

extend(ParticipantCollection, Backbone.Collection)

function ParticipantCollection() {
  return ParticipantCollection.__super__.constructor.apply(this, arguments)
}

ParticipantCollection.prototype.model = Participant

ParticipantCollection.prototype.defaults = {
  currentUser: {},
  unknown: {
    avatar_image_url: null,
    display_name: I18n.t('uknown_author', 'Unknown Author'),
    id: null,
  },
}

ParticipantCollection.prototype.findOrUnknownAsJSON = function (id) {
  const participant = this.get(id)
  if (participant != null) {
    return participant.toJSON()
  } else if (id === ENV.current_user.id) {
    return ENV.current_user
  } else {
    return this.options.unknown
  }
}

export default ParticipantCollection

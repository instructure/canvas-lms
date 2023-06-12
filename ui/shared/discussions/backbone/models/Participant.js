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
import Backbone from '@canvas/backbone'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('discussions.participant')

extend(Participant, Backbone.Model)

function Participant() {
  return Participant.__super__.constructor.apply(this, arguments)
}

Participant.prototype.defaults = {
  avatar_image_url: '',
  display_name: I18n.t('anonymous_user', 'Anonymous'),
  id: null,
}

export default Participant

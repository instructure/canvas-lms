/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import Backbone from '@canvas/backbone'

const I18n = useI18nScope('observer_pairing_code')

export default class ObserverPairingCode extends Backbone.Model {}

// no way of defining this in the class itself was making it work
// with how coffeescript classes were expecting things to work
ObserverPairingCode.prototype.errorMap = {
  code: {
    invalid: I18n.t('errors.invalid', 'Invalid pairing code'),
  },
}

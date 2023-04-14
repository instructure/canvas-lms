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
import LockButtonView from './Button'

extend(LockIconView, LockButtonView)

function LockIconView() {
  return LockIconView.__super__.constructor.apply(this, arguments)
}

LockIconView.prototype.lockClass = 'lock-icon-lock'

LockIconView.prototype.lockedClass = 'lock-icon-locked'

LockIconView.prototype.unlockClass = 'lock-icon-unlock'

LockIconView.prototype.tagName = 'span'

LockIconView.prototype.className = 'lock-icon'

// These values allow the default text to be overridden if necessary
LockIconView.optionProperty('lockText')
LockIconView.optionProperty('unlockText')

LockIconView.prototype.initialize = function () {
  LockIconView.__super__.initialize.apply(this, arguments)
  return (this.events = {...LockButtonView.prototype.events, ...this.events})
}

LockIconView.prototype.events = {
  keyclick: 'click',
}

export default LockIconView

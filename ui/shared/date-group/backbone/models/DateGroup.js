/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@canvas/datetime'

const I18n = useI18nScope('models_DateGroup')

export default class DateGroup extends Backbone.Model {
  dueAt() {
    const dueAt = this.get('due_at')
    if (dueAt) {
      return tz.parse(dueAt)
    } else {
      return null
    }
  }

  unlockAt() {
    const unlockAt = this.get('unlock_at') || this.get('single_section_unlock_at')
    if (unlockAt) {
      return tz.parse(unlockAt)
    } else {
      return null
    }
  }

  lockAt() {
    const lockAt = this.get('lock_at') || this.get('single_section_lock_at')
    if (lockAt) {
      return tz.parse(lockAt)
    } else {
      return null
    }
  }

  now() {
    const now = this.get('now')
    if (now) {
      return tz.parse(now)
    } else {
      return new Date()
    }
  }

  // no lock/unlock dates
  alwaysAvailable() {
    return !this.unlockAt() && !this.lockAt()
  }

  // not unlocked yet
  pending() {
    const unlockAt = this.unlockAt()
    return unlockAt && unlockAt > this.now()
  }

  // available and won't ever lock
  available() {
    return this.alwaysAvailable() || (!this.lockAt() && this.unlockAt() < this.now())
  }

  // available, but will lock at some point
  open() {
    return this.lockAt() && !this.pending() && !this.closed()
  }

  // locked
  closed() {
    const lockAt = this.lockAt()
    return lockAt && lockAt < this.now()
  }

  toJSON() {
    return {
      dueFor: this.get('title'),
      dueAt: this.dueAt(),
      unlockAt: this.unlockAt(),
      lockAt: this.lockAt(),
      available: this.available(),
      pending: this.pending(),
      open: this.open(),
      closed: this.closed(),
    }
  }
}
DateGroup.prototype.defaults = {
  get title() {
    return I18n.t('everyone_else', 'Everyone else')
  },
  due_at: null,
  unlock_at: null,
  lock_at: null,
}

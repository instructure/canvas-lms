/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import './index'
import DatetimeField from './DatetimeField'
import {log} from '@canvas/datetime-natural-parsing-instrument'

// inb4 "why not just monkey-patch DatetimeField from here and not have others
// know about this?", the reason we have it this way is that it's difficult to
// patch a constructor reliably, and - luckily for us - it is only that library
// that directly accesses DatetimeField so we can get away with this, at the
// measly cost of some spaghetti
export default class InstrumentedDatetimeField extends DatetimeField {
  constructor(...args) {
    super(...args)
    this.__updateQueue__ = []
    trackPasteEvents(this, this.__updateQueue__)
    trackTypingEvents(this, this.__updateQueue__)

    // not all widgets show a picker
    if (this.$field.data('datepicker')) {
      trackPickingEvents(this, this.__updateQueue__)
    }
  }

  // we need a reliable way to tell when an interaction *can* be logged --
  // anytime after the DatetimeField has updated its properties should be ok
  update() {
    DatetimeField.prototype.update.apply(this, arguments)

    // might not be initialized yet because DatetimeField's constructor itself
    // calls update()
    if (this.__updateQueue__) {
      this.__updateQueue__.splice(0).forEach(f => f())
    }
  }
}

function trackPasteEvents(datetimeField, updateQueue) {
  const node = datetimeField.$field[0]

  node.addEventListener(
    'paste',
    e => {
      updateQueue.push(() => {
        const {datetime} = datetimeField

        log({
          id: node.id,
          method: 'paste',
          value: e.target.value,
          parsed: (datetime && datetime.toISOString()) || null,
        })
      })
    },
    false
  )
}

function trackTypingEvents(datetimeField) {
  const node = datetimeField.$field[0]

  let value = null
  let typing = false

  node.addEventListener(
    'input',
    e => {
      if (e.inputType === 'insertText') {
        typing = true
        // we cannot directly inspect the node's value at the time of blur because
        // it might have been wiped out by DatetimeField during validation
        value = e.target.value
      }
    },
    false
  )

  node.addEventListener(
    'blur',
    () => {
      if (typing) {
        const finalValue = value
        const {datetime} = datetimeField

        typing = false
        value = null

        log({
          id: node.id,
          method: 'type',
          value: finalValue,
          parsed: (datetime && datetime.toISOString()) || null,
        })
      }
    },
    false
  )
}

function trackPickingEvents(datetimeField, _updateQueue) {
  const node = datetimeField.$field[0]
  const picker = datetimeField.$field.data('datepicker')
  const {onClose = NOOP, onSelect = NOOP} = picker.settings

  let didUserPick = false

  picker.settings.onClose = function (inputValue) {
    if (didUserPick) {
      const {datetime} = datetimeField

      didUserPick = false

      log({
        id: node.id,
        method: 'pick',
        value: node.value,
        parsed: (datetime && datetime.toISOString()) || null,
      })
    }

    return onClose(inputValue)
  }

  picker.settings.onSelect = function (text, picker) {
    didUserPick = true
    return onSelect(text, picker)
  }
}

const NOOP = () => {}

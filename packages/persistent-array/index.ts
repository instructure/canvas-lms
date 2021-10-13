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

import debounce from 'lodash/debounce.js'
import type { PersistentArrayParameters } from './types'

// A special Array that persists its value to localStorage whenever you push to,
// pop from, or splice it.
export default function createPersistentArray({
  key,
  throttle = 1000,
  size = Infinity,
  transform = x => x
}: PersistentArrayParameters) {
  const value = JSON.parse(localStorage.getItem(key) || '[]')
  const save = () => localStorage.setItem(key, JSON.stringify(transform(value)))
  const resize = () => {
    if (value.length >= size) {
      value.shift()
    }
  };

  const saveInBatch = debounce(save, Math.max(0, throttle))

  // we'll do it on the next frame and not synchronously if only to be
  // consistent with the batch saving behavior and to avoid interfering with the
  // actual routine in case the save routine throws errors
  const saveASAP = debounce(save, 0)

  const saveBehaviors = {
    pop: saveInBatch,
    push: pipe(resize, saveInBatch),
    splice: saveASAP,
    // ---
    // nb: we only intend to cover the APIs we're using
  }

  for (const [method, saveImpl] of Object.entries(saveBehaviors)) {
    // define them as properties so that they are not enumerable; we want this
    // to behave as much like a regular Array as possible
    Object.defineProperty(value, method, {
      enumerable: false,
      configurable: false,
      value() {
        saveImpl()
        return Array.prototype[method].apply(this, arguments)
      }
    })
  }

  Object.defineProperty(value, 'cancel', {
    value() {
      saveInBatch.cancel()
      saveASAP.cancel()
    }
  })

  return value
}

const pipe = (...f) => x => f.reduce((acc, fx) => fx(acc), x)
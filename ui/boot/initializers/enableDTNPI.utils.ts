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

import {debounce} from 'lodash'

export type PersistentArray<T> = Array<T>
export type PersistentArrayParameters = {
  // Where to store the value in localStorage. If a value is found at that key,
  // it will be used as the initial value for the array.
  key: string

  // Milliseconds to wait before persisting any batched writes. APIs that
  // accept single elements, like push and pop, batch their writes to
  // localStorage.
  throttle: number

  // Maximum number of elements the array should contain. If a call to #push()
  // would cause the array to exceed this boundary, a value will be shifted
  // from the front first.
  //
  // Defaults to Infinity.
  size: number

  // A hook to transform the value to make it more suitable for saving by the
  // transform parameter. This only applies to the saved value and not for the
  // one stored in memory.
  //
  // Don't mutate it
  transform: (array: NormalizedDTNPIEvent[]) => NormalizedDTNPIEvent[]
}

export type DateTimeInputMethod = 'pick' | 'type' | 'paste'

export type DTNPIEvent = {
  id: string
  method: DateTimeInputMethod
  parsed: string | null
  value: string | null
}
export type NormalizedDTNPIEvent = {
  id: string
  type: string
  locale: string | null
  method: DateTimeInputMethod
  parsed: string | null
  value: string | null
}

// A special Array that persists its value to localStorage whenever you push to,
// pop from, or splice it.
export function createPersistentArray({
  key,
  throttle = 1000,
  size = Infinity,
  transform = x => x as NormalizedDTNPIEvent[],
}: PersistentArrayParameters): PersistentArray<NormalizedDTNPIEvent> {
  const value = JSON.parse(localStorage.getItem(key) || '[]') as NormalizedDTNPIEvent[]
  if (!Array.isArray(value)) {
    throw new Error(`Expected ${key} to be an array`)
  }
  const save = () => localStorage.setItem(key, JSON.stringify(transform(value)))
  const resize = () => {
    if (value.length >= size) {
      value.shift()
    }
  }

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

  function entries<T extends Record<string, unknown>>(obj: T) {
    return Object.entries(obj) as Array<[keyof T, T[keyof T]]>
  }

  for (const [method, saveImpl] of entries(saveBehaviors)) {
    // define them as properties so that they are not enumerable; we want this
    // to behave as much like a regular Array as possible
    Object.defineProperty(value, method, {
      enumerable: false,
      configurable: false,
      value(...args: any[]) {
        saveImpl()
        return Array.prototype[method].apply(this, args)
      },
    })
  }

  Object.defineProperty(value, 'cancel', {
    value() {
      saveInBatch.cancel()
      saveASAP.cancel()
    },
  })

  return value
}

const pipe =
  (...f: Array<(x: unknown) => void>) =>
  (x?: unknown) =>
    f.reduce((acc, fx) => fx(acc), x)

export function normalizeEvent(event: DTNPIEvent): NormalizedDTNPIEvent {
  return {
    id: event.id,
    type: 'datepicker_usage',
    locale: window.ENV?.LOCALE || null,
    method: event.method,
    parsed: event.parsed,
    // don't store values that may be too long, 32 feels plenty for what people
    // may actually type
    value: event.value ? event.value.slice(0, 32) : null,
  }
}

export function postToBackend({
  endpoint,
  events,
}: {
  endpoint: string
  events: unknown
}): Promise<Response> {
  const url = endpoint || window.ENV.DATA_COLLECTION_ENDPOINT
  if (!url) {
    throw new Error('No endpoint provided')
  }
  return fetch(url, {
    method: 'PUT',
    mode: 'cors',
    credentials: 'omit',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(events),
  })
}

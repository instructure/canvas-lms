// @ts-nocheck
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

import createPersistentArray from './enableDTNPI.utils'
import {configure} from '@canvas/datetime-natural-parsing-instrument'

const localStorageKey = 'dtnpi'

let events

export async function up(options = {endpoint: null, throttle: 1000, size: 50}) {
  const throttle = Math.max(1, Math.min(options.throttle, 1000))
  const size = Math.max(1, options.size)
  const {endpoint} = options

  events = createPersistentArray({
    key: localStorageKey,
    throttle,
    size,
    // @ts-expect-error
    transform: value => value.map(normalizeEvent),
  })

  configure({events})

  // submit events that have been collected so far:
  const collected = [].concat(events)

  if (endpoint && collected.length) {
    await postToBackend({endpoint, events: collected})
  }

  events.splice(0, collected.length)
}

export function down() {
  if (events) {
    events.splice(0)
    events = null
  }

  localStorage.removeItem(localStorageKey)
}

function normalizeEvent(event) {
  return {
    id: event.id,
    type: 'datepicker_usage',
    locale: (window.ENV && window.ENV.LOCALE) || null,
    method: event.method,
    parsed: event.parsed,
    // don't store values that may be too long, 32 feels plenty for what people
    // may actually type
    value: event.value ? event.value.slice(0, 32) : null,
  }
}

// TODO: submit to an actual backend
function postToBackend({endpoint, events}): Promise<void> {
  // @ts-expect-error
  return fetch(endpoint, {
    method: 'PUT',
    mode: 'cors',
    credentials: 'omit',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(events),
  })
}

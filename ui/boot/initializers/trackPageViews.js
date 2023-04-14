/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import $ from 'jquery'
import authenticity_token from '@canvas/authenticity-token'
import '@canvas/jquery/jquery.ajaxJSON'

if (!('INST' in window)) window.INST = {}

let update_url = window.ENV.page_view_update_url
if (update_url) {
  $(() => {
    let interactionSeconds = 0

    INST.interaction_contexts = {}

    if (update_url) {
      let secondsSinceLastEvent = 0
      const intervalInSeconds = 60 * 5

      $(document).bind('page_view_update_url_received', (event, new_update_url) => {
        update_url = new_update_url
      })

      let updateTrigger
      $(document).bind('page_view_update', (event, force) => {
        const data = {}

        if (force || (interactionSeconds > 10 && secondsSinceLastEvent < intervalInSeconds)) {
          data.interaction_seconds = interactionSeconds
          $.ajaxJSON(update_url, 'PUT', data, null, (result, xhr) => {
            if (xhr.status === 422) {
              clearInterval(updateTrigger)
            }
          })
          interactionSeconds = 0
        }
      })

      updateTrigger = setInterval(() => {
        $(document).triggerHandler('page_view_update')
      }, 1000 * intervalInSeconds)

      window.addEventListener(
        'unload',
        () => {
          if (interactionSeconds > 30) {
            // Use sendBeacon so the request doesn't get cancelled as we navigate away like a normal XHR would,
            // but because sendBeacon only sends POST requests, we have to use FormData to fake the "_method" to PUT
            // like Rail's `form_for` does
            const formData = new FormData()
            formData.append('interaction_seconds', interactionSeconds)
            formData.append('_method', 'put')
            formData.append('authenticity_token', authenticity_token())
            formData.append('utf8', '&#x2713')
            navigator.sendBeacon(update_url, formData)
          }
        },
        false
      )

      let eventInTime = false
      $(document).bind('mousemove keypress mousedown focus', () => {
        eventInTime = true
      })
      setInterval(() => {
        if (eventInTime) {
          interactionSeconds++
          if (INST && INST.interaction_context && INST.interaction_contexts) {
            INST.interaction_contexts[INST.interaction_context] =
              (INST.interaction_contexts[INST.interaction_context] || 0) + 1
          }
          eventInTime = false
          if (secondsSinceLastEvent >= intervalInSeconds) {
            secondsSinceLastEvent = 0
            $(document).triggerHandler('page_view_update')
          }
          secondsSinceLastEvent = 0
        } else {
          secondsSinceLastEvent++
        }
      }, 1000)
    }
  })
}

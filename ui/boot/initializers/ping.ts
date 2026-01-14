//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import {throttle} from 'es-toolkit'

const pingUrl = (ENV as {ping_url?: string}).ping_url

if (pingUrl) {
  let lastUserActivity = Date.now()

  // Only ping if user was active within this threshold
  const ACTIVITY_THRESHOLD = 5 * 60 * 1000 // 5 inutes

  const activityEvents = ['mousemove', 'mousedown', 'keydown', 'scroll', 'touchstart'] as const

  // Throttled to once per second to avoid excessive updates
  const updateActivity = throttle(
    () => {
      lastUserActivity = Date.now()
    },
    1000,
    {edges: ['leading']},
  )

  activityEvents.forEach(event => {
    document.addEventListener(event, updateActivity, {passive: true, capture: true})
  })

  const interval = setInterval(() => {
    if (document.visibilityState === 'visible') {
      const timeSinceActivity = Date.now() - lastUserActivity

      // Only ping if the user was recently active
      // This prevents keeping sessions alive when users leave pages open but inactive
      if (timeSinceActivity < ACTIVITY_THRESHOLD) {
        $.post(pingUrl).fail((xhr: {status: number}) => {
          if (xhr.status === 401) {
            clearInterval(interval)
            // Clean up event listeners when session ends
            activityEvents.forEach(event => {
              document.removeEventListener(event, updateActivity, {capture: true})
            })
          }
        })
      }
    }
  }, 1000 * 180)
}

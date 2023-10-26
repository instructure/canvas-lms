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

import type {Setting} from '@canvas/global/env/EnvCommon'

const settings = [
  'manual_mark_as_read',
  'release_notes_badge_disabled',
  'collapse_global_nav',
  'collapse_course_nav',
  'hide_dashcard_color_overlays',
  'comment_library_suggestions_enabled',
  'elementary_dashboard_disabled',
] as const

export function getSetting({queryKey}: {queryKey: ['settings', Setting]}) {
  const setting = queryKey[1]
  if (!settings.includes(setting)) {
    throw new Error('Invalid setting')
  }
  return Boolean(ENV.SETTINGS[setting])
}

export function setSetting({setting, newState}: {setting: Setting; newState: boolean}) {
  const oldValue = ENV.SETTINGS[setting]

  // optimistic update
  ENV.SETTINGS[setting] = newState

  // use fetch
  return fetch('/api/v1/users/self/settings', {
    method: 'PUT',
    body: JSON.stringify({[setting]: newState}),
    headers: {
      'Content-Type': 'application/json',
    },
  })
    .then(() => {
      // ensure change
      ENV.SETTINGS[setting] = newState
    })
    .catch(() => {
      ENV.SETTINGS[setting] = oldValue
    })
}

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

import type {QueryKey} from '@tanstack/react-query'
import type {Setting} from '@canvas/global/env/EnvCommon'
import {defaultFetchOptions} from '@canvas/util/xhr'
import doFetchApi from '@canvas/do-fetch-api-effect'

const settings = [
  'manual_mark_as_read',
  'release_notes_badge_disabled',
  'collapse_global_nav',
  'collapse_course_nav',
  'hide_dashcard_color_overlays',
  'comment_library_suggestions_enabled',
  'elementary_dashboard_disabled',
] as const

export function getSetting({queryKey}: {queryKey: QueryKey}) {
  const setting = queryKey[1] as Setting
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
  return doFetchApi({
    path: '/api/v1/users/self/settings',
    params: {[setting]: newState},
  })
    .then(() => {
      // ensure change
      ENV.SETTINGS[setting] = newState
    })
    .catch(() => {
      ENV.SETTINGS[setting] = oldValue
    })
}

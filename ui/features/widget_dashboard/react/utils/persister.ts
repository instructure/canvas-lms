/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {experimental_createPersister} from '@tanstack/query-persist-client-core'
import {v4} from 'uuid'

const ONE_DAY = 1000 * 60 * 60 * 24

// Widget dashboard uses a stable cache buster that doesn't change on page reload
// This allows queries to persist across page refreshes (Cmd+R)
if (localStorage.widgetDashboardCacheBuster === undefined) {
  localStorage.widgetDashboardCacheBuster = v4()
}

export const widgetDashboardPersister = experimental_createPersister({
  storage: window.sessionStorage,
  maxAge: ONE_DAY,
  buster: localStorage.widgetDashboardCacheBuster,
})

// Test helper to clear widget dashboard cache
export const clearWidgetDashboardCache = () => {
  // Clear sessionStorage keys that start with 'tanstack-query'
  const keysToRemove: string[] = []
  for (let i = 0; i < sessionStorage.length; i++) {
    const key = sessionStorage.key(i)
    if (key?.startsWith('tanstack-query')) {
      keysToRemove.push(key)
    }
  }
  keysToRemove.forEach(key => sessionStorage.removeItem(key))
}

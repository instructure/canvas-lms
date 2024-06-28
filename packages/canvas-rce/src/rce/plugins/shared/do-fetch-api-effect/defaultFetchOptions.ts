/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import getCookie from './get-cookie'

const csrfToken = getCookie('_csrf_token')

// these are duplicated in application_helper.rb#prefetch_xhr
// because we don't have a good pattern for sharing them yet.
// If you change these defaults, you should probably cascade that change
// to that ruby location
export const defaultFetchOptions = (): {
  credentials: 'include' | 'omit' | 'same-origin'
  headers: Record<string, string>
} => ({
  credentials: 'same-origin',
  headers: {
    Accept: 'application/json+canvas-string-ids, application/json',
    'X-Requested-With': 'XMLHttpRequest',
    'X-CSRF-Token': csrfToken as string,
  },
})

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

/**
 * A faster alternative to $.cookie for getting a cookie from document.cookie by name
 * see: https://stackoverflow.com/a/25490531/7159335
 * @param {string} cookieName
 * @returns {string} cookie value
 */
export default function getCookie(cookieName) {
  const match = document.cookie.match('(^|[^;]+)\\s*' + cookieName + '\\s*=\\s*([^;]+)')
  return match ? decodeURIComponent(match.pop()) : undefined
}

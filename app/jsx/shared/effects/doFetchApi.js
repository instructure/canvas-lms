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

import $ from 'jquery'
import getCookie from '../helpers/getCookie'

function constructRelativeUrl({path, params}) {
  const queryString = $.param(params)
  if (!queryString.length) return path
  return `${path}?${queryString}`
}

export default async function doFetchApi({
  path,
  method = 'GET',
  headers = {},
  params = {},
  body,
  fetchOpts = {}
}) {
  const fetchHeaders = {
    Accept: 'application/json+canvas-string-ids, application/json',
    'X-CSRF-Token': getCookie('_csrf_token')
  }
  if (body && typeof body !== 'string') {
    body = JSON.stringify(body)
    fetchHeaders['Content-Type'] = 'application/json'
  }
  Object.assign(fetchHeaders, headers)

  const url = constructRelativeUrl({path, params})
  const response = await fetch(url, {headers: fetchHeaders, body, method, ...fetchOpts})
  if (!response.ok) {
    const err = new Error(
      `doFetchApi received a bad response: ${response.status} ${response.statusText}`
    )
    err.response = response // in case anyone wants to check it for something
    throw err
  }
  const text = await response.text()
  const json = text.length > 0 ? JSON.parse(text) : undefined
  return json
}

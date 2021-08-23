/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import qs from 'qs'

export function sendGetRequest(url, params) {
  const request = new XMLHttpRequest()
  const query = qs.stringify(params)
  const fullUrl = query ? `${url}?${query}` : url
  request.open('GET', fullUrl, true)
  request.send()
  return request
}

export function sendPostJsonRequest(url, params, data) {
  const request = new XMLHttpRequest()
  const query = qs.stringify(params)
  const fullUrl = query ? `${url}?${query}` : url
  request.open('POST', fullUrl, true)
  request.setRequestHeader('Content-Type', 'application/json; charset=UTF-8')
  request.send(JSON.stringify(data))
  return request
}

export function sendPostFormRequest(url, params, data) {
  const request = new XMLHttpRequest()
  const query = qs.stringify(params)
  const fullUrl = query ? `${url}?${query}` : url
  request.open('POST', fullUrl, true)
  request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
  request.send(qs.stringify(data))
  return request
}

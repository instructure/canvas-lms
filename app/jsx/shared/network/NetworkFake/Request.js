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
 * details.g
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import qs from 'qs'

import Response from './Response'

export default class Request {
  constructor(request) {
    this._request = request
  }

  get url() {
    return this._request.url
  }

  get path() {
    return this.url.split('?')[0]
  }

  get params() {
    return qs.parse(this.url.split('?')[1])
  }

  get headers() {
    return this._request.requestHeaders
  }

  get requestBody() {
    return this._request.requestBody
  }

  get formBody() {
    return qs.parse(this.requestBody)
  }

  get jsonBody() {
    return JSON.parse(this.requestBody)
  }

  get response() {
    return (this._response = this._response || new Response(this))
  }

  isReady() {
    return this.url != null
  }
}

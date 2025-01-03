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

interface ResponseData {
  body: string | null
  headers: Record<string, string>
  status: number
}

interface Request {
  _request: {
    respond: (status: number, headers: Record<string, string>, body: string | null) => void
  }
  params: Record<string, unknown>
  path: string
}

export default class Response {
  request: Request
  responseData: ResponseData
  sent: boolean

  constructor(request: Request) {
    this.request = {
      ...request,
      params: request.params || {},
      path: request.path || '',
    }
    this.responseData = {
      body: null,
      headers: {},
      status: 200,
    }
    this.sent = false
  }

  setHeader(key: string, value: string): void {
    this.responseData.headers[key] = value
  }

  clearHeaders(): void {
    this.responseData.headers = {}
  }

  setStatus(status: number): void {
    this.responseData.status = status
  }

  setBody(body: string): void {
    this.responseData.body = body
  }

  setJson(data: unknown): void {
    this.setHeader('Content-Type', 'application/json')
    this.setBody(JSON.stringify(data))
  }

  send(): void {
    if (!this.sent) {
      const {body, headers, status} = this.responseData
      this.request._request.respond(status, headers, body)
    }
    this.sent = true
  }
}

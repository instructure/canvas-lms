//
// Copyright (C) 2012 - present Instructure, Inc.
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
//

import $ from 'jquery'

// Used to make a fake XHR request, useful if there are errors on an
// asynchronous request generated using the iframe trick.
//
// We don't actually care about some of this stuff, but we stub out all XHR so
// that things that try to use it don't blow up.
export default class FakeXHR {
  constructor() {
    this.readyState = 0
    this.timeout = 0
    this.withCredentials = false
  }

  // #
  // we assume all responses are json
  setResponse(body) {
    this.readyState = 4
    this.responseText = body

    try {
      this.response = JSON.parse(body)
    } catch (e) {
      this.status = 500
      this.statusText = '500 Internal Server Error'
      return
    }

    if (this.response.errors) {
      this.status = 400
      this.statusText = '400 Bad Request'
    } else {
      this.status = 200
      this.statusText = '200 OK'
    }
    return (this.responseType = 'json')
  }

  abort() {}

  getAllResponseHeaders() {
    if (this.responseText) {
      return ''
    } else {
      return null
    }
  }

  getResponseHeader() {}

  open() {}

  overrideMimeType() {}

  send() {}

  setRequestHeader() {}
}

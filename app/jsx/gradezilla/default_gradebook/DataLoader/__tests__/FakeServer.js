/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import sinon from 'sinon'

export function pathFromRequest(request) {
  return request.url.split('?')[0]
}

export function paramsFromRequest(request) {
  return qs.parse(request.url.split('?')[1])
}

function matchParams(request, params) {
  const queryString = request.url.split('?')[1] || ''
  const queryParams = qs.parse(queryString)
  return Object.keys(params).every(
    // ensure the params match, no matter the data type
    key => qs.stringify({[key]: queryParams[key]}) === qs.stringify({[key]: params[key]})
  )
}

function requestMatchesResponse(request, response) {
  return request.url.match(response.url) && matchParams(request, response.params)
}

function getResponseForRequest(request, pendingResponses) {
  let response
  for (let i = 0; i < pendingResponses.length; i++) {
    if (requestMatchesResponse(request, pendingResponses[i])) {
      response = pendingResponses[i]
      pendingResponses.splice(i, 1)
      break
    }
  }
  return response
}

function urlMatcher(url) {
  const urlRegExp = new RegExp(`^${url}$`)
  return request => pathFromRequest(request).match(urlRegExp)
}

function processRequest(request, pendingResponses) {
  const response = getResponseForRequest(request, pendingResponses)
  if (response) {
    request.respond(response.status, response.headers, JSON.stringify(response.body))
  }
}

function storeRequestAndProcessResponses(request, server) {
  server.receivedRequests.push(request)
  setTimeout(() => {
    processRequest(request, server.pendingResponses)
  })
}

class RequestStub {
  constructor(server, url, queryParams) {
    this.server = server
    this.url = url
    this.queryParams = queryParams
  }

  respond(responseData) {
    const {queryParams, url} = this
    if (responseData instanceof Array) {
      responseData.forEach((responseDatum, index) => {
        const headers = {}
        headers.Link = [
          `<${url}&page=1>; rel="first"`,
          `<${url}&page=${index + 1}>; rel="current"`,
          `<${url}&page=${responseData.length}>; rel="last"`
        ].join(',')
        const params = {...queryParams}
        if (index > 0) {
          params.page = index + 1
        }
        this.server.pendingResponses.push({url, params, headers, ...responseDatum})
      })
    } else {
      this.server.pendingResponses.push({url, params: queryParams, headers: {}, ...responseData})
    }
  }
}

export default class FakeServer {
  constructor() {
    this.fakeXhr = sinon.useFakeXMLHttpRequest()
    this.fakeXhr.onCreate = request => {
      storeRequestAndProcessResponses(request, this)
    }
    this.receivedRequests = []
    this.pendingResponses = []
  }

  filterRequests(url) {
    return this.receivedRequests.filter(urlMatcher(url))
  }

  findFirstIndex(url) {
    return this.receivedRequests.findIndex(urlMatcher(url))
  }

  findLastIndex(url) {
    const reverseIndex = [...this.receivedRequests].reverse().findIndex(urlMatcher(url))
    return reverseIndex === -1 ? -1 : this.receivedRequests.length - reverseIndex - 1
  }

  findRequest(url) {
    return this.receivedRequests.find(urlMatcher(url))
  }

  for(url, queryParams = {}) {
    return new RequestStub(this, url, queryParams)
  }

  teardown() {
    this.fakeXhr.restore()
  }

  unsetResponses(...urlsToUnset) {
    urlsToUnset.forEach(url => {
      this.pendingResponses = this.pendingResponses.filter(response => response.url !== url)
    })
  }
}

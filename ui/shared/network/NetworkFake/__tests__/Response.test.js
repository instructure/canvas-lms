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

import NetworkFake from '../NetworkFake'
import {sendGetRequest} from '../specHelpers'

describe('Shared > Network > NetworkFake > Response', () => {
  let network

  beforeEach(() => {
    network = new NetworkFake()
  })

  afterEach(async () => {
    await network.allRequestsReady()
    network.restore()
  })

  async function getResponse() {
    await network.allRequestsReady()
    const [{response}] = network.getRequests()
    return response
  }

  describe('headers', () => {
    it('can be set using #setHeader()', async () => {
      const xhr = sendGetRequest('/example')
      const response = await getResponse()
      response.setHeader('Content-Type', 'text/plain')
      response.send()
      expect(xhr.getResponseHeader('Content-Type')).toEqual('text/plain')
    })

    it('default to empty', async () => {
      const xhr = sendGetRequest('/example')
      const response = await getResponse()
      response.send()
      expect(xhr.getAllResponseHeaders()).toEqual('')
    })
  })

  describe('#clearHeaders()', () => {
    it('removes all headers set on the response', async () => {
      const xhr = sendGetRequest('/example')
      const response = await getResponse()
      response.setHeader('Content-Type', 'text/plain')
      response.setHeader('X-Data-Example', 'true')
      response.clearHeaders()
      response.send()
      expect(xhr.getAllResponseHeaders()).toEqual('')
    })
  })

  describe('status', () => {
    it('can be set using #setStatus()', async () => {
      const xhr = sendGetRequest('/example')
      const response = await getResponse()
      response.setStatus(218)
      response.send()
      expect(xhr.status).toEqual(218)
    })

    it('defaults to 200', async () => {
      const xhr = sendGetRequest('/example')
      const response = await getResponse()
      response.send()
      expect(xhr.status).toEqual(200)
    })
  })

  describe('body', () => {
    it('can be set as text using #setBody()', async () => {
      const xhr = sendGetRequest('/example')
      const response = await getResponse()
      response.setBody('some\rdata')
      response.send()
      expect(xhr.responseText).toEqual('some\rdata')
    })

    it('defaults to an empty string', async () => {
      const xhr = sendGetRequest('/example')
      const response = await getResponse()
      response.send()
      expect(xhr.responseText).toEqual('')
    })
  })

  describe('#setJson()', () => {
    it('sets the "Content-Type" header to "application/json"', async () => {
      const xhr = sendGetRequest('/example')
      const response = await getResponse()
      response.setJson({example: true, items: ['one', 2]})
      response.send()
      expect(xhr.getResponseHeader('Content-Type')).toEqual('application/json')
    })

    it('sets the body to stringified json', async () => {
      const xhr = sendGetRequest('/example')
      const response = await getResponse()
      const json = {example: true, items: ['one', 2]}
      response.setJson(json)
      response.send()
      expect(JSON.parse(xhr.responseText)).toEqual(json)
    })
  })

  describe('#send()', () => {
    it('sends a response for the request', async () => {
      const xhr = sendGetRequest('/example')
      const response = await getResponse()
      response.send()
      expect(xhr.readyState).toEqual(XMLHttpRequest.DONE)
    })

    it('does not send more than one response', async () => {
      sendGetRequest('/example')
      const response = await getResponse()
      response.send()
      expect(() => response.send()).not.toThrow()
    })
  })
})

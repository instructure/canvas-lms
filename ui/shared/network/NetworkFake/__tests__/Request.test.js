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
import Response from '../Response'
import {sendGetRequest, sendPostFormRequest, sendPostJsonRequest} from '../specHelpers'

describe('Shared > Network > NetworkFake > Request', () => {
  let network

  beforeEach(() => {
    network = new NetworkFake()
  })

  afterEach(async () => {
    await network.allRequestsReady()
    network.restore()
  })

  describe('#url', () => {
    it('is the url of the request', async () => {
      sendGetRequest('/example')
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.url).toEqual('/example')
    })

    it('includes the query', async () => {
      sendGetRequest('/example', {sample: true})
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.url).toEqual('/example?sample=true')
    })
  })

  describe('#path', () => {
    it('is the url of the request', async () => {
      sendGetRequest('/example')
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.path).toEqual('/example')
    })

    it('excludes the query', async () => {
      sendGetRequest('/example?data=1', {sample: true})
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.path).toEqual('/example')
    })
  })

  describe('#params', () => {
    it('is the parsed query of the url', async () => {
      sendGetRequest('/example', {sample: true})
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.params).toEqual({sample: 'true'})
    })

    it('is an empty object when no params were provided', async () => {
      sendGetRequest('/example')
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.params).toEqual({})
    })
  })

  describe('#formBody', () => {
    it('is the parsed form body from the request', async () => {
      const formData = {
        examples: [{one: 1, two: 'two'}],
        sample: true,
      }
      sendPostFormRequest('/example', null, formData)
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.formBody).toEqual({
        examples: [{one: '1', two: 'two'}],
        sample: 'true',
      })
    })
  })

  describe('#jsonBody', () => {
    it('is the parsed form body from the request', async () => {
      const formData = {
        examples: [{one: 1, two: 'two'}],
        sample: true,
      }
      sendPostJsonRequest('/example', null, formData)
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.jsonBody).toEqual({
        examples: [{one: 1, two: 'two'}],
        sample: true,
      })
    })
  })

  describe('#response', () => {
    it('is a Response for the request', async () => {
      sendGetRequest('/example')
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.response).toBeInstanceOf(Response)
    })
  })
})

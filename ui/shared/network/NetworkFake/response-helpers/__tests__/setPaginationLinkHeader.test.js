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

import parseLinkHeader from '@canvas/parse-link-header'

import NetworkFake from '../../NetworkFake'
import {sendGetRequest} from '../../specHelpers'
import setPaginationLinkHeader from '../setPaginationLinkHeader'

describe('Shared > Network > NetworkFake > Response Helpers > .setPaginationLinkHeader()', () => {
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

  function getPaginationLinks(xhr) {
    return parseLinkHeader(xhr.getResponseHeader('Link'))
  }

  it('sets the "Link" header on the response', async () => {
    const xhr = sendGetRequest('/example')
    const response = await getResponse()
    setPaginationLinkHeader(response, {first: 2})
    response.send()
    expect(xhr.getResponseHeader('Link')).toContain('/example')
  })

  it('optionally sets the "first" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {first: 2})
    response.send()
    expect(getPaginationLinks(xhr).first.url).toEqual('http://www.example.com/data?page=2')
  })

  it('preserves params on the "first" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data', {sort: 'asc'})
    const response = await getResponse()
    setPaginationLinkHeader(response, {first: 2})
    response.send()
    expect(getPaginationLinks(xhr).first.url).toEqual('http://www.example.com/data?sort=asc&page=2')
  })

  it('ensures the "first" page link has a full protocol and domain', async () => {
    const xhr = sendGetRequest('/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {first: 2})
    response.send()
    expect(getPaginationLinks(xhr).first.url).toEqual('http://canvas.example.com/data?page=2')
  })

  it('optionally omits the "first" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {last: 2})
    response.send()
    expect(getPaginationLinks(xhr).first).toBeUndefined()
  })

  it('optionally sets the "current" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {current: 2})
    response.send()
    expect(getPaginationLinks(xhr).current.url).toEqual('http://www.example.com/data?page=2')
  })

  it('preserves params on the "current" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data', {sort: 'asc'})
    const response = await getResponse()
    setPaginationLinkHeader(response, {current: 2})
    response.send()
    expect(getPaginationLinks(xhr).current.url).toEqual(
      'http://www.example.com/data?sort=asc&page=2'
    )
  })

  it('ensures the "current" page link has a full protocol and domain', async () => {
    const xhr = sendGetRequest('/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {current: 2})
    response.send()
    expect(getPaginationLinks(xhr).current.url).toEqual('http://canvas.example.com/data?page=2')
  })

  it('optionally omits the "current" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {last: 2})
    response.send()
    expect(getPaginationLinks(xhr).current).toBeUndefined()
  })

  it('optionally sets the "next" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {next: 2})
    response.send()
    expect(getPaginationLinks(xhr).next.url).toEqual('http://www.example.com/data?page=2')
  })

  it('preserves params on the "next" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data', {sort: 'asc'})
    const response = await getResponse()
    setPaginationLinkHeader(response, {next: 2})
    response.send()
    expect(getPaginationLinks(xhr).next.url).toEqual('http://www.example.com/data?sort=asc&page=2')
  })

  it('ensures the "next" page link has a full protocol and domain', async () => {
    const xhr = sendGetRequest('/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {next: 2})
    response.send()
    expect(getPaginationLinks(xhr).next.url).toEqual('http://canvas.example.com/data?page=2')
  })

  it('optionally omits the "next" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {last: 2})
    response.send()
    expect(getPaginationLinks(xhr).next).toBeUndefined()
  })

  it('optionally sets the "last" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {last: 2})
    response.send()
    expect(getPaginationLinks(xhr).last.url).toEqual('http://www.example.com/data?page=2')
  })

  it('preserves params on the "last" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data', {sort: 'asc'})
    const response = await getResponse()
    setPaginationLinkHeader(response, {last: 2})
    response.send()
    expect(getPaginationLinks(xhr).last.url).toEqual('http://www.example.com/data?sort=asc&page=2')
  })

  it('ensures the "last" page link has a full protocol and domain', async () => {
    const xhr = sendGetRequest('/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {last: 2})
    response.send()
    expect(getPaginationLinks(xhr).last.url).toEqual('http://canvas.example.com/data?page=2')
  })

  it('optionally omits the "last" page link', async () => {
    const xhr = sendGetRequest('http://www.example.com/data')
    const response = await getResponse()
    setPaginationLinkHeader(response, {first: 2})
    response.send()
    expect(getPaginationLinks(xhr).last).toBeUndefined()
  })
})

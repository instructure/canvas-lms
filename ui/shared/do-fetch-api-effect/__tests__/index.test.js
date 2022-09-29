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

import fetchMock from 'fetch-mock'

import doFetchApi from '../index'

describe('doFetchApi', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('fetches and resolves with json results', () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    fetchMock.mock(`path:${path}`, response)
    return expect(doFetchApi({path})).resolves.toMatchObject({json: {key: 'value'}})
  })

  it('resolves json to undefined when response is empty', () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, 200)
    return expect(doFetchApi({path})).resolves.toMatchObject({json: undefined})
  })

  it('resolve includes response', () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, 200)
    return expect(doFetchApi({path})).resolves.toMatchObject({response: {status: 200}})
  })

  it('resolve includes the parsed link header', () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, {
      headers: {
        Link: '<http://api?page=3>; rel="current",<http://api?page=1>; rel="first",<http://api?page=5>; rel="last", <http://api?page=4>; rel="next", <http://api?page=2>; rel="prev"',
      },
    })
    return expect(doFetchApi({path})).resolves.toMatchObject({
      link: {
        first: {page: '1'},
        prev: {page: '2'},
        current: {page: '3'},
        next: {page: '4'},
        last: {page: '5'},
      },
    })
  })

  it('link is undefined when there is no link header', () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, 200)
    return expect(doFetchApi({path})).resolves.toMatchObject({link: undefined})
  })

  it('rejects on network error', () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, {throws: new Error('network failure')})
    return expect(doFetchApi({path})).rejects.toThrow('network failure')
  })

  it('rejects when not ok and attaches the response', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, 401)
    try {
      expect.hasAssertions()
      await doFetchApi({path})
    } catch (err) {
      expect(err.message).toMatch(/unauthorized/i)
      expect(err.response.status).toBe(401)
    }
  })

  it('encodes params as url parameters', () => {
    const path = '/api/v1/blah'
    const params = {foo: 'bar', baz: 'bing'}
    // Mock both orders so the test doesn't depend on object insertion order
    fetchMock.mock(`end:?foo=bar&baz=bing`, {key: 'value'})
    fetchMock.mock(`end:?baz=bing&foo=bar`, {key: 'value'})
    return expect(doFetchApi({path, params})).resolves.toMatchObject({json: {key: 'value'}})
  })

  it('passes default headers, headers, body, and fetch options', () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, 200)
    const headers = {foo: 'bar', baz: 'bing'}
    document.cookie = '_csrf_token=the_token'
    doFetchApi({path, headers, method: 'POST', body: 'the body', fetchOpts: {additional: 'option'}})
    const [, fetchOptions] = fetchMock.lastCall()
    expect(fetchOptions).toEqual({
      method: 'POST',
      body: 'the body',
      credentials: 'same-origin',
      headers: {
        'X-CSRF-Token': 'the_token',
        Accept: expect.stringMatching(/application\/json\+canvas-string-ids/),
        'X-Requested-With': 'XMLHttpRequest',
        foo: 'bar',
        baz: 'bing',
      },
      additional: 'option',
    })
  })

  it('converts body object to string body and sets content-type', () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, 200)
    doFetchApi({path, body: {the: 'body'}})
    const [, fetchOptions] = fetchMock.lastCall()
    expect(JSON.parse(fetchOptions.body)).toEqual({the: 'body'})
    expect(fetchOptions.headers['Content-Type']).toBe('application/json')
  })
})

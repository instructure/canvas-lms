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

import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

import doFetchApi from '../index'

const server = setupServer()

describe('doFetchApi', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  it('fetches and resolves with json results', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return HttpResponse.json(
          {key: 'value', locale: 'en-US'},
          {headers: {'Content-Type': 'application/json; charset=utf-8'}},
        )
      }),
    )
    const result = await doFetchApi({path})
    expect(result).toMatchObject({json: {key: 'value', locale: 'en-US'}})
  })

  it('fetches and resolves with plain text results', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return HttpResponse.text('just returns a string', {
          headers: {'Content-Type': 'text/plain'},
        })
      }),
    )
    const result = await doFetchApi({path})
    expect(result.json).toBeUndefined()
    expect(result.text).toBe('just returns a string')
  })

  it('resolves json to undefined when response body is empty', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return new HttpResponse('', {
          status: 200,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
        })
      }),
    )
    const result = await doFetchApi({path})
    expect(result.json).toBeUndefined()
  })

  it('resolve includes response', () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return new HttpResponse(null, {status: 200})
      }),
    )
    return expect(doFetchApi({path})).resolves.toMatchObject({response: {status: 200}})
  })

  it('resolve includes the parsed link header', () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return new HttpResponse(null, {
          headers: {
            Link: '<http://api?page=3>; rel="current",<http://api?page=1>; rel="first",<http://api?page=5>; rel="last", <http://api?page=4>; rel="next", <http://api?page=2>; rel="prev"',
          },
        })
      }),
    )
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

  it('returns undefined link when there is no link header', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return new HttpResponse(null, {status: 200})
      }),
    )
    const result = await doFetchApi({path})
    expect(result.link).toBeUndefined()
  })

  it('rejects on network error', () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return HttpResponse.error()
      }),
    )
    return expect(doFetchApi({path})).rejects.toThrow()
  })

  it('rejects when not ok and attaches the response', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return new HttpResponse(null, {status: 401})
      }),
    )
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
    server.use(
      http.get(path, ({request}) => {
        const url = new URL(request.url)
        const searchParams = url.searchParams
        if (
          (searchParams.get('foo') === 'bar' && searchParams.get('baz') === 'bing') ||
          (searchParams.get('baz') === 'bing' && searchParams.get('foo') === 'bar')
        ) {
          return HttpResponse.json({key: 'value'})
        }
      }),
    )
    return expect(doFetchApi({path, params})).resolves.toMatchObject({json: {key: 'value'}})
  })

  it('passes default headers, headers, body, and fetch options', async () => {
    const path = '/api/v1/blah'
    let capturedRequest
    server.use(
      http.post(path, async ({request}) => {
        capturedRequest = {
          headers: Object.fromEntries(request.headers.entries()),
          body: await request.text(),
          method: request.method,
        }
        return new HttpResponse(null, {status: 200})
      }),
    )
    const headers = new Headers({foo: 'bar', baz: 'bing'})
    document.cookie = '_csrf_token=the_token'
    await doFetchApi({
      path,
      headers,
      method: 'POST',
      body: 'the body',
      fetchOpts: {additional: 'option'},
    })
    expect(capturedRequest.method).toBe('POST')
    expect(capturedRequest.body).toBe('the body')
    expect(capturedRequest.headers).toMatchObject({
      'x-csrf-token': 'the_token',
      accept: expect.stringMatching(/application\/json\+canvas-string-ids/),
      'x-requested-with': 'XMLHttpRequest',
      foo: 'bar',
      baz: 'bing',
    })
  })

  it('does not allow sneaking in headers via fetchOpts', async () => {
    const path = '/api/v1/blah'
    let capturedHeaders
    server.use(
      http.get(path, ({request}) => {
        capturedHeaders = Object.fromEntries(request.headers.entries())
        return HttpResponse.json({key: 'value'})
      }),
    )
    const headers = new Headers({foo: 'bar'})
    const fetchOpts = {headers: {baz: 'bing'}}
    await doFetchApi({path, headers, fetchOpts})
    expect(capturedHeaders.baz).toBeUndefined()
    expect(capturedHeaders.foo).toBe('bar')
  })

  it('converts body object to string body and overrides content-type to JSON', async () => {
    const path = '/api/v1/blah'
    let capturedRequest
    server.use(
      http.post(path, async ({request}) => {
        capturedRequest = {
          headers: Object.fromEntries(request.headers.entries()),
          body: await request.text(),
        }
        return new HttpResponse(null, {status: 200})
      }),
    )
    await doFetchApi({
      path,
      method: 'POST',
      body: {the: 'body'},
      headers: {'Content-Type': 'application/octet-stream'},
    })
    expect(JSON.parse(capturedRequest.body)).toEqual({the: 'body'})
    expect(capturedRequest.headers['content-type']).toBe('application/json')
  })

  it('handles string body correctly without altering it or setting Content-Type', async () => {
    const path = '/api/v1/string-body-test'
    const body = 'this is a plain string'
    let capturedRequest
    server.use(
      http.post(path, async ({request}) => {
        capturedRequest = {
          headers: Object.fromEntries(request.headers.entries()),
          body: await request.text(),
        }
        return new HttpResponse(null, {status: 200})
      }),
    )
    await doFetchApi({path, method: 'POST', body})
    expect(capturedRequest.body).toBe(body)
    // When posting a string body, fetch may add text/plain content-type automatically
    const contentType = capturedRequest.headers['content-type']
    expect(!contentType || contentType.includes('text/plain')).toBe(true)
  })

  it('respects manually-set Content-Type for a text body', async () => {
    const path = '/api/v1/string-body-test'
    const body = '<p>this is an html string</p>'
    const headers = {'Content-Type': 'text/html'}
    let capturedRequest
    server.use(
      http.post(path, async ({request}) => {
        capturedRequest = {
          headers: Object.fromEntries(request.headers.entries()),
          body: await request.text(),
        }
        return new HttpResponse(null, {status: 200})
      }),
    )
    await doFetchApi({path, method: 'POST', body, headers})
    expect(capturedRequest.body).toBe(body)
    expect(capturedRequest.headers['content-type']).toBe('text/html')
  })

  describe('handles FormData correctly', () => {
    it('does not stringify FormData and does not set a Content-Type', async () => {
      const path = '/api/v1/formdata-test'
      let capturedRequest
      server.use(
        http.post(path, async ({request}) => {
          const contentType = request.headers.get('content-type') || ''
          capturedRequest = {
            headers: Object.fromEntries(request.headers.entries()),
            bodyIsFormData: contentType.includes('multipart/form-data'),
          }
          return new HttpResponse(null, {status: 200})
        }),
      )
      const formData = new FormData()
      formData.append('key', 'value')
      await doFetchApi({path, method: 'POST', body: formData})
      expect(capturedRequest.bodyIsFormData).toBe(true)
      const contentType = capturedRequest.headers['content-type']
      expect(!contentType || contentType.includes('multipart/form-data')).toBe(true)
    })

    it('sends FormData along with other headers correctly', async () => {
      const path = '/api/v1/formdata-headers-test'
      let capturedRequest
      server.use(
        http.post(path, async ({request}) => {
          const contentType = request.headers.get('content-type') || ''
          capturedRequest = {
            headers: Object.fromEntries(request.headers.entries()),
            bodyIsFormData: contentType.includes('multipart/form-data'),
          }
          return new HttpResponse(null, {status: 200})
        }),
      )
      const formData = new FormData()
      formData.append('key', 'value')
      const headers = {foo: 'bar'}
      await doFetchApi({path, method: 'POST', body: formData, headers})
      expect(capturedRequest.bodyIsFormData).toBe(true)
      expect(capturedRequest.headers.foo).toBe('bar')
      const contentType = capturedRequest.headers['content-type']
      expect(!contentType || contentType.includes('multipart/form-data')).toBe(true)
    })

    it('handles FormData with no additional headers', async () => {
      const path = '/api/v1/formdata-no-headers'
      let capturedRequest
      server.use(
        http.post(path, async ({request}) => {
          const contentType = request.headers.get('content-type') || ''
          capturedRequest = {
            headers: Object.fromEntries(request.headers.entries()),
            bodyIsFormData: contentType.includes('multipart/form-data'),
          }
          return new HttpResponse(null, {status: 200})
        }),
      )
      const formData = new FormData()
      formData.append('key', 'value')
      await doFetchApi({path, method: 'POST', body: formData})
      expect(capturedRequest.bodyIsFormData).toBe(true)
      const contentType =
        capturedRequest.headers['content-type'] || capturedRequest.headers['Content-Type']
      expect(!contentType || contentType.includes('multipart/form-data')).toBe(true)
    })

    it('handles FormData with multiple values for a single key', async () => {
      const path = '/api/v1/formdata-multiple-values'
      let capturedRequest
      server.use(
        http.post(path, async ({request}) => {
          const contentType = request.headers.get('content-type') || ''
          capturedRequest = {
            headers: Object.fromEntries(request.headers.entries()),
            bodyIsFormData: contentType.includes('multipart/form-data'),
          }
          return new HttpResponse(null, {status: 200})
        }),
      )
      const formData = new FormData()
      formData.append('files', new Blob(['file1']), 'file1.txt')
      formData.append('files', new Blob(['file2']), 'file2.txt')
      await doFetchApi({path, method: 'POST', body: formData})
      expect(capturedRequest.bodyIsFormData).toBe(true)
      const contentType = capturedRequest.headers['content-type']
      expect(!contentType || contentType.includes('multipart/form-data')).toBe(true)
    })

    it('removes manually set Content-Type header when using FormData', async () => {
      const path = '/api/v1/formdata-custom-content-type'
      let capturedRequest
      server.use(
        http.post(path, async ({request}) => {
          const contentType = request.headers.get('content-type') || ''
          capturedRequest = {
            headers: Object.fromEntries(request.headers.entries()),
            bodyIsFormData: contentType.includes('multipart/form-data'),
          }
          return new HttpResponse(null, {status: 200})
        }),
      )
      const formData = new FormData()
      formData.append('key', 'value')
      const headers = {'Content-Type': 'multipart/form-data'}
      await doFetchApi({path, method: 'POST', body: formData, headers})
      expect(capturedRequest.bodyIsFormData).toBe(true)
      const contentType = capturedRequest.headers['content-type']
      expect(!contentType || contentType.includes('multipart/form-data')).toBe(true)
    })

    it('handles FormData with empty entries correctly', async () => {
      const path = '/api/v1/formdata-empty-entries'
      let capturedRequest
      server.use(
        http.post(path, async ({request}) => {
          const contentType = request.headers.get('content-type') || ''
          capturedRequest = {
            headers: Object.fromEntries(request.headers.entries()),
            bodyIsFormData: contentType.includes('multipart/form-data'),
          }
          return new HttpResponse(null, {status: 200})
        }),
      )
      const formData = new FormData()
      formData.append('key1', 'value1')
      formData.append('emptyKey', '')
      await doFetchApi({path, method: 'POST', body: formData})
      expect(capturedRequest.bodyIsFormData).toBe(true)
      const contentType = capturedRequest.headers['content-type']
      expect(!contentType || contentType.includes('multipart/form-data')).toBe(true)
    })
  })
})

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
import {renderHook} from '@testing-library/react-hooks/dom'
import {waitFor} from '@testing-library/react'
// eslint-disable-next-line import/no-nodejs-modules
import EventEmitter from 'events'
import useFetchApi from '../index'

// A lot of promises are involved here and we don't have access to them to know when they have all
// been resolved, even with fetchMock.flush. So instead we have to wait for a function to be
// called some number of times to know that the loading has been completed.
function makeEventedFn({times = 1, arg}) {
  const ee = new EventEmitter()
  const promise = new Promise(resolve => ee.on('done', resolve))
  let fn
  if (arg !== undefined) {
    fn = vi.fn(p => {
      if (p === arg) ee.emit('done')
    })
  } else {
    fn = vi.fn(() => {
      times -= 1
      if (times <= 0) ee.emit('done')
    })
  }
  return [fn, promise]
}

const server = setupServer()

describe('useFetchApi', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => {
    server.resetHandlers()
  })

  it('reports loading status', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    server.use(
      http.get(path, () => {
        return HttpResponse.json(response)
      }),
    )
    const loading = vi.fn()
    renderHook(() => useFetchApi({loading, path}))
    expect(loading).toHaveBeenCalledTimes(1)
    expect(loading).toHaveBeenCalledWith(true)
    await waitFor(() => {
      expect(loading).toHaveBeenCalledWith(false)
    })
  })

  it('fetches and reports success and meta with results', async () => {
    const path = '/api/v1/blah'
    const body = {key: 'value'}
    server.use(
      http.get(path, () => {
        return HttpResponse.json(body, {
          headers: {Link: '<http://api?page=1>;rel="first"'},
        })
      }),
    )
    const success = vi.fn()
    const meta = vi.fn()
    const error = vi.fn()
    renderHook(() => useFetchApi({success, error, meta, path}))
    await waitFor(() => {
      expect(success).toHaveBeenCalledWith(body)
    })
    expect(meta).toHaveBeenCalled()
    expect(meta.mock.calls[0][0]).toMatchObject({
      link: {first: {page: '1'}},
      response: {status: 200},
    })
    expect(error).not.toHaveBeenCalled()
  })

  it('fails when response is not ok', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return new HttpResponse(null, {status: 401})
      }),
    )
    const success = vi.fn()
    const meta = vi.fn()
    const error = vi.fn()
    const loading = vi.fn()
    renderHook(() => useFetchApi({success, error, meta, loading, path}))
    await waitFor(() => {
      expect(error).toHaveBeenCalled()
    })
    expect(success).not.toHaveBeenCalled()
    expect(meta).not.toHaveBeenCalled()
    expect(error.mock.calls[0][0].response.status).toEqual(401)
    expect(loading).toHaveBeenCalledWith(false)
  })

  it('fails when there is a network error', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return HttpResponse.error()
      }),
    )
    const success = vi.fn()
    const error = vi.fn()
    const loading = vi.fn()
    renderHook(() => useFetchApi({success, error, loading, path}))
    await waitFor(() => {
      expect(error).toHaveBeenCalled()
    })
    expect(success).not.toHaveBeenCalled()
    expect(error.mock.calls[0][0].toString()).toMatch(/Failed to fetch/)
    expect(loading).toHaveBeenCalledWith(false)
  })

  it('passes params via url', async () => {
    const path = '/api/v1/blah'
    let capturedUrl = ''
    server.use(
      http.get(path, ({request}) => {
        capturedUrl = request.url
        return new HttpResponse(null, {status: 200})
      }),
    )
    const success = vi.fn()
    renderHook(() => useFetchApi({path: '/api/v1/blah', params: {foo: 'bar'}, success}))
    await waitFor(() => {
      expect(capturedUrl).toMatch(/\?foo=bar/)
    })
  })

  it('passes headers and options to fetch', async () => {
    const path = '/api/v1/blah'
    let capturedHeaders = {}
    server.use(
      http.get(path, ({request}) => {
        capturedHeaders = Object.fromEntries(request.headers.entries())
        return HttpResponse.json({key: 'value'})
      }),
    )
    const success = vi.fn()
    renderHook(() =>
      useFetchApi({path, headers: {header: 'value'}, fetchOpts: {blah: 'frog'}, success}),
    )
    await waitFor(() => {
      expect(success).toHaveBeenCalled()
    })
    expect(capturedHeaders.header).toBe('value')
    expect(capturedHeaders.accept).toMatch(/application\/json\+canvas-string-ids/)
  })

  it('applies the convert function to the results before passing it to success', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return HttpResponse.json({foo: 42})
      }),
    )
    const convert = vi.fn(() => ({bar: 'baz'}))
    const success = vi.fn()
    renderHook(() => useFetchApi({success, path, convert}))
    await waitFor(() => {
      expect(success).toHaveBeenCalledWith({bar: 'baz'})
    })
    expect(convert).toHaveBeenCalledWith({foo: 42})
  })

  it('does not call convert if result is falsey', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return new HttpResponse(null, {status: 200})
      }),
    )
    const convert = vi.fn()
    const success = vi.fn()
    renderHook(() => useFetchApi({success, path, convert}))
    await waitFor(() => {
      expect(success).toHaveBeenCalledWith(undefined)
    })
    expect(convert).not.toHaveBeenCalled()
  })

  it('fetches again if path has changed', async () => {
    const response = {key: 'value'}
    server.use(
      http.get('*/blah', () => {
        return HttpResponse.json(response)
      }),
      http.get('*/frog', () => {
        return HttpResponse.json(response)
      }),
    )
    const success = vi.fn()
    const meta = vi.fn()
    const error = vi.fn()
    const {rerender} = renderHook(({path}) => useFetchApi({success, error, meta, path}), {
      initialProps: {path: '/api/v1/blah'},
    })
    await waitFor(() => {
      expect(success).toHaveBeenCalledTimes(1)
    })
    rerender({path: '/api/v1/frog'})
    await waitFor(() => {
      expect(success).toHaveBeenCalledTimes(2)
    })
    expect(meta).toHaveBeenCalledTimes(2)
    expect(error).not.toHaveBeenCalled()
  })

  it('fetches again if params have changed', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    server.use(
      http.get(path, () => {
        return HttpResponse.json(response)
      }),
    )
    const success = vi.fn()
    const error = vi.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, error, path, params}), {
      initialProps: {params: {foo: 42}},
    })
    await waitFor(() => {
      expect(success).toHaveBeenCalledTimes(1)
    })
    rerender({params: {foo: 44}})
    await waitFor(() => {
      expect(success).toHaveBeenCalledTimes(2)
    })
    expect(error).not.toHaveBeenCalled()
  })

  it('fetches again if headers have changed', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    server.use(
      http.get(path, () => {
        return HttpResponse.json(response)
      }),
    )
    const success = vi.fn()
    const error = vi.fn()
    const {rerender} = renderHook(({headers}) => useFetchApi({success, error, path, headers}), {
      initialProps: {headers: {foo: 42}},
    })
    await waitFor(() => {
      expect(success).toHaveBeenCalledTimes(1)
    })
    rerender({headers: {foo: 44}})
    await waitFor(() => {
      expect(success).toHaveBeenCalledTimes(2)
    })
    expect(error).not.toHaveBeenCalled()
  })

  it('fetches again if fetchOpts have changed', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    server.use(
      http.get(path, () => {
        return HttpResponse.json(response)
      }),
    )
    const success = vi.fn()
    const error = vi.fn()
    const {rerender} = renderHook(({fetchOpts}) => useFetchApi({success, error, path, fetchOpts}), {
      initialProps: {fetchOpts: {foo: 42}},
    })
    await waitFor(() => {
      expect(success).toHaveBeenCalledTimes(1)
    })
    rerender({fetchOpts: {foo: 44}})
    await waitFor(() => {
      expect(success).toHaveBeenCalledTimes(2)
    })
    expect(error).not.toHaveBeenCalled()
  })

  it('does not fetch again if nothing has changed', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    let requestCount = 0
    server.use(
      http.get(path, () => {
        requestCount++
        return HttpResponse.json(response)
      }),
    )
    const success = vi.fn()
    const error = vi.fn()
    const {rerender} = renderHook(props => useFetchApi({success, error, ...props}), {
      initialProps: {
        path,
        params: {foo: 42},
        headers: {bar: 43},
        fetchOpts: {bing: 44},
      },
    })
    await waitFor(() => {
      expect(success).toHaveBeenCalledTimes(1)
    })
    rerender({
      path,
      params: {foo: 42},
      headers: {bar: 43},
      fetchOpts: {bing: 44},
    })
    // Wait a bit to ensure no additional requests are made
    await new Promise(resolve => setTimeout(resolve, 100))
    expect(requestCount).toBe(1)
    expect(success).toHaveBeenCalledTimes(1)
    expect(error).not.toHaveBeenCalled()
  })

  it('reports forceResult when specified, without calling fetch', () => {
    const success = vi.fn()
    const meta = vi.fn()
    renderHook(() => useFetchApi({success, meta, path: '/blah', forceResult: {fake: 'news'}}))
    expect(success).toHaveBeenCalledWith({fake: 'news'})
    expect(meta).not.toHaveBeenCalled()
  })

  it('only reports forceResult once if it has not changed', () => {
    const success = vi.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {
      initialProps: {success, path: '/blah', forceResult: {fake: 'news'}},
    })
    expect(success).toHaveBeenCalledWith({fake: 'news'})
    rerender({success, path: '/blah', forceResult: {fake: 'news'}})
    expect(success).toHaveBeenCalledTimes(1)
  })

  it('reports new results if forceResult is changed', () => {
    const success = vi.fn()
    const meta = vi.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {
      initialProps: {success, meta, path: '/blah', forceResult: {fake: 'news'}},
    })
    expect(success).toHaveBeenCalledWith({fake: 'news'})
    rerender({success, path: '/blah', forceResult: {other: 'thing'}})
    expect(success).toHaveBeenCalledTimes(2)
    expect(meta).not.toHaveBeenCalled()
    expect(success).toHaveBeenCalledWith({other: 'thing'})
  })

  it('invokes fetch if forceResult is changed to undefined', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return HttpResponse.json({fetch: 'result'})
      }),
    )
    const success = vi.fn()
    const meta = vi.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {
      initialProps: {success, meta, path, forceResult: {fake: 'news'}},
    })
    rerender({success, meta, path})
    await waitFor(() => {
      expect(success).toHaveBeenCalledWith({fetch: 'result'})
    })
    expect(meta).toHaveBeenCalledWith(
      expect.objectContaining({link: undefined, response: expect.anything()}),
    )
  })

  it('reports forceResult if changed from undefined', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, () => {
        return HttpResponse.json({fetch: 'result'})
      }),
    )
    const success = vi.fn()
    const meta = vi.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {
      initialProps: {success, meta, path},
    })
    await waitFor(() => {
      expect(success).toHaveBeenCalledWith({fetch: 'result'})
    })
    rerender({success, meta, path, forceResult: {force: 'value'}})
    expect(success).toHaveBeenCalledWith({force: 'value'})
    expect(meta).toHaveBeenCalledTimes(1)
  })

  it('ignores first success results if another fetch starts before it finishes', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, ({request}) => {
        const url = new URL(request.url)
        const foo = url.searchParams.get('foo')
        if (foo === '42') {
          return HttpResponse.json({first: 41})
        } else if (foo === '44') {
          return HttpResponse.json({second: 42})
        }
      }),
    )
    const success = vi.fn()
    const meta = vi.fn()
    const error = vi.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, meta, error, path, params}), {
      initialProps: {params: {foo: 42}},
    })
    // don't wait for flush, just start another one
    rerender({params: {foo: 44}})
    await waitFor(() => {
      expect(success).toHaveBeenCalledWith({second: 42})
    })
    expect(success).toHaveBeenCalledTimes(1)
    expect(meta).toHaveBeenCalledTimes(1)
    expect(meta).toHaveBeenCalledWith(expect.objectContaining({link: undefined}))
    expect(error).not.toHaveBeenCalled()
  })

  it('ignores first fetch error and reports success if another fetch starts before it finishes', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, ({request}) => {
        const url = new URL(request.url)
        const foo = url.searchParams.get('foo')
        if (foo === '42') {
          return new HttpResponse(null, {status: 401})
        } else if (foo === '44') {
          return HttpResponse.json({second: 42})
        }
      }),
    )
    const success = vi.fn()
    const error = vi.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, error, path, params}), {
      initialProps: {params: {foo: 42}},
    })
    // don't wait for flush, just start another one
    rerender({params: {foo: 44}})
    await waitFor(() => {
      expect(success).toHaveBeenCalledWith({second: 42})
    })
    expect(success).toHaveBeenCalledTimes(1)
    expect(error).not.toHaveBeenCalled()
  })

  it('ignores first fetch success and reports error if another fetch errors before it finishes', async () => {
    const path = '/api/v1/blah'
    server.use(
      http.get(path, ({request}) => {
        const url = new URL(request.url)
        const foo = url.searchParams.get('foo')
        if (foo === '42') {
          return HttpResponse.json({first: 42})
        } else if (foo === '44') {
          return new HttpResponse(null, {status: 401})
        }
      }),
    )
    const success = vi.fn()
    const error = vi.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, error, path, params}), {
      initialProps: {params: {foo: 42}},
    })
    // don't wait for flush, just start another one
    rerender({params: {foo: 44}})
    await waitFor(() => {
      expect(error).toHaveBeenCalled()
    })
    expect(success).not.toHaveBeenCalled()
    expect(error.mock.calls[0][0].response.status).toBe(401)
  })

  describe('additionalDependencies', () => {
    it('fetches again if additionalDependencies change', async () => {
      const path = '/api/v1/blah'
      const response = {key: 'value'}
      server.use(
        http.get(path, () => {
          return HttpResponse.json(response)
        }),
      )
      const success = vi.fn()
      const error = vi.fn()
      const {rerender} = renderHook(({nonce}) => useFetchApi({success, error, path}, [nonce]), {
        initialProps: {nonce: 'foo'},
      })
      await waitFor(() => {
        expect(success).toHaveBeenCalledTimes(1)
      })
      rerender({nonce: 'baz'})
      await waitFor(() => {
        expect(success).toHaveBeenCalledTimes(2)
      })
      expect(error).not.toHaveBeenCalled()
    })

    it('does not fetch again if additionalDependencies do not change', async () => {
      const path = '/api/v1/blah'
      const response = {key: 'value'}
      let requestCount = 0
      server.use(
        http.get(path, () => {
          requestCount++
          return HttpResponse.json(response)
        }),
      )
      const success = vi.fn()
      const error = vi.fn()
      const {rerender} = renderHook(({nonce}) => useFetchApi({success, error, path}, [nonce]), {
        initialProps: {nonce: 'foo'},
      })
      await waitFor(() => {
        expect(success).toHaveBeenCalledTimes(1)
      })
      rerender({nonce: 'foo'})
      // Wait a bit to ensure no additional requests are made
      await new Promise(resolve => setTimeout(resolve, 100))
      expect(requestCount).toBe(1)
      expect(success).toHaveBeenCalledTimes(1)
      expect(error).not.toHaveBeenCalled()
    })
  })

  describe('fetchAllPages', () => {
    it('fetches multiple pages if fetchAllPages is true', async () => {
      const path = '/api'
      server.use(
        http.get(path, ({request}) => {
          const url = new URL(request.url)
          const page = url.searchParams.get('page')
          if (!page) {
            return HttpResponse.json(['a'], {
              headers: {link: `<${path}?page=2>;rel="next"`},
            })
          } else if (page === '2') {
            return HttpResponse.json(['b', 'c'], {
              headers: {link: `<${path}?page=3>;rel="next"`},
            })
          } else if (page === '3') {
            return HttpResponse.json(['d', 'e'])
          }
        }),
      )
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const success = vi.fn()
      const meta = vi.fn()
      const error = vi.fn()
      renderHook(() => useFetchApi({path, loading, success, meta, error, fetchAllPages: true}))
      await loadingDone
      expect(loading).toHaveBeenCalledTimes(2)
      expect(loading).toHaveBeenNthCalledWith(1, true)
      expect(loading).toHaveBeenNthCalledWith(2, false)

      expect(success).toHaveBeenCalledTimes(3)
      expect(success).toHaveBeenNthCalledWith(1, ['a'])
      expect(success).toHaveBeenNthCalledWith(2, ['a', 'b', 'c'])
      expect(success).toHaveBeenNthCalledWith(3, ['a', 'b', 'c', 'd', 'e'])

      expect(meta).toHaveBeenCalledTimes(3)
      expect(meta.mock.calls[0][0]).toMatchObject({link: {next: {page: '2'}}})
      expect(meta.mock.calls[1][0]).toMatchObject({link: {next: {page: '3'}}})
      expect(meta.mock.calls[2][0]).toMatchObject({link: undefined})

      expect(error).not.toHaveBeenCalled()
    })

    it('errors if any page fails', async () => {
      const path = '/api'
      server.use(
        http.get(path, ({request}) => {
          const url = new URL(request.url)
          const page = url.searchParams.get('page')
          if (!page) {
            return HttpResponse.json(['a'], {
              headers: {link: `<${path}?page=2>;rel="next"`},
            })
          } else if (page === '2') {
            return new HttpResponse(null, {status: 401})
          }
        }),
      )
      const success = vi.fn()
      const error = vi.fn()
      const [loading, loadingDone] = makeEventedFn({arg: false})
      renderHook(() => useFetchApi({path, loading, success, error, fetchAllPages: true}))
      await loadingDone
      expect(success).toHaveBeenCalledTimes(1)
      expect(success).toHaveBeenCalledWith(['a'])
      expect(error).toHaveBeenCalledTimes(1)
      expect(error.mock.calls[0][0].message).toMatch(/unauthorized/i)
    })

    it('aborts and fetches again if fetchAllPages changes', async () => {
      const path = '/api'
      server.use(
        http.get(path, () => {
          return HttpResponse.json(
            {foo: 'bar'},
            {
              headers: {link: `<${path}?page=bar>;rel="next"`},
            },
          )
        }),
      )
      const success = vi.fn()
      const error = vi.fn()
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const {rerender} = renderHook(
        ({fetchAllPages}) => useFetchApi({path, loading, success, error, fetchAllPages}),
        {initialProps: {fetchAllPages: true}},
      )
      rerender({fetchAllPages: false})
      await loadingDone
      expect(success).toHaveBeenCalledTimes(1)
      expect(success).toHaveBeenCalledWith({foo: 'bar'}) // called with object instead of array with object
      expect(error).not.toHaveBeenCalled()
    })

    it('calls convert on all pages of data', async () => {
      const path = '/api'
      server.use(
        http.get(path, ({request}) => {
          const url = new URL(request.url)
          const page = url.searchParams.get('page')
          if (!page) {
            return HttpResponse.json([1], {
              headers: {link: `<${path}?page=2>;rel="next"`},
            })
          } else if (page === '2') {
            return HttpResponse.json([2, 3], {
              headers: {link: `<${path}?page=3>;rel="next"`},
            })
          } else if (page === '3') {
            return HttpResponse.json([4, 5])
          }
        }),
      )
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const success = vi.fn()
      const meta = vi.fn()
      const error = vi.fn()
      const convert = page => page.map(n => n + 10)
      renderHook(() =>
        useFetchApi({path, loading, success, meta, error, convert, fetchAllPages: true}),
      )
      await loadingDone
      expect(success).toHaveBeenCalledWith([11, 12, 13, 14, 15])
    })

    it('works with bookmarked pages', async () => {
      const path = '/api'
      server.use(
        http.get(path, ({request}) => {
          const url = new URL(request.url)
          const page = url.searchParams.get('page')
          if (!page) {
            return HttpResponse.json([1], {
              headers: {link: `<${path}?page=foo>;rel="next"`},
            })
          } else if (page === 'foo') {
            return HttpResponse.json([2, 3], {
              headers: {link: `<${path}?page=bar>;rel="next"`},
            })
          } else if (page === 'bar') {
            return HttpResponse.json([4, 5])
          }
        }),
      )
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const success = vi.fn()
      const meta = vi.fn()
      const error = vi.fn()
      renderHook(() => useFetchApi({path, loading, success, meta, error, fetchAllPages: true}))
      await loadingDone
      expect(success).toHaveBeenCalledWith([1, 2, 3, 4, 5])
    })
  })

  describe('fetchNumPages param', () => {
    const path = '/api'

    beforeEach(() => {
      server.use(
        http.get(path, ({request}) => {
          const url = new URL(request.url)
          const page = url.searchParams.get('page')
          if (!page) {
            return HttpResponse.json(['a'], {
              headers: {link: `<${path}?page=2>;rel="next"`},
            })
          } else if (page === '2') {
            return HttpResponse.json(['b'], {
              headers: {link: `<${path}?page=3>;rel="next"`},
            })
          } else if (page === '3') {
            return HttpResponse.json(['c'], {
              headers: {link: `<${path}?page=4>;rel="next"`},
            })
          } else if (page === '4') {
            return HttpResponse.json(['d'], {
              headers: {link: `<${path}?page=5>;rel="next"`},
            })
          } else if (page === '5') {
            return HttpResponse.json(['e'])
          }
        }),
      )
    })

    it('fetches n pages if fetchNumPages is passed', async () => {
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const success = vi.fn()
      const meta = vi.fn()
      const error = vi.fn()

      renderHook(() => useFetchApi({path, loading, success, meta, error, fetchNumPages: 3}))
      await loadingDone

      expect(error).not.toHaveBeenCalled()

      expect(loading).toHaveBeenCalledTimes(2)
      expect(loading).toHaveBeenNthCalledWith(1, true)
      expect(loading).toHaveBeenNthCalledWith(2, false)

      expect(success).toHaveBeenCalledTimes(3)
      expect(success).toHaveBeenNthCalledWith(1, ['a'])
      expect(success).toHaveBeenNthCalledWith(2, ['a', 'b'])
      expect(success).toHaveBeenNthCalledWith(3, ['a', 'b', 'c'])
    })

    it('works if there are fewer pages than fetchNumPages', async () => {
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const success = vi.fn()
      const meta = vi.fn()
      const error = vi.fn()

      renderHook(() => useFetchApi({path, loading, success, meta, error, fetchNumPages: 10}))
      await loadingDone

      expect(error).not.toHaveBeenCalled()

      expect(success).toHaveBeenCalledTimes(5)
      expect(success).toHaveBeenNthCalledWith(1, ['a'])
      expect(success).toHaveBeenNthCalledWith(2, ['a', 'b'])
      expect(success).toHaveBeenNthCalledWith(3, ['a', 'b', 'c'])
      expect(success).toHaveBeenNthCalledWith(4, ['a', 'b', 'c', 'd'])
      expect(success).toHaveBeenNthCalledWith(5, ['a', 'b', 'c', 'd', 'e'])
    })

    it('gets overridden by fetchAllPages', async () => {
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const success = vi.fn()
      const meta = vi.fn()
      const error = vi.fn()

      renderHook(() =>
        useFetchApi({
          path,
          loading,
          success,
          meta,
          error,
          fetchAllPages: true,
          fetchNumPages: 1,
        }),
      )
      await loadingDone

      expect(error).not.toHaveBeenCalled()
      expect(success).toHaveBeenCalledTimes(5)
      expect(success).toHaveBeenNthCalledWith(5, ['a', 'b', 'c', 'd', 'e'])
    })
  })
})

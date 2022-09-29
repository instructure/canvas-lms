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
import {renderHook} from '@testing-library/react-hooks/dom'
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
    fn = jest.fn(p => {
      if (p === arg) ee.emit('done')
    })
  } else {
    fn = jest.fn(() => {
      times -= 1
      if (times <= 0) ee.emit('done')
    })
  }
  return [fn, promise]
}

describe('useFetchApi', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('reports loading status', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    fetchMock.mock(`path:${path}`, response)
    const loading = jest.fn()
    renderHook(() => useFetchApi({loading, path}))
    expect(loading).toHaveBeenCalledTimes(1)
    expect(loading).toHaveBeenCalledWith(true)
    await fetchMock.flush(true)
    expect(loading).toHaveBeenCalledWith(false)
  })

  it('fetches and reports success and meta with results', async () => {
    const path = '/api/v1/blah'
    const response = {headers: {Link: '<http://api?page=1>;rel="first"'}, body: {key: 'value'}}
    fetchMock.mock(`path:${path}`, response)
    const success = jest.fn()
    const meta = jest.fn()
    const error = jest.fn()
    renderHook(() => useFetchApi({success, error, meta, path}))
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledWith(response.body)
    expect(meta).toHaveBeenCalled()
    expect(meta.mock.calls[0][0]).toMatchObject({
      link: {first: {page: '1'}},
      response: {status: 200},
    })
    expect(error).not.toHaveBeenCalled()
  })

  it('fails when response is not ok', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, 401)
    const success = jest.fn()
    const meta = jest.fn()
    const error = jest.fn()
    const loading = jest.fn()
    renderHook(() => useFetchApi({success, error, meta, loading, path}))
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).not.toHaveBeenCalled()
    expect(meta).not.toHaveBeenCalled()
    expect(error.mock.calls[0][0].response.status).toEqual(401)
    expect(loading).toHaveBeenCalledWith(false)
  })

  it('fails when there is a network error', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, {throws: new Error('network failure')})
    const success = jest.fn()
    const error = jest.fn()
    const loading = jest.fn()
    renderHook(() => useFetchApi({success, error, loading, path}))
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).not.toHaveBeenCalled()
    expect(error.mock.calls[0][0].toString()).toMatch('network failure')
    expect(loading).toHaveBeenCalledWith(false)
  })

  it('passes params via url', () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, 200)
    renderHook(() => useFetchApi({path: '/api/v1/blah', params: {foo: 'bar'}}))
    const [url] = fetchMock.lastCall()
    expect(url).toMatch(/\?foo=bar/)
  })

  it('passes headers and options to fetch', () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, {key: 'value'})
    renderHook(() => useFetchApi({path, headers: {header: 'value'}, fetchOpts: {blah: 'frog'}}))
    const [, options] = fetchMock.lastCall()
    expect(options.headers).toEqual(expect.objectContaining({header: 'value'}))
    expect(options.headers.Accept).toMatch(/application\/json\+canvas-string-ids/)
    expect(options.blah).toBe('frog')
  })

  it('applies the convert function to the results before passing it to success', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, {foo: 42})
    const convert = jest.fn(() => ({bar: 'baz'}))
    const success = jest.fn()
    renderHook(() => useFetchApi({success, path, convert}))
    await fetchMock.flush(true)
    expect(convert).toHaveBeenCalledWith({foo: 42})
    expect(success).toHaveBeenCalledWith({bar: 'baz'})
  })

  it('does not call convert if result is falsey', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, 200)
    const convert = jest.fn()
    const success = jest.fn()
    renderHook(() => useFetchApi({success, path, convert}))
    await fetchMock.flush(true)
    expect(convert).not.toHaveBeenCalled()
    expect(success).toHaveBeenCalledWith(undefined)
  })

  it('fetches again if path has changed', async () => {
    const response = {key: 'value'}
    fetchMock.mock('end:blah', response, {repeat: 1})
    fetchMock.mock('end:frog', response, {repeat: 1})
    const success = jest.fn()
    const meta = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(({path}) => useFetchApi({success, error, meta, path}), {
      initialProps: {path: '/api/v1/blah'},
    })
    await fetchMock.flush(true)
    rerender({path: '/api/v1/frog'})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledTimes(2)
    expect(meta).toHaveBeenCalledTimes(2)
    expect(error).not.toHaveBeenCalled()
  })

  it('fetches again if params have changed', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    fetchMock.mock(`path:${path}`, response, {repeat: 2})
    const success = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, error, path, params}), {
      initialProps: {params: {foo: 42}},
    })
    await fetchMock.flush(true)
    rerender({params: {foo: 44}})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledTimes(2)
    expect(error).not.toHaveBeenCalled()
  })

  it('fetches again if headers have changed', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    fetchMock.mock(`path:${path}`, response, {repeat: 2})
    const success = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(({headers}) => useFetchApi({success, error, path, headers}), {
      initialProps: {headers: {foo: 42}},
    })
    await fetchMock.flush(true)
    rerender({headers: {foo: 44}})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledTimes(2)
    expect(error).not.toHaveBeenCalled()
  })

  it('fetches again if fetchOpts have changed', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    fetchMock.mock(`path:${path}`, response, {repeat: 2})
    const success = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(({fetchOpts}) => useFetchApi({success, error, path, fetchOpts}), {
      initialProps: {fetchOpts: {foo: 42}},
    })
    await fetchMock.flush(true)
    rerender({fetchOpts: {foo: 44}})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledTimes(2)
    expect(error).not.toHaveBeenCalled()
  })

  it('does not fetch again if nothing has changed', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    fetchMock.mock(`path:${path}`, response, {repeat: 1})
    const success = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(props => useFetchApi({success, error, ...props}), {
      initialProps: {
        path,
        params: {foo: 42},
        headers: {bar: 43},
        fetchOpts: {bing: 44},
      },
    })
    await fetchMock.flush(true)
    rerender({
      path,
      params: {foo: 42},
      headers: {bar: 43},
      fetchOpts: {bing: 44},
    })
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledTimes(1)
    expect(error).not.toHaveBeenCalled()
  })

  it('reports forceResult when specified, without calling fetch', () => {
    const success = jest.fn()
    const meta = jest.fn()
    renderHook(() => useFetchApi({success, meta, path: '/blah', forceResult: {fake: 'news'}}))
    expect(success).toHaveBeenCalledWith({fake: 'news'})
    expect(meta).not.toHaveBeenCalled()
  })

  it('only reports forceResult once if it has not changed', () => {
    const success = jest.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {
      initialProps: {success, path: '/blah', forceResult: {fake: 'news'}},
    })
    expect(success).toHaveBeenCalledWith({fake: 'news'})
    rerender({success, path: '/blah', forceResult: {fake: 'news'}})
    expect(success).toHaveBeenCalledTimes(1)
  })

  it('reports new results if forceResult is changed', () => {
    const success = jest.fn()
    const meta = jest.fn()
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
    fetchMock.mock(`path:${path}`, {fetch: 'result'})
    const success = jest.fn()
    const meta = jest.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {
      initialProps: {success, meta, path, forceResult: {fake: 'news'}},
    })
    rerender({success, meta, path})
    await fetchMock.flush(true)
    expect(success).toHaveBeenCalledWith({fetch: 'result'})
    expect(meta).toHaveBeenCalledWith(
      expect.objectContaining({link: undefined, response: expect.anything()})
    )
  })

  it('reports forceResult if changed from undefined', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, {fetch: 'result'})
    const success = jest.fn()
    const meta = jest.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {
      initialProps: {success, meta, path},
    })
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    rerender({success, meta, path, forceResult: {force: 'value'}})
    expect(success).toHaveBeenCalledWith({force: 'value'})
    expect(meta).toHaveBeenCalledTimes(1)
  })

  it('ignores first success results if another fetch starts before it finishes', async () => {
    const path = '/api/v1/blah'
    fetchMock
      .mock('end:foo=42', {first: 41}, {repeat: 1})
      .mock('end:foo=44', {second: 42}, {repeat: 1})
    const success = jest.fn()
    const meta = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, meta, error, path, params}), {
      initialProps: {params: {foo: 42}},
    })
    // don't wait for flush, just start another one
    rerender({params: {foo: 44}})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledTimes(1)
    expect(success).toHaveBeenCalledWith({second: 42})
    expect(meta).toHaveBeenCalledTimes(1)
    expect(meta).toHaveBeenCalledWith(expect.objectContaining({link: undefined}))
    expect(error).not.toHaveBeenCalled()
  })

  it('ignores first fetch error and reports success if another fetch starts before it finishes', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock('end:foo=42', 401, {repeat: 1}).mock('end:foo=44', {second: 42}, {repeat: 1})
    const success = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, error, path, params}), {
      initialProps: {params: {foo: 42}},
    })
    // don't wait for flush, just start another one
    rerender({params: {foo: 44}})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledTimes(1)
    expect(success).toHaveBeenCalledWith({second: 42})
    expect(error).not.toHaveBeenCalled()
  })

  it('ignores first fetch success and reports error if another fetch errors before it finishes', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock('end:foo=42', {first: 42}, {repeat: 1}).mock('end:foo=44', 401, {repeat: 1})
    const success = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, error, path, params}), {
      initialProps: {params: {foo: 42}},
    })
    // don't wait for flush, just start another one
    rerender({params: {foo: 44}})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).not.toHaveBeenCalled()
    expect(error.mock.calls[0][0].response.status).toBe(401)
  })

  describe('additionalDependencies', () => {
    it('fetches again if additionalDependencies change', async () => {
      const path = '/api/v1/blah'
      const response = {key: 'value'}
      fetchMock.mock(`path:${path}`, response, {repeat: 2})
      const success = jest.fn()
      const error = jest.fn()
      const {rerender} = renderHook(({nonce}) => useFetchApi({success, error, path}, [nonce]), {
        initialProps: {nonce: 'foo'},
      })
      await fetchMock.flush(true)
      rerender({nonce: 'baz'})
      await fetchMock.flush(true)
      expect(fetchMock.done()).toBe(true)
      expect(success).toHaveBeenCalledTimes(2)
      expect(error).not.toHaveBeenCalled()
    })

    it('does not fetch again if additionalDependencies do not change', async () => {
      const path = '/api/v1/blah'
      const response = {key: 'value'}
      fetchMock.mock(`path:${path}`, response, {repeat: 1})
      const success = jest.fn()
      const error = jest.fn()
      const {rerender} = renderHook(({nonce}) => useFetchApi({success, error, path}, [nonce]), {
        initialProps: {nonce: 'foo'},
      })
      await fetchMock.flush(true)
      rerender({nonce: 'foo'})
      await fetchMock.flush(true)
      expect(fetchMock.done()).toBe(true)
      expect(success).toHaveBeenCalledTimes(1)
      expect(error).not.toHaveBeenCalled()
    })
  })

  describe('fetchAllPages', () => {
    it('fetches multiple pages if fetchAllPages is true', async () => {
      const path = '/api'
      fetchMock
        .mock(path, {headers: {link: `<${path}?page=2>;rel="next"`}, body: ['a']})
        .mock(`${path}?page=2`, {headers: {link: `<${path}?page=3>;rel="next"`}, body: ['b', 'c']})
        .mock(`${path}?page=3`, ['d', 'e'])
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const success = jest.fn()
      const meta = jest.fn()
      const error = jest.fn()
      renderHook(() => useFetchApi({path, loading, success, meta, error, fetchAllPages: true}))
      await loadingDone
      expect(fetchMock.done()).toBe(true)
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
      fetchMock
        .mock(path, {headers: {link: `<${path}?page=2>;rel="next"`}, body: ['a']})
        .mock(`${path}?page=2`, 401)
      const success = jest.fn()
      const error = jest.fn()
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
      fetchMock.mock(
        path,
        {headers: {link: `<${path}?page=bar>;rel="next"`}, body: {foo: 'bar'}},
        {overwriteRoutes: false}
      )
      const success = jest.fn()
      const error = jest.fn()
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const {rerender} = renderHook(
        ({fetchAllPages}) => useFetchApi({path, loading, success, error, fetchAllPages}),
        {initialProps: {fetchAllPages: true}}
      )
      rerender({fetchAllPages: false})
      await loadingDone
      expect(success).toHaveBeenCalledTimes(1)
      expect(success).toHaveBeenCalledWith({foo: 'bar'}) // called with object instead of array with object
      expect(error).not.toHaveBeenCalled()
    })

    it('calls convert on all pages of data', async () => {
      const path = '/api'
      fetchMock
        .mock(path, {headers: {link: `<${path}?page=2>;rel="next"`}, body: [1]})
        .mock(`${path}?page=2`, {headers: {link: `<${path}?page=3>;rel="next"`}, body: [2, 3]})
        .mock(`${path}?page=3`, [4, 5])
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const success = jest.fn()
      const meta = jest.fn()
      const error = jest.fn()
      const convert = page => page.map(n => n + 10)
      renderHook(() =>
        useFetchApi({path, loading, success, meta, error, convert, fetchAllPages: true})
      )
      await loadingDone
      expect(success).toHaveBeenCalledWith([11, 12, 13, 14, 15])
    })

    it('works with bookmarked pages', async () => {
      const path = '/api'
      fetchMock
        .mock(path, {headers: {link: `<${path}?page=foo>;rel="next"`}, body: [1]})
        .mock(`${path}?page=foo`, {headers: {link: `<${path}?page=bar>;rel="next"`}, body: [2, 3]})
        .mock(`${path}?page=bar`, [4, 5])
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const success = jest.fn()
      const meta = jest.fn()
      const error = jest.fn()
      renderHook(() => useFetchApi({path, loading, success, meta, error, fetchAllPages: true}))
      await loadingDone
      expect(success).toHaveBeenCalledWith([1, 2, 3, 4, 5])
    })
  })

  describe('fetchNumPages param', () => {
    const path = '/api'

    beforeEach(() => {
      fetchMock
        .mock(path, {headers: {link: `<${path}?page=2>;rel="next"`}, body: ['a']})
        .mock(`${path}?page=2`, {headers: {link: `<${path}?page=3>;rel="next"`}, body: ['b']})
        .mock(`${path}?page=3`, {headers: {link: `<${path}?page=4>;rel="next"`}, body: ['c']})
        .mock(`${path}?page=4`, {headers: {link: `<${path}?page=5>;rel="next"`}, body: ['d']})
        .mock(`${path}?page=5`, ['e'])
    })

    it('fetches n pages if fetchNumPages is passed', async () => {
      const [loading, loadingDone] = makeEventedFn({arg: false})
      const success = jest.fn()
      const meta = jest.fn()
      const error = jest.fn()

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
      const success = jest.fn()
      const meta = jest.fn()
      const error = jest.fn()

      renderHook(() => useFetchApi({path, loading, success, meta, error, fetchNumPages: 10}))
      await loadingDone

      expect(fetchMock.done()).toBe(true)
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
      const success = jest.fn()
      const meta = jest.fn()
      const error = jest.fn()

      renderHook(() =>
        useFetchApi({
          path,
          loading,
          success,
          meta,
          error,
          fetchAllPages: true,
          fetchNumPages: 1,
        })
      )
      await loadingDone

      expect(fetchMock.done()).toBe(true)
      expect(error).not.toHaveBeenCalled()
      expect(success).toHaveBeenCalledTimes(5)
      expect(success).toHaveBeenNthCalledWith(5, ['a', 'b', 'c', 'd', 'e'])
    })
  })
})

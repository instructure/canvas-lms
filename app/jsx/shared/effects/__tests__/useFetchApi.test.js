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
import {renderHook} from '@testing-library/react-hooks'

import useFetchApi from '../useFetchApi'

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

  it('fetches and reports success with results', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    fetchMock.mock(`path:${path}`, response)
    const success = jest.fn()
    const error = jest.fn()
    renderHook(() => useFetchApi({success, error, path}))
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledWith(response)
    expect(error).not.toHaveBeenCalled()
  })

  it('fails when response is not ok', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, 401)
    const success = jest.fn()
    const error = jest.fn()
    const loading = jest.fn()
    renderHook(() => useFetchApi({success, error, loading, path}))
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).not.toHaveBeenCalled()
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

  it('does not call convert if result is undefined', async () => {
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
    const error = jest.fn()
    const {rerender} = renderHook(({path}) => useFetchApi({success, error, path}), {
      initialProps: {path: '/api/v1/blah'}
    })
    await fetchMock.flush(true)
    rerender({path: '/api/v1/frog'})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledTimes(2)
    expect(error).not.toHaveBeenCalled()
  })

  it('fetches again if params have changed', async () => {
    const path = '/api/v1/blah'
    const response = {key: 'value'}
    fetchMock.mock(`path:${path}`, response, {repeat: 2})
    const success = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, error, path, params}), {
      initialProps: {params: {foo: 42}}
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
      initialProps: {headers: {foo: 42}}
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
      initialProps: {fetchOpts: {foo: 42}}
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
        fetchOpts: {bing: 44}
      }
    })
    await fetchMock.flush(true)
    rerender({
      path,
      params: {foo: 42},
      headers: {bar: 43},
      fetchOpts: {bing: 44}
    })
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledTimes(1)
    expect(error).not.toHaveBeenCalled()
  })

  it('reports forceResult when specified, without calling fetch', () => {
    const success = jest.fn()
    renderHook(() => useFetchApi({success, path: '/blah', forceResult: {fake: 'news'}}))
    expect(success).toHaveBeenCalledWith({fake: 'news'})
  })

  it('only reports forceResult once if it has not changed', () => {
    const success = jest.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {
      initialProps: {success, path: '/blah', forceResult: {fake: 'news'}}
    })
    expect(success).toHaveBeenCalledWith({fake: 'news'})
    rerender({success, path: '/blah', forceResult: {fake: 'news'}})
    expect(success).toHaveBeenCalledTimes(1)
  })

  it('reports new results if forceResult is changed', () => {
    const success = jest.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {
      initialProps: {success, path: '/blah', forceResult: {fake: 'news'}}
    })
    expect(success).toHaveBeenCalledWith({fake: 'news'})
    rerender({success, path: '/blah', forceResult: {other: 'thing'}})
    expect(success).toHaveBeenCalledTimes(2)
    expect(success).toHaveBeenCalledWith({other: 'thing'})
  })

  it('invokes fetch if forceResult is changed to undefined', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, {fetch: 'result'})
    const success = jest.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {
      initialProps: {success, path, forceResult: {fake: 'news'}}
    })
    rerender({success, path})
    await fetchMock.flush(true)
    expect(success).toHaveBeenCalledWith({fetch: 'result'})
  })

  it('reports forceResult if changed from undefined', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock(`path:${path}`, {fetch: 'result'})
    const success = jest.fn()
    const {rerender} = renderHook(props => useFetchApi(props), {initialProps: {success, path}})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    rerender({success, path, forceResult: {force: 'value'}})
    expect(success).toHaveBeenCalledWith({force: 'value'})
  })

  it('ignores first success results if another fetch starts before it finishes', async () => {
    const path = '/api/v1/blah'
    fetchMock
      .mock('end:foo=42', {first: 41}, {repeat: 1})
      .mock('end:foo=44', {second: 42}, {repeat: 1})
    const success = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, error, path, params}), {
      initialProps: {params: {foo: 42}}
    })
    // don't wait for flush, just start another one
    // await fetchMock.flush(true)
    rerender({params: {foo: 44}})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledTimes(1)
    expect(success).toHaveBeenCalledWith({second: 42})
    expect(error).not.toHaveBeenCalled()
  })

  it('ignores first fetch error and reports success if another fetch starts before it finishes', async () => {
    const path = '/api/v1/blah'
    fetchMock.mock('end:foo=42', 401, {repeat: 1}).mock('end:foo=44', {second: 42}, {repeat: 1})
    const success = jest.fn()
    const error = jest.fn()
    const {rerender} = renderHook(({params}) => useFetchApi({success, error, path, params}), {
      initialProps: {params: {foo: 42}}
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
      initialProps: {params: {foo: 42}}
    })
    // don't wait for flush, just start another one
    rerender({params: {foo: 44}})
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).not.toHaveBeenCalled()
    expect(error.mock.calls[0][0].response.status).toBe(401)
  })
})

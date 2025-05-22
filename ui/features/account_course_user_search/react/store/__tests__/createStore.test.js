/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import createStore from '../createStore'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('account course user search createStore', () => {
  let store

  beforeEach(() => {
    fakeENV.setup()
    store = createStore({
      getUrl: () => 'test-url',
      normalizeParams: params => ({...params, normalized: true}),
      jsonKey: 'items',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('initializes with empty state', () => {
    expect(store.getState()).toEqual({})
  })

  test('reset clears state and sets context', () => {
    store.setState({testKey: {data: [1, 2, 3]}})
    expect(store.getState()).toHaveProperty('testKey')

    const context = {userId: 123}
    store.reset(context)

    expect(store.getState()).toEqual({})
    expect(store.context).toEqual(context)
  })

  test('getKey converts params to JSON string', () => {
    const params = {course_id: 123, search_term: 'test'}
    const key = store.getKey(params)
    expect(key).toBe(JSON.stringify(params))
  })

  test('getKey handles undefined params', () => {
    const key = store.getKey(undefined)
    expect(key).toBe('{}')
  })

  test('normalizeParams applies custom normalization', () => {
    const params = {search_term: 'test'}
    const normalized = store.normalizeParams(params)
    expect(normalized).toEqual({search_term: 'test', normalized: true})
  })

  test('getStateFor returns empty object for non-existent key', () => {
    const state = store.getStateFor('non-existent-key')
    expect(state).toEqual({})
  })

  test('mergeState updates existing state correctly', () => {
    const key = 'test-key'

    store.mergeState(key, {data: [1, 2], loading: true})
    expect(store.getStateFor(key)).toEqual({data: [1, 2], loading: true})

    store.mergeState(key, {data: [1, 2, 3], error: false})

    expect(store.getStateFor(key)).toEqual({
      data: [1, 2, 3],
      loading: true,
      error: false,
    })
  })

  test('get returns state for given params', () => {
    const params = {search_term: 'test'}
    const key = store.getKey(params)

    store.mergeState(key, {data: [1, 2, 3], loading: false})

    const result = store.get(params)
    expect(result).toEqual({data: [1, 2, 3], loading: false})
  })

  test('get uses the correct key for params', () => {
    const params1 = {search_term: 'test1'}
    store.mergeState(store.getKey(params1), {data: ['test1']})

    const params2 = {search_term: 'test2'}
    store.mergeState(store.getKey(params2), {data: ['test2']})

    expect(store.get(params1).data).toEqual(['test1'])
    expect(store.get(params2).data).toEqual(['test2'])
  })

  test('lastParams is updated when load is called', () => {
    const params = {search_term: 'test'}
    store.load(params)
    expect(store.lastParams).toEqual(params)
  })

  test('loadMore updates lastParams', () => {
    const params = {search_term: 'test'}
    store.loadMore(params)
    expect(store.lastParams).toEqual(params)
  })

  test('loadAll updates lastParams and applies normalization', () => {
    const params = {search_term: 'test'}
    store.loadAll(params)
    expect(store.lastParams).toEqual({search_term: 'test', normalized: true})
  })
})

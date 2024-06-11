/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {act, waitFor} from '@testing-library/react'
import {renderHook, type RenderResult} from '@testing-library/react-hooks/dom'
import type {ApiResult} from '../../../../common/lib/apiResult/ApiResult'
import type {FetchRegistrations} from '../../../api/registrations'
import {mkUseManagePageState, type ManagePageLoadingState} from '../ManagePageLoadingState'
import {mockPageOfRegistrations, mockRegistration} from './helpers'
import {ZAccountId} from '../../../model/AccountId'

// #region helpers
const mockFetchRegistrations = (
  ...promises: ReadonlyArray<ReturnType<FetchRegistrations>>
): FetchRegistrations => {
  const returns = Array.from(promises)
  return () => {
    const toReturn = returns.shift()
    if (typeof toReturn === 'undefined') {
      throw new Error('fetchRegistrations called, but no promises left to return')
    } else {
      return toReturn
    }
  }
}

const mockPromise = <T>(
  apiResultData: T
): {
  resolve: () => void
  reject: () => void
  promise: Promise<ApiResult<T>>
} => {
  let resolve: null | ((params: ApiResult<T>) => void) = null
  let reject: any = null
  // eslint-disable-next-line promise/param-names
  const p = new Promise<ApiResult<T>>((res, rej) => {
    resolve = res
    reject = rej
  })
  return {
    promise: p,
    resolve: () => {
      resolve &&
        resolve({
          _type: 'success',
          data: apiResultData,
        })
    },
    reject: () => {
      reject({
        _type: 'error',
        message: 'An error occurred',
      })
    },
  }
}

const awaitState = async <K extends ManagePageLoadingState['_type']>(
  state: RenderResult<
    readonly [
      ManagePageLoadingState,
      {
        readonly setStale: () => void
      }
    ]
  >,
  type: K,
  f: (s: Extract<ManagePageLoadingState, {_type: K}>) => void
) => {
  await waitFor(() => {
    expect(state.current[0]._type).toEqual(type)
  })
  f(state.current[0] as Extract<ManagePageLoadingState, {_type: K}>)
}

const accountId = ZAccountId.parse('foo')

/**
 * Creates a few mock promises and renders the hook.
 * @returns
 */
const setup = () => {
  const req1 = mockPromise(mockPageOfRegistrations('Foo', 'Bar', 'Baz'))
  const req2 = mockPromise(mockPageOfRegistrations('Bar', 'Baz'))
  const deleteReq = mockPromise(undefined)

  const useManagePageState = mkUseManagePageState(
    mockFetchRegistrations(req1.promise, req2.promise),
    () => deleteReq.promise
  )

  const {result, rerender} = renderHook<
    Parameters<typeof useManagePageState>[0],
    ReturnType<typeof useManagePageState>
  >(params => useManagePageState(params), {
    initialProps: {
      dir: 'asc',
      page: 1,
      q: '',
      sort: 'name',
      accountId,
    },
  })
  return {result, rerender, req1, req2, deleteReq}
}
// #endregion

/**
 * This test is to ensure basic request are resolved correctly.
 *
 * @startuml
 * FE -> BE: request initial items
 * BE -> FE: return initial items
 * @enduml
 */
test('it should load results', async () => {
  const {result, req1} = setup()

  await awaitState(result, 'reloading', state => {
    expect(state.items).toBeUndefined()
  })

  act(() => {
    req1.resolve()
  })

  await awaitState(result, 'loaded', state => {
    expect(state.items.data.length).toBe(3)
  })
})

/**
 * This test is to ensure that the state is updated correctly if an
 * in-flight request is made stale.
 *
 * @startuml
 * FE -> BE: request initial items
 * FE --> BE: update search, request additional items
 *
 * BE -> FE: return initial items (should be ignored)
 * BE --> FE: return searched items
 * @enduml
 */
test('it should handle race conditions when an in-flight request is made stale', async () => {
  const {result, rerender, req1, req2} = setup()

  // #region INITIAL REQUEST
  await awaitState(result, 'reloading', state => {
    expect(state.items).toBeUndefined()
  })
  // #endregion

  // #region UPDATE SEARCH
  act(() => {
    result.current[1].setStale()
  })

  await awaitState(result, 'stale', state => {
    expect(state.items).toBeUndefined()
  })

  rerender({
    dir: 'asc',
    page: 1,
    q: 'Ba',
    sort: 'name',
    accountId,
  })

  await awaitState(result, 'reloading', state => {
    expect(state.items).toBeUndefined()
  })
  // #endregion

  // #region RETURN INITIAL REQUEST
  act(() => {
    req1.resolve()
  })

  await awaitState(result, 'reloading', state => {
    expect(state.items).toBeUndefined()
  })
  // #endregion

  // #region RETURN SEARCHED ITEMS
  act(() => {
    req2.resolve()
  })

  // The second request should be the one that populates the items
  await awaitState(result, 'loaded', state => {
    expect(state.items.data.length).toBe(2)
  })
  // #endregion
})

/**
 * This test is to ensure that the state is updated correctly if a later
 * request is resolved quicker than an earlier request.
 *
 * @startuml
 * FE -> BE: request initial items
 * FE --> BE: update search, request additional items
 *
 * BE --> FE: return searched items
 * BE -> FE: return initial items (should be ignored)
 * @enduml
 */
test('it should handle race conditions when a later request is resolved quicker', async () => {
  const {result, rerender, req1, req2} = setup()

  // #region UPDATE SEARCH
  act(() => {
    result.current[1].setStale()
  })

  await awaitState(result, 'stale', state => {
    expect(state.items).toBeUndefined()
  })

  rerender({
    dir: 'asc',
    page: 1,
    q: 'Ba',
    sort: 'name',
    accountId,
  })

  await awaitState(result, 'reloading', state => {
    expect(state.items).toBeUndefined()
  })
  // #endregion

  // #region RETURN SEARCHED ITEMS
  act(() => {
    req2.resolve()
  })
  await awaitState(result, 'loaded', state => {
    expect(state.items.data.length).toBe(2)
  })
  // #endregion

  // #region RETURN INITIAL REQUEST
  act(() => {
    req1.resolve()
  })

  await awaitState(result, 'loaded', state => {
    // the initial request should be ignored
    expect(state.items.data.length).toBe(2)
  })
  // #endregion
})

test('it should reload results when the query is changed', async () => {
  const {result, rerender, req1, req2} = setup()

  await awaitState(result, 'reloading', state => {
    expect(state.items).toBeUndefined()
  })

  act(() => {
    req1.resolve()
  })

  await awaitState(result, 'loaded', state => {
    expect(state.items.data.length).toBe(3)
  })

  act(() => {
    result.current[1].setStale()
  })

  await awaitState(result, 'stale', state => {
    expect(state.items?.data.length).toBe(3)
  })

  rerender({
    dir: 'asc',
    page: 1,
    q: 'Ba',
    sort: 'name',
    accountId,
  })

  await awaitState(result, 'reloading', state => {
    expect(state.items?.data.length).toBe(3)
  })

  act(() => {
    req2.resolve()
  })

  await awaitState(result, 'loaded', state => {
    expect(state.items.data.length).toBe(2)
  })
})
// TOOD flatten if you can to adhere to paul's style
describe('deleteRegistration', () => {
  it('should refresh the list after deleting succeeds', async () => {
    // TODO dry?
    const {req1, req2, result, deleteReq} = setup()

    req1.resolve()

    await awaitState(result, 'loaded', state => {
      expect(state.items.data.length).toBe(3)
    })

    const deletionPromise = result.current[1].deleteRegistration(mockRegistration('Foo', 0))
    deleteReq.resolve()

    await awaitState(result, 'reloading', state => {
      expect(state.items).toBeDefined()
    })

    req2.resolve()
    expect(await deletionPromise).toEqual({
      _type: 'success',
    })
  })

  it('should refresh the list after deleting fails', async () => {
    // TODO dry?
    const {req1, req2, result, deleteReq} = setup()

    act(() => {
      req1.resolve()
    })

    await awaitState(result, 'loaded', state => {
      expect(state.items.data.length).toBe(3)
    })

    const deletionPromise = result.current[1].deleteRegistration(mockRegistration('Foo', 0))

    deleteReq.reject()

    await awaitState(result, 'reloading', state => {
      expect(state.items).toBeDefined()
    })

    req2.resolve()
    expect(await deletionPromise).toEqual({
      _type: 'GenericError',
      message: 'Error deleting app “Foo”',
    })
  })
})

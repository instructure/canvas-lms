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
import {useApiResult} from '../useApiResult'
import {WithApiResultState} from '../WithApiResultState'

// #region helpers
const mockApiResultPromise = <T>(
  apiResultData: T,
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
      resolve !== null &&
        resolve({
          _type: 'Success',
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

const awaitState = async <K extends WithApiResultState<any>['_type'], A = unknown>(
  state: RenderResult<{
    state: WithApiResultState<A>
    setStale: () => void
    refresh: () => void
  }>,
  type: K,
  f: (s: Extract<WithApiResultState<A>, {_type: K}>) => void,
) => {
  await waitFor(() => {
    expect(state.current.state._type).toEqual(type)
  })
  f(state.current.state as Extract<WithApiResultState<A>, {_type: K}>)
}

/**
 * Creates a few mock promises and renders the hook.
 * @returns
 */
const setup = () => {
  const req1 = mockApiResultPromise(1)
  const req2 = mockApiResultPromise(2)

  const {result, rerender} = renderHook<
    () => Promise<ApiResult<number>>,
    ReturnType<typeof useApiResult<number>>
  >(useApiResult, {
    initialProps: () => {
      return req1.promise
    },
  })
  return {result, rerender, req1, req2}
}
// #endregion

/**
 * This test is to ensure basic request are resolved correctly.
 *
 * @startuml
 * FE -> BE: request initial data
 * BE -> FE: return initial data
 * @enduml
 */
test('it should load results', async () => {
  const {result, req1} = setup()

  await awaitState(result, 'reloading', state => {
    expect(state.data).toBeUndefined()
  })

  act(() => {
    req1.resolve()
  })

  await awaitState(result, 'loaded', state => {
    expect(state.data).toBe(1)
  })
})

/**
 * This test is to ensure that the state is updated correctly if an
 * in-flight request is made stale.
 *
 * @startuml
 * FE -> BE: request initial data
 * FE --> BE: request next data
 *
 * BE -> FE: return initial data (should be ignored)
 * BE --> FE: return next data (should be rendered)
 * @enduml
 */
test('it should handle race conditions when an in-flight request is made stale', async () => {
  const {result, rerender, req1, req2} = setup()

  // #region INITIAL REQUEST
  await awaitState(result, 'reloading', state => {
    expect(state.data).toBeUndefined()
  })
  // #endregion

  // #region UPDATE SEARCH
  act(() => {
    result.current.setStale()
  })

  await awaitState(result, 'stale', state => {
    expect(state.data).toBeUndefined()
  })

  rerender(() => req2.promise)

  await awaitState(result, 'reloading', state => {
    expect(state.data).toBeUndefined()
  })
  // #endregion

  // #region RETURN INITIAL REQUEST
  act(() => {
    req1.resolve()
  })

  await awaitState(result, 'reloading', state => {
    expect(state.data).toBeUndefined()
  })
  // #endregion

  // #region RETURN SEARCHED ITEMS
  act(() => {
    req2.resolve()
  })

  // The second request should be the one that populates the data
  await awaitState(result, 'loaded', state => {
    expect(state.data).toBe(2)
  })
  // #endregion
})

/**
 * This test is to ensure that the state is updated correctly if a later
 * request is resolved quicker than an earlier request.
 *
 * @startuml
 * FE -> BE: request initial data
 * FE --> BE: request next data
 *
 * BE --> FE: return next data (should be rendered)
 * BE -> FE: return initial data (should be ignored)
 * @enduml
 */
test('it should handle race conditions when a later request is resolved quicker', async () => {
  const {result, rerender, req1, req2} = setup()

  // #region UPDATE SEARCH
  act(() => {
    result.current.setStale()
  })

  await awaitState(result, 'stale', state => {
    expect(state.data).toBeUndefined()
  })

  rerender(() => req2.promise)

  await awaitState(result, 'reloading', state => {
    expect(state.data).toBeUndefined()
  })
  // #endregion

  // #region RETURN SEARCHED ITEMS
  act(() => {
    req2.resolve()
  })
  await awaitState(result, 'loaded', state => {
    expect(state.data).toBe(2)
  })
  // #endregion

  // #region RETURN INITIAL REQUEST
  act(() => {
    req1.resolve()
  })

  await awaitState(result, 'loaded', state => {
    // the initial request should be ignored
    expect(state.data).toBe(2)
  })
  // #endregion
})

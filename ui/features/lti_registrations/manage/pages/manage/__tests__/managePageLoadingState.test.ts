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
import React from 'react'
import {mkUseManagePageState, type ManagePageLoadingState} from '../ManagePageLoadingState'
import type {FetchRegistrations} from 'features/lti_registrations/manage/api/registrations'
import type {LtiRegistration} from 'features/lti_registrations/manage/model/LtiRegistration'
import type {LtiRegistrationId} from 'features/lti_registrations/manage/model/LtiRegistrationId'
import type {AccountId} from 'features/lti_registrations/manage/model/AccountId'
import type {DeveloperKeyId} from 'features/lti_registrations/manage/model/DeveloperKeyId'
import type {LtiRegistrationAccountBindingId} from 'features/lti_registrations/manage/model/LtiRegistrationAccountBinding'
import type {UserId} from 'features/lti_registrations/manage/model/UserId'
import {renderHook, type RenderResult} from '@testing-library/react-hooks/dom'

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

const mockPromise = (
  registrations: Array<LtiRegistration>
): {
  resolve: () => void
  reject: () => void
  promise: ReturnType<FetchRegistrations>
} => {
  let resolve: null | ((params: Awaited<ReturnType<FetchRegistrations>>) => void) = null
  let reject: any = null
  // eslint-disable-next-line promise/param-names
  const p = new Promise<Awaited<ReturnType<FetchRegistrations>>>((res, rej) => {
    resolve = res
    reject = rej
  })
  return {
    promise: p,
    resolve: () => {
      resolve &&
        resolve({
          _type: 'success',
          data: {
            data: registrations,
            total: registrations.length,
          },
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

const mockRegistrations = (...names: Array<string>): Array<LtiRegistration> => {
  return names.map((n, i) => {
    const id = i.toString()
    const date = new Date()
    const common = {
      account_id: id as AccountId,
      created_at: date,
      created_by: id as UserId,
      updated_at: date,
      updated_by: id as UserId,
      workflow_state: 'on',
    }
    return {
      id: id as LtiRegistrationId,
      name: n,
      ...common,
      account_binding: {
        id: id as LtiRegistrationAccountBindingId,
        registration_id: id as unknown as LtiRegistrationId,
        ...common,
      },
      developer_key_id: id as DeveloperKeyId,
      internal_service: false,
      ims_registration_id: id,
      legacy_configuration_id: null,
      manual_configuration_id: null,
      admin_nickname: n,
    }
  })
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

/**
 * Creates a few mock promises and renders the hook.
 * @returns
 */
const setup = () => {
  const req1 = mockPromise(mockRegistrations('Foo', 'Bar', 'Baz'))
  const req2 = mockPromise(mockRegistrations('Bar', 'Baz'))

  const useManagePageState = mkUseManagePageState(
    mockFetchRegistrations(req1.promise, req2.promise)
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
    },
  })
  return {result, rerender, req1, req2}
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

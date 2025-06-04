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

import * as React from 'react'
import {ApiResult, exception, formatApiResultError, isSuccessful} from './ApiResult'
import {WithApiResultState} from './WithApiResultState'

export type ApiResultFetch<A> = () => Promise<ApiResult<A>>

/**
 * Hook that handles state management for fetching data from an API
 * handles refresh & stale states.
 *
 * @example
 *
 * const {state, refresh} = useApiResult(() => fetchThing())
 *
 * return matchApiResultState(state)({
 *  data: (data, stale) => <div>{data}</div>,
 *  error: message => <div>{message}</div>,
 *  loading: () => <div>Loading...</div>,
 * })
 *
 * @param fetch
 * @returns
 */
export const useApiResult = <A>(fetch: ApiResultFetch<A>) => {
  const [state, setState] = React.useState<WithApiResultState<A>>({
    _type: 'not_requested',
  })

  // Using a ref ensures that the refresh closure called by downstream users
  // will have up-to-date search params, even if the search params changed.
  // refresh returns a promise that resolves once load is complete
  const refreshRef = React.useRef<() => void>()
  refreshRef.current = React.useCallback(() => {
    const requested = Date.now()
    setState(prev => ({
      _type: 'reloading',
      requested,
      data: 'data' in prev ? prev.data : undefined,
    }))

    return fetch()
      .then(result => {
        setState(prev => {
          // Only apply the result if the request is still relevant
          if (prev._type === 'reloading' && requested === prev.requested) {
            return isSuccessful(result)
              ? {
                  data: result.data,
                  _type: 'loaded',
                  lastRequested: requested,
                }
              : {
                  _type: 'error',
                  error: result,
                }
          } else {
            return prev
          }
        })
      })
      .catch(err => {
        setState({
          _type: 'error',
          error: exception(err),
        })
      })
  }, [fetch])

  // Refresh whenever the fetch (and thus refreshRef.current) change
  React.useEffect(() => {
    refreshRef.current?.()
  }, [refreshRef.current])

  const setStale = React.useCallback(() => {
    setState(prev => {
      if (prev._type === 'loaded' || prev._type === 'stale' || prev._type === 'reloading') {
        return {
          _type: 'stale',
          data: prev.data,
        }
      } else {
        return {
          _type: 'stale',
        }
      }
    })
  }, [])

  return {setStale, state, refresh: refreshRef.current}
}

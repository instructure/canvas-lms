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

import {UnsuccessfulApiResult} from './ApiResult'
import {WithApiResultState} from './WithApiResultState'

/**
 * Helps match conditions of an ApiResult
 *
 * @example
 *
 * matchApiResultState(state)({
 *   data: data => <div>loaded! {data}</div>,
 *   error: message => <div>Error! {message}</div>,
 *   loading: () => <div>Loading</div>
 * })
 *
 * @param apiResultState
 * @returns
 */
export const matchApiResultState =
  <A>(apiResultState: WithApiResultState<A>) =>
  <Z>(matcher: {
    data: (data: A, stale: boolean, requested?: number) => Z
    error: (error: UnsuccessfulApiResult) => Z
    loading: () => Z
  }): Z => {
    if ('data' in apiResultState && typeof apiResultState.data !== 'undefined') {
      return matcher.data(
        apiResultState.data,
        apiResultState._type === 'stale' || apiResultState._type === 'reloading',
        'requested' in apiResultState ? apiResultState.requested : undefined,
      )
    } else if (apiResultState._type === 'error') {
      return matcher.error(apiResultState.error)
    } else {
      return matcher.loading()
    }
  }

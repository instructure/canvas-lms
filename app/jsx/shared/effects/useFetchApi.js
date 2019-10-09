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

import useImmediate from '../hooks/useImmediate'
import doFetchApi from './doFetchApi'

// useImmediate for deep comparisons and may help avoid browser flickering

// utility for making it easy to abort the fetch
function abortable({success, error, loading}) {
  const aborter = new AbortController()
  let active = true
  return {
    activeSuccess: (...p) => {
      if (active && success) success(...p)
    },
    activeError: (...p) => {
      if (active && error) error(...p)
    },
    activeLoading: (...p) => {
      if (active && loading) loading(...p)
    },
    abort: () => {
      active = false
      aborter.abort()
    },
    signal: aborter.signal
  }
}

export default function useFetchApi({
  success,
  error,
  loading,
  path,
  convert,
  forceResult,
  params = {},
  headers = {},
  fetchOpts = {}
}) {
  useImmediate(() => {
    if (forceResult !== undefined) {
      success(forceResult)
      return
    }

    // prevent sending results and errors from stale queries
    const {activeSuccess, activeError, activeLoading, abort, signal} = abortable({success, error, loading})
    activeLoading(true)
    doFetchApi({
      path,
      headers,
      params,
      fetchOpts: {signal, ...fetchOpts}
    })
      .then(result => {
        if (convert && result) result = convert(result)
        activeLoading(false)
        activeSuccess(result)
      })
      .catch(err => {
        activeLoading(false)
        activeError(err)
      })
    return abort
  }, [
    success,
    error,
    loading,
    path,
    convert,
    headers,
    params,
    fetchOpts,
    forceResult
  ], {deep: true})
}

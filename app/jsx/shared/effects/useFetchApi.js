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

// utility for making it easy to abort the fetch
function abortable({success, error, loading, meta}) {
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
    activeMeta: (...p) => {
      if (active && meta) meta(...p)
    },
    abort: () => {
      active = false
      aborter.abort()
    },
    signal: aborter.signal
  }
}

// NOTE: if identity of any of the output functions changes, the prior fetch will be aborted and a
// new fetch will start, just as if you had changed an input parameter. This will result in a react
// error: "too many rerenders". An common example of this problem is this:
//
// useFetchApi({path: '/api/v1/foo', success: json => setSomeState(mungeApi(json))})
//
// The success function is recreated every time this is called, so it has a new identity. Instead of
// doing this, you could use the convert parameter:
//
// useFetchApi({path: '/api/v1/foo', success: setSomeState, convert: mungeApi})
//
// If that doesn't suit your use case, another approach would be the useCallback hook to preserve
// the identity of your callbacks.
export default function useFetchApi({
  // data output callbacks
  success, // (parsed json object of the response body) => {}
  error, // (Error object from doFetchApi) => {}
  loading, // (boolean that specifies whether a fetch is in progress) => {}
  meta, // other information about the fetch: ({link, response}) => {}. called only when success is called.

  // inputs
  path, // the url to fetch; often a relative path
  convert, // allows you to convert the json response data into another format before calling success
  forceResult, // specify this to bypass the fetch and report this to success instead. meta is not called.
  params = {}, // url parameters
  headers = {}, // additoinal request headers
  fetchOpts = {} // other options to pass to fetch
}) {
  // useImmediate for deep comparisons and may help avoid browser flickering
  useImmediate(
    () => {
      if (forceResult !== undefined) {
        success(forceResult)
        return
      }

      // prevent sending results and errors from stale queries
      const {activeSuccess, activeError, activeLoading, activeMeta, abort, signal} = abortable({
        success,
        error,
        loading,
        meta
      })
      activeLoading(true)
      doFetchApi({
        path,
        headers,
        params,
        fetchOpts: {signal, ...fetchOpts}
      })
        .then(({json, response, link}) => {
          if (convert && json) json = convert(json)
          activeLoading(false)
          activeMeta({response, link})
          activeSuccess(json)
        })
        .catch(err => {
          activeLoading(false)
          activeError(err)
        })
      return abort
    },
    [success, error, loading, meta, path, convert, headers, params, fetchOpts, forceResult],
    {deep: true}
  )
}

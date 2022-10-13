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

import useImmediate from '@canvas/use-immediate-hook'
import doFetchApi from '@canvas/do-fetch-api-effect'

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
    signal: aborter.signal,
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
//
// You can optionally pass an array of additional dependencies as a second argument. If any of
// these change, the fetch will be repeated.
export default function useFetchApi(
  {
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
    headers = {}, // additional request headers

    // Setting fetchAllPages makes useFetchApi continually fetch pages while the Link header indicates
    // there is a next page. The success callback will be invoked for each page with a flattened array
    // of the results accumulated thus far. The meta callback will also be called once for each page.
    // If an error occurs on any page, the error callback will be called and pagination will stop. The
    // loading callback will only be called with false when pagination ends. If any of the parameters
    // change, the pagination starts over. Overrides fetchNumPages.
    fetchAllPages = false,

    // Setting fetchNumPages makes useFetchApi continually fetch the next page while the Link header
    // supplies the next page or until the provided limit is reached. The same implications listed in
    // comments for fetchAllPages option apply. Overridden by fetchAllPages, if that param is true.
    fetchNumPages = 0,

    fetchOpts = {}, // other options to pass to fetch
  },
  additionalDependencies = []
) {
  // useImmediate for deep comparisons and may help avoid browser flickering
  useImmediate(
    () => {
      if (typeof forceResult !== 'undefined') {
        success(forceResult)
        return
      }

      // prevent sending results and errors from stale queries
      const {activeSuccess, activeError, activeLoading, activeMeta, abort, signal} = abortable({
        success,
        error,
        loading,
        meta,
      })

      async function fetchLoop() {
        try {
          activeLoading(true)
          let nextPage = false
          let accummulatedResults = []
          let pagesRemaining = fetchNumPages
          do {
            const paramsWithPage = {...params}
            if (nextPage) paramsWithPage.page = nextPage
            // we don't want to flood the server with parallel requests, and we need to wait for the
            // "next" link header before we know what the next page url is, so we actually want to
            // await in the loop.
            // eslint-disable-next-line no-await-in-loop
            const {json, response, link} = await doFetchApi({
              path,
              headers,
              params: paramsWithPage,
              fetchOpts: {signal, ...fetchOpts},
            })
            const result = convert && json ? convert(json) : json
            accummulatedResults = accummulatedResults.concat(result)

            activeMeta({response, link})
            if (fetchAllPages || pagesRemaining) {
              activeSuccess(accummulatedResults)
              nextPage = fetchAllPages || --pagesRemaining ? link?.next?.page : false
            } else {
              activeSuccess(result)
            }
          } while (nextPage)
        } catch (err) {
          activeError(err)
        } finally {
          activeLoading(false)
        }
      }
      fetchLoop()
      return abort
    },
    [
      ...additionalDependencies,
      success,
      error,
      loading,
      meta,
      path,
      convert,
      forceResult,
      params,
      headers,
      fetchAllPages,
      fetchNumPages,
      fetchOpts,
    ],
    {deep: true}
  )
}

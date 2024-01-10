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

import getCookie from '@instructure/get-cookie'

declare global {
  interface Window {
    prefetched_xhrs?: Record<string, Promise<Response>>
  }
}

// These are helpful methods you can use along side the ruby ApplicationHelper::prefetch_xhr helper method in canvas

/**
 * Retrieve the fetch response promise assigned to the given id. This will
 * return `undefined` if there are no prefetched requests or there is no
 * request assigned to the given id. When a request is assigned to the given
 * id, it will remain stored for subsequent retrievals, if needed.
 *
 * @param {String} id
 * @returns {Promise<Response>} fetchResponsePromise
 */
export function getPrefetchedXHR(id: string) {
  return window.prefetched_xhrs && window.prefetched_xhrs[id]
}

/**
 * Retrieve the fetch response promise assigned to the given id. This will
 * return `undefined` if there are no prefetched requests or there is no
 * request assigned to the given id. When a request is assigned to the given
 * id, it will be removed from request storage. This is important for requests
 * which are expected to return fresh results upon each request.
 *
 * @param {String} id
 * @returns {Promise<Response>} fetchResponsePromise
 */
export function consumePrefetchedXHR(id: string) {
  if (window.prefetched_xhrs) {
    const value = window.prefetched_xhrs[id]
    delete window.prefetched_xhrs[id]
    return value
  }

  return undefined
}

/**
 * Store a fetch response promise assigned to the given id. This function is
 * intended for specs so that they do not need awareness of the implementation
 * details for how prefetched requests are managed.
 */
export function setPrefetchedXHR(id: string, fetchResponsePromise: Promise<Response>) {
  window.prefetched_xhrs = window.prefetched_xhrs || {}
  window.prefetched_xhrs[id] = fetchResponsePromise
}

/**
 * Remove all prefetched requests from storage. This function is intended for
 * specs so that they can clean up after assertions without needing awareness
 * of the implementation details for how prefetched requests are managed.
 */
export function clearPrefetchedXHRs() {
  delete window.prefetched_xhrs
}

/**
 * Transforms a `fetch` request into something that looks like an `axios` response
 * with a `.data` and `.headers` property, so you can pass it to our parseLinkHeaders stuff
 */
export function asAxios<T>(
  fetchRequest: Promise<Response>,
  type: 'json' | 'text' = 'json'
):
  | Promise<{
      data: T
      headers: {
        link: string | null
      }
    }>
  | undefined {
  if (!fetchRequest) return

  return fetchRequest.then(checkStatus).then(res =>
    res
      .clone()
      [type]()
      .then(data => {
        return {
          data,
          headers: {link: res.headers.get('Link')},
        }
      })
  )
}

/**
 * Takes a `fetch` request and returns a promise of the json data of the response
 */
export function asJson(fetchRequest?: Promise<Response>) {
  if (!fetchRequest) return
  return fetchRequest.then(checkStatus).then((res: Response) => res.clone().json())
}

/**
 * Takes a `fetch` request and returns a promise of the text of the response
 */
export function asText(fetchRequest: Promise<Response>) {
  if (!fetchRequest) return
  return fetchRequest.then(checkStatus).then(res => res.clone().text())
}

/**
 * filter a response to raise an error on a 400+ status
 */
export function checkStatus(response: Response) {
  if (response.status < 400) {
    return response
  } else {
    const error = new Error(response.statusText)
    // @ts-expect-error
    error.response = response
    throw error
  }
}

const csrfToken = getCookie('_csrf_token')

// these are duplicated in application_helper.rb#prefetch_xhr
// because we don't have a good pattern for sharing them yet.
// If you change these defaults, you should probably cascade that change
// to that ruby location
export const defaultFetchOptions = (): {
  credentials: 'include' | 'omit' | 'same-origin'
  headers: Record<string, string>
} => ({
  credentials: 'same-origin',
  headers: {
    Accept: 'application/json+canvas-string-ids, application/json',
    'X-Requested-With': 'XMLHttpRequest',
    'X-CSRF-Token': csrfToken,
  },
})

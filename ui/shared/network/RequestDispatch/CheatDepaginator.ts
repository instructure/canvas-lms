/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {find, isArray} from 'lodash'
import parseLinkHeader from '@canvas/parse-link-header'
import deferPromise from '@instructure/defer-promise'

interface PageResponse {
  data: any
  xhr: XMLHttpRequest
}

interface DeferredPromise {
  promise: Promise<any>
  resolve: (value?: any) => void
  reject: (reason?: any) => void
}

/*
 * Fires callback for paginated APIs in order
 *
 * @param callback
 * @param data - api data will be appended to this array (also in order)
 */
function consumePagesInOrder(
  callback: ((response: any) => void) | null,
  data: any[],
): (response: any, page: number) => void {
  const pendingResponses: Array<[any, number]> = []
  let wantedPage = 1

  const orderedConsumer = (response: any, page: number) => {
    if (page === wantedPage) {
      if (callback) callback(response)
      if (isArray(response)) {
        data.push(...response)
      } else {
        data.push(response)
      }
      wantedPage += 1
    } else {
      pendingResponses.push([response, page])
    }

    const nextPage = find(pendingResponses, ([_pageData, pageNum]) => pageNum === wantedPage)
    if (nextPage) {
      const [pageData, pageNum] = nextPage
      orderedConsumer(pageData, pageNum)
    }
  }

  return orderedConsumer
}

/*
 * Quickly depaginates a canvas API endpoint
 *
 * Returns pages in sequential order.
 *
 * Note: this can only be used for endpoints that have sequential page
 * numbers
 *
 * @param url - canvas api endpoint
 * @param params - params to be passed along with each request
 * @param pageCallback - called for each page of data
 * @returns a Promise that will be resolved when all pages have been fetched
 */
function cheaterDepaginate(
  url: string,
  params: Record<string, any>,
  pageCallback: (response: any) => void,
  pagesEnqueuedCallback: (promises: Promise<any>[]) => void = _deferred => {},
  dispatch: any,
): Promise<any[]> {
  const gotAllPagesDeferred: DeferredPromise = deferPromise()
  const data: any[] = []
  const errHandler = () => {
    pagesEnqueuedCallback([])
    gotAllPagesDeferred.reject()
  }
  const orderedPageCallback = consumePagesInOrder(pageCallback, data)

  dispatch
    ._getJSON(url, params)
    .then(({data: firstPageResponse, xhr}: PageResponse) => {
      orderedPageCallback(firstPageResponse, 1)

      const paginationLinks = xhr.getResponseHeader('Link')
      const lastLink = paginationLinks ? parseLinkHeader(paginationLinks)?.last : null
      if (lastLink == null) {
        pagesEnqueuedCallback([])
        gotAllPagesDeferred.resolve(data)
        return
      }

      const lastPage = parseInt(lastLink.page, 10)
      if (!(lastPage > 1)) {
        pagesEnqueuedCallback([])
        gotAllPagesDeferred.resolve(data)
        return
      }

      // At this point, there are multiple pages

      function paramsForPage(page: number): Record<string, any> {
        return {page, ...params}
      }

      function bindPageCallback(page: number): (response: any) => void {
        return response => orderedPageCallback(response, page)
      }

      const promises: Promise<any>[] = []

      for (let page = 2; page <= lastPage; page++) {
        const promise = dispatch.getJSON(url, paramsForPage(page)).then(bindPageCallback(page))
        promises.push(promise)
      }
      pagesEnqueuedCallback(promises)

      Promise.all(promises)
        .then(() => gotAllPagesDeferred.resolve(data))
        .catch(errHandler)
    })
    .catch(errHandler)

  return gotAllPagesDeferred.promise
}

export default cheaterDepaginate

/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import $ from 'jquery'
import {isArray, find} from 'lodash'
import '@canvas/jquery/jquery.ajaxJSON'

/*
 * Fires callback for paginated APIs in order
 *
 * @param callback
 * @param data - api data will be appended to this array (also in order)
 */
function consumePagesInOrder(
  callback: (response: unknown) => void,
  data: unknown[],
): (response: unknown, page: number) => void {
  const pendingResponses: Array<[unknown, number]> = []
  let wantedPage = 1

  const orderedConsumer = (response: unknown, page: number) => {
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
 * @returns a jQuery Deferred that will be resolved when all pages have been fetched
 */
function cheaterDepaginate<T>(
  url: string,
  params: Record<string, unknown>,
  pageCallback: (data: unknown) => void,
  pagesEnqueuedCallback: (deferreds: JQueryDeferred<T>[]) => void = () => {},
  dispatch: {
    getJSON: (
      url: string,
      params: Record<string, unknown>,
      callback: (data: T) => void,
    ) => JQueryDeferred<T>
  } | null = null,
) {
  const gotAllPagesDfd = $.Deferred<T[]>()
  const data: T[] = []
  const errHandler = () => {
    pagesEnqueuedCallback([])
    gotAllPagesDfd.reject()
  }
  const orderedPageCallback = consumePagesInOrder(pageCallback, data)

  $.ajaxJSON(
    url,
    'GET',
    params,
    (firstPageResponse: T, xhr: JQuery.jqXHR) => {
      orderedPageCallback(firstPageResponse, 1)

      const paginationLinks = xhr.getResponseHeader('Link')
      if (!paginationLinks) {
        pagesEnqueuedCallback([])
        gotAllPagesDfd.resolve(data)
        return
      }

      const lastLink = paginationLinks.match(/<[^>]+>; *rel="last"/)
      if (!lastLink) {
        pagesEnqueuedCallback([])
        gotAllPagesDfd.resolve(data)
        return
      }

      const lastPageMatch = lastLink[0].match(/page=(\d+)/)
      if (!lastPageMatch) {
        pagesEnqueuedCallback([])
        gotAllPagesDfd.resolve(data)
        return
      }

      const lastPage = parseInt(lastPageMatch[1], 10)
      if (lastPage === 1) {
        pagesEnqueuedCallback([])
        gotAllPagesDfd.resolve(data)
        return
      }

      // At this point, there are multiple pages

      function paramsForPage(page: number): Record<string, unknown> {
        return {page, ...params}
      }

      function bindPageCallback(page: number): (response: unknown) => void {
        return response => orderedPageCallback(response, page)
      }

      const dfds: JQueryDeferred<T>[] = []

      if (dispatch == null) {
        const fetchPage = (page: number) =>
          $.ajaxJSON(url, 'GET', paramsForPage(page), bindPageCallback(page))

        for (let page = 2; page <= lastPage; page++) {
          dfds.push(fetchPage(page))
        }
      } else {
        for (let page = 2; page <= lastPage; page++) {
          const deferred = dispatch.getJSON(url, paramsForPage(page), bindPageCallback(page))
          dfds.push(deferred)
        }
      }
      pagesEnqueuedCallback(dfds)

      $.when(...dfds).then(() => gotAllPagesDfd.resolve(data), errHandler)
    },
    errHandler,
  )

  return gotAllPagesDfd
}

export default cheaterDepaginate

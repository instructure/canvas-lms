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
function consumePagesInOrder(callback, data) {
  const pendingResponses = []
  let wantedPage = 1

  const orderedConsumer = (response, page) => {
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
function cheaterDepaginate(
  url,
  params,
  pageCallback,
  pagesEnqueuedCallback = () => {},
  dispatch = null
) {
  const gotAllPagesDfd = $.Deferred()
  const data = []
  const errHandler = () => {
    pagesEnqueuedCallback([])
    gotAllPagesDfd.reject()
  }
  const orderedPageCallback = consumePagesInOrder(pageCallback, data)

  $.ajaxJSON(
    url,
    'GET',
    params,
    (firstPageResponse, xhr) => {
      orderedPageCallback(firstPageResponse, 1)

      const paginationLinks = xhr.getResponseHeader('Link')
      const lastLink = paginationLinks.match(/<[^>]+>; *rel="last"/)
      if (lastLink === null) {
        pagesEnqueuedCallback([])
        gotAllPagesDfd.resolve(data)
        return
      }

      const lastPage = parseInt(lastLink[0].match(/page=(\d+)/)[1], 10)
      if (lastPage === 1) {
        pagesEnqueuedCallback([])
        gotAllPagesDfd.resolve(data)
        return
      }

      // At this point, there are multiple pages

      function paramsForPage(page) {
        return {page, ...params}
      }

      function bindPageCallback(page) {
        return response => orderedPageCallback(response, page)
      }

      const dfds = []

      if (dispatch == null) {
        const fetchPage = page =>
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
    errHandler
  )

  return gotAllPagesDfd
}

export default cheaterDepaginate

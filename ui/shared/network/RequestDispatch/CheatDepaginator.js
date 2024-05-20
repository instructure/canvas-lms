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
 * @returns a Promise that will be resolved when all pages have been fetched
 */
function cheaterDepaginate(
  url,
  params,
  pageCallback,
  pagesEnqueuedCallback = _deferred => {},
  dispatch
) {
  const gotAllPagesDeferred = deferPromise()
  const data = []
  const errHandler = () => {
    pagesEnqueuedCallback([])
    gotAllPagesDeferred.reject()
  }
  const orderedPageCallback = consumePagesInOrder(pageCallback, data)

  dispatch
    ._getJSON(url, params)
    .then(({data: firstPageResponse, xhr}) => {
      orderedPageCallback(firstPageResponse, 1)

      const paginationLinks = xhr.getResponseHeader('Link')
      const lastLink = parseLinkHeader(paginationLinks)?.last
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

      function paramsForPage(page) {
        return {page, ...params}
      }

      function bindPageCallback(page) {
        return response => orderedPageCallback(response, page)
      }

      const promises = []

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

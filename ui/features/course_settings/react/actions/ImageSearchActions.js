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

import axios from '@canvas/axios'
import parseLinkHeader from 'parse-link-header'
import _ from 'lodash'

let request

const once = (config = {}) => {
  if (request) {
    request.cancel('Only one request allowed at a time.')
  }
  request = axios.CancelToken.source()

  config.cancelToken = request.token
  return axios(config)
}

const ImageSearchActions = {
  updateSearchTerm(term) {
    return {type: 'UPDATE_SEARCH_TERM', term}
  },

  startImageSearch() {
    return {type: 'START_IMAGE_SEARCH'}
  },

  receiveImageSearchResults(originalResults, pageDirection) {
    const results = {...originalResults}
    results.prevUrl = parseLinkHeader(results.headers.link).prev
      ? parseLinkHeader(results.headers.link).prev.url
      : null
    results.nextUrl = parseLinkHeader(results.headers.link).next
      ? parseLinkHeader(results.headers.link).next.url
      : null
    return {type: 'RECEIVE_IMAGE_SEARCH_RESULTS', results, pageDirection}
  },

  clearImageSearch() {
    this.searchApiGet(null)
    return {type: 'CLEAR_IMAGE_SEARCH'}
  },

  failImageSearch(error, pageDirection) {
    return {type: 'FAIL_IMAGE_SEARCH', error, pageDirection}
  },

  cancelImageSearch() {
    if (request) {
      request.cancel()
    }
  },

  search(term) {
    return dispatch => {
      dispatch(this.updateSearchTerm(term))
      this.searchApiGet(this.composeSearchUrl(term), null, dispatch)
    }
  },

  loadMore(url, page_direction) {
    return dispatch => {
      dispatch(this.startImageSearch())
      this.searchApiGet(url, page_direction, dispatch)
    }
  },

  searchApiGet: _.debounce(function (url, pageDirection, dispatch = null) {
    this.cancelImageSearch()
    if (url === null) return
    dispatch(this.startImageSearch())

    const config = {
      method: 'get',
      url,
      timeout: 60000,
    }

    once(config)
      .then(response => {
        dispatch(this.receiveImageSearchResults(response, pageDirection))
      })
      .catch(error => {
        dispatch(this.failImageSearch(error, pageDirection))
      })
  }, 750),

  composeSearchUrl(term) {
    const per_page = '12'
    return `/api/v1/image_search/?query=${term}&per_page=${per_page}&orientation=landscape`
  },
}

export default ImageSearchActions

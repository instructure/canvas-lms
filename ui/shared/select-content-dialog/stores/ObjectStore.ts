/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {clone} from 'lodash'
import createStore, {type CanvasStore} from '@canvas/backbone/createStore'
import parseLinkHeader from 'link-header-parsing/parseLinkHeaderFromXHR'
import '@canvas/rails-flash-notifications'
import {encodeQueryString} from '@canvas/query-string-encoding'

const initialStoreState = {
  links: {},
  items: [],
  isLoading: false,
  hasLoaded: false,
  hasMore: false,
}

class ObjectStore {
  store: CanvasStore<{
    links: {
      next?: string
    }
    items: []
    isLoading: boolean
    hasLoaded: boolean
    isLoaded: boolean
    hasMore: boolean
  }>

  apiEndpoint: string

  /**
   * apiEndpoint should be the endpoint for this resource.
   * Options is an object containing additional options for the store:
   *    - perPage - indicates the number of records that should be pulled per
   *                request.
   *
   * Other options will be to query parameters
   */
  constructor(apiEndpoint: string, options: any) {
    // We clone the initialStoreState so it doesn't hang onto a bad reference.
    // @ts-expect-error
    this.store = createStore(clone(initialStoreState))
    if (options) {
      options.per_page = options.perPage
      delete options.perPage
      apiEndpoint += '?' + encodeQueryString(options)
    }
    this.apiEndpoint = apiEndpoint
  }

  /**
   * Fetches the resources.
   * options is an optional object.  Currently this allows for the following:
   *   - fetchAll: true - this will continually fetch all pages of the resource
   */
  fetch(options: any) {
    const url = this.store.getState().links?.next || this.apiEndpoint
    this.store.setState({isLoading: true})
    $.ajax({
      url,
      type: 'GET',
      success: this._fetchSuccessHandler.bind(this, options),
      error: this._fetchErrorHandler.bind(this),
    })
  }

  /**
   * Sets the store back to the initial state.
   */
  reset() {
    // We clone the initialStoreState so it doesn't hang onto a bad reference.
    // @ts-expect-error
    this.store.setState(clone(initialStoreState))
  }

  /**
   * Returns the current state of the underlying store.
   */
  getState() {
    return this.store.getState()
  }

  /**
   * Adds a change listener
   */
  addChangeListener(callback: () => void) {
    this.store.addChangeListener(callback)
  }

  /**
   * Removes a change listener
   */
  removeChangeListener(callback: () => void) {
    this.store.removeChangeListener(callback)
  }

  _fetchSuccessHandler(options: any, items: any, status: any, xhr: any) {
    const links = parseLinkHeader(xhr)
    items = this.store.getState().items?.concat(items)

    this.store.setState({
      links,
      isLoading: false,
      isLoaded: true,
      items,
      hasMore: !!links.next,
    })

    if (options && options.fetchAll && !!links.next) {
      this.fetch(options)
    }
  }

  _fetchErrorHandler() {
    this.store.setState({
      items: [],
      isLoading: false,
      isLoaded: false,
      hasMore: true,
    })
  }
}

export default ObjectStore

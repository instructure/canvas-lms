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

import parseLinkHeader from 'parse-link-header'
import ajaxJSON from 'jquery.ajaxJSON'
import createStore from '../../shared/helpers/createStore'

const getNextUrl = obj =>
  obj &&
  obj.links &&
  obj.links.next &&
  obj.links.next.url

/**
 * Build a store that support basic ajax fetching (first, next, all),
 * and caches the results by params.
 *
 * You only need to implement getUrl, and can optionally implement
 * normalizeParams and jsonKey
 */
export default function factory(spec) {
  return Object.assign(createStore(), {
    /**
     * Get a blank state in the store; useful when mounting the top-
     * level component that uses the store
     *
     * @param {any} context
     *        User-defined data you can use later on in normalizeParams
     *        and getUrl; will be available as `this.context`
     */
    reset(context) {
      this.clearState()
      this.context = context
    },

    getKey: params => JSON.stringify(params || {}),
    normalizeParams: params => params,

    getUrl() {
      throw new Error('not implemented')
    },

    /**
     * If the API response is an object instead of an array, use this
     * to specify the key containing the actual array of results
     */
    jsonKey: null,

    /**
     * Load the first page of data for the given params
     */
    load(params) {
      const key = this.getKey(params)
      this.lastParams = params
      const normalizedParams = this.normalizeParams(params)
      const url = this.getUrl()

      return this._load(key, url, normalizedParams)
    },

    /**
     * Create a record; since we're lazy, just blow away all the store
     * data, but reload the last thing we fetched
     */
    create(params) {
      const url = this.getUrl()
      return ajaxJSON(url, 'POST', this.normalizeParams(params)).then(() => {
        this.clearState()
        if (this.lastParams) this.load(this.lastParams)
      })
    },

    /**
     * Load the next page of data for the given params
     */
    loadMore(params) {
      const key = this.getKey(params)
      this.lastParams = params
      const nextUrl = getNextUrl(this.getStateFor(key))
      if (!nextUrl) return

      return this._load(key, nextUrl, {}, {append: true})
    },

    loadPage(page, params) {
      const key = this.getKey(params)
      this.lastParams = params
      return this._load(key, page  )
    },

    /**
     * Load data from the endpoint, following `next` links until
     * everything has been fetched. Don't be dumb and call this
     * on users or something :P
     */
    loadAll(params, append) {
      const key = this.getKey(params)
      const normalizedParams = this.lastParams = this.normalizeParams(params)
      const url = this.getUrl()
      this._loadAll(key, url, normalizedParams, append)
    },

    _loadAll(key, url, params, append) {
      const promise = this._load(key, url, params, {append})
      if (!promise) return

      promise.then(() => {
        const nextUrl = getNextUrl(this.getStateFor(key))
        if (nextUrl) this._loadAll(key, nextUrl, {}, true)
      })
    },

    _load(key, url, params, options={}) {
      this.mergeState(key, {loading: true})

      ajaxJSON.abortRequest(this.previousLoadRequest)
      const xhr = ajaxJSON(url, 'GET', params)
      this.previousLoadRequest = xhr

      return xhr.then((data, _textStatus, xhr) => {
        if (this.jsonKey) data = data[this.jsonKey]
        if (options.wrap) data = [data]
        if (options.append) data = (this.getStateFor(key).data || []).concat(data)

        const links = parseLinkHeader(xhr.getResponseHeader('Link'))
        this.mergeState(key, {data, links, loading: false})
      }, () => {
        this.mergeState(key, {error: true, loading: false})
      })
    },

    getStateFor(key) {
      return this.getState()[key] || {}
    },

    mergeState(key, newState) {
      this.setState({
        [key]: {
          ...this.getStateFor(key),
          ...newState
        }
      })
    },

    /**
     * Return whatever results we have for the given params, as well as
     * useful meta data.
     *
     * @return {Object}   obj
     *
     * @return {Object[]} obj.data
     *         The actual data
     *
     * @return {Boolean}  obj.error
     *         Indication of whether there was an error
     *
     * @return {Boolean}  obj.loading
     *         Whether or not we are currently fetching data
     *
     * @return {String}   obj.next
     *         A URL where we can retrieve the next page of data (if
     *         there is more)
     */
    get(params) {
      const key = this.getKey(params)
      return this.getStateFor(key)
    }
  }, spec)
}

/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {encodeQueryString} from '@canvas/query-string-encoding'

/**
 * @class Common.Core.Environment
 *
 * API for manipulating the search query.
 */
const Environment = {
  /**
   * @property {Object} query
   * The extracted GET query parameters. See #parseQueryString
   */
  query: {},

  /**
   * Extract query parameters from a query string. The method can handle
   * scalar and 1-level array values.
   *
   * @param  {String} query
   *         The query string from the location bar. Like:
   *         "?foo=bar" or "foo=bar&arr[]=1&arr[]=2"
   *
   * @return {Object}
   *         Contains the key-value pairs found in the query string.
   */
  parseQueryString(query) {
    const items = query.replace(/^\?/, '').split('&')

    return items.reduce(function (params, item) {
      const pair = item.split('=')
      let key = decodeURIComponent(pair[0])
      const value = decodeURIComponent(pair[1])

      if (key && key.length) {
        if (key.substr(-2, 2) === '[]') {
          key = key.substr(0, key.length - 2)

          params[key] = params[key] || []
          params[key].push(value)
        } else {
          params[key] = value
        }
      }

      return params
    }, {})
  },

  /**
   * Create or replace a bunch of parameters in the query string.
   *
   * @example
   *   // Say the search has something like ?foo=bar&from=03/01/2014
   *   Env.updateQueryString({
   *     from: "03/28/2014"
   *   });
   *   // => ?foo=bar&from=03/28/2014
   *
   */
  updateQueryString(params) {
    this.query = {...this.query, ...params}

    window.history.pushState(
      '',
      '',
      [window.location.pathname, decodeURIComponent(encodeQueryString(this.query))].join('?')
    )
  },

  getQueryParameter(key) {
    return this.query[key]
  },

  removeQueryParameter(key) {
    this.removeQueryParameters([key])
  },

  removeQueryParameters(keys) {
    const query = this.query

    keys.forEach(function (key) {
      delete query[key]
    })

    this.updateQueryString({})
  },
}

// Extract the actual query string either from location.search if it's there,
// or from the hash if we're using hash-based history, or from the href
// as the last resort.
const extractQueryString = function () {
  if (window.location.search.length) {
    return window.location.search
  } else if (window.location.hash.length) {
    return window.location.hash.split('?')[1] || ''
  } else {
    return window.location.href.split('?')[1] || ''
  }
}

Environment.query = Environment.parseQueryString(extractQueryString())

export default Environment

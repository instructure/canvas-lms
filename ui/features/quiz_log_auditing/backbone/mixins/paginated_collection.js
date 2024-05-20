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

import {find} from 'lodash'

const RE_EXTRACT_LINK = /<([^>]+)>; rel="([^"]+)",?\s*/g
const RE_EXTRACT_PP = /per_page=(\d+)/

// Extract pagination meta from a JSON-API payload inside the
// "meta.pagination" set.
const parseJsonApiPagination = function (respMeta, meta) {
  if (!meta) meta = {}

  meta.perPage = respMeta.per_page
  meta.hasMore = !!respMeta.next
  meta.nextPage = meta.hasMore ? respMeta.page + 1 : undefined
  meta.count = respMeta.count

  return meta
}

// Extract pagination from the Link header.
//
// Here's a good reference:
//   https://developer.github.com/guides/traversing-with-pagination/
const parseLinkPagination = function (linkHeader, meta) {
  let match
  const links = []

  if (!meta) meta = {}

  while ((match = RE_EXTRACT_LINK.exec(linkHeader))) {
    links.push({
      rel: match[2],
      href: match[1],
      page: parseInt(/page=(\d+)/.exec(match[1])[1], 10),
    })
  }

  const nextLink = find(links, {rel: 'next'})
  const lastLink = find(links, {rel: 'last'})

  meta.perPage = parseInt((RE_EXTRACT_PP.exec(linkHeader) || [])[1] || 0, 10)
  meta.hasMore = !!nextLink
  meta.nextPage = meta.hasMore ? nextLink.page : undefined

  // Link header does not provide us with an accurate count of objects, so
  // we'll estimate it if we know how many we get per page, and we know the
  // index of the last page:
  if (lastLink) {
    meta.count = meta.perPage * lastLink.page
  }

  return meta
}

/**
 * @class Events.Mixins.PaginatedCollection
 * @extends {Backbone.Collection}
 *
 * Adds support for utilizing JSON-API pagination meta-data to allow fetching
 * any page of a paginated API resource, or all pages at once.
 *
 * Usage example:
 *
 *     var Collection = Backbone.Collection.extend({
 *       // install the mixin
 *       constructor: function() {
 *         PaginatedCollection(this);
 *         return Backbone.Collection.apply(this, arguments);
 *       },
 *
 *       url: function() {
 *         return '/users';
 *       }
 *     });
 *
 *     var collection = new Collection();
 *
 *     collection.fetch(); // /users
 *     collection.length;  // 10
 *
 *     collection.fetchNext(); // /users?page=2
 *     collection.length;      // 20
 *
 *     // load all available users in one go:
 *     // /users?page=1
 *     // ...
 *     // /users?page=5
 *     collection.fetchAll().then(function() {
 *       collection.length; // 50
 *     });
 */
const Mixin = {
  /**
   * Fetch the next page, if available.
   *
   * @param {Object} options
   *        Normal options you'd pass to Backbone.Collection#fetch().
   *
   * @param {Number} [options.page]
   *        If specified, exactly that page will be fetched, otherwise we'll
   *        use the current cursor (or 1).
   *
   * @return {Promise}
   *         Resolves when the page has been loaded and the pagination meta
   *         parsed.
   */
  fetchNext(options) {
    const meta = this._paginationMeta

    if (!options) {
      options = {}
    } else if (options.hasOwnProperty('xhr')) {
      delete options.xhr
    }

    if (!options.data) {
      options.data = {}
    }

    options.data.page = options.page || meta.nextPage

    options.success = function (payload, statusText, xhr) {
      const header = xhr.getResponseHeader('Link')

      if (payload.meta && payload.meta.pagination) {
        parseJsonApiPagination(payload.meta.pagination, meta)
      } else if (header) {
        parseLinkPagination(header, meta)
      }

      this.add(payload, {parse: true /* always parse */})
    }.bind(this)

    return this.sync('read', this, options)
  },

  /**
   * @return {Boolean}
   *         Whether there's more data (that we know of) to pull in from the
   *         server.
   */
  canLoadMore() {
    return !!this._paginationMeta.hasMore
  },

  /**
   * Fetch all available pages.
   *
   * @param  {Object} options
   *         Options to pass to #fetchNext. "page" is not allowed here and
   *         will be ignored if specified.
   *
   * @return {Promise}
   *         Resolves when *all* pages have been loaded.
   */
  fetchAll(options) {
    const meta = this._paginationMeta

    if (!options) {
      options = {}
    } else if (options.hasOwnProperty('page')) {
      if (process.env.NODE_ENV === 'development') {
        console.error(
          'You should not specify a page when fetching all pages since it will be reset to 1!'
        )
      }

      delete options.page
    }

    if (options.reset) {
      this.reset(null, {silent: true})
    }

    meta.nextPage = 1

    return (function fetch(collection) {
      return collection.fetchNext(options).then(function () {
        if (meta.hasMore) {
          return fetch(collection)
        } else {
          return collection
        }
      })
    })(this)
  },

  /** @private */
  _resetPaginationMeta() {
    this._paginationMeta = {}
  },
}

export default function applyMixin(collection) {
  collection.fetchNext = Mixin.fetchNext
  collection.fetchAll = Mixin.fetchAll
  collection._resetPaginationMeta = Mixin._resetPaginationMeta

  collection.on('reset', collection._resetPaginationMeta, collection)
  collection._resetPaginationMeta()
}

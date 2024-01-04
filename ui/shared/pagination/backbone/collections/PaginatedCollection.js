/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import $ from 'jquery'
import Backbone from '@canvas/backbone'

const indexOf = [].indexOf
const slice = [].slice

const capitalize = function (string) {
  if (string == null) {
    string = ''
  }
  return string.charAt(0).toUpperCase() + string.substring(1).toLowerCase()
}

extend(PaginatedCollection, Backbone.Collection)

function PaginatedCollection() {
  this._setStateAfterFetch = this._setStateAfterFetch.bind(this)
  return PaginatedCollection.__super__.constructor.apply(this, arguments)
}

PaginatedCollection.prototype.nameRegex = /rel="([a-z]+)/

PaginatedCollection.prototype.linkRegex = /^<([^>]+)/

PaginatedCollection.prototype.pageRegex = /\Wpage=(\d+)/

PaginatedCollection.prototype.perPageRegex = /\Wper_page=(\d+)/

PaginatedCollection.prototype.initialize = function () {
  PaginatedCollection.__super__.initialize.apply(this, arguments)
  return (this.urls = {})
}

PaginatedCollection.prototype.fetch = function (opts) {
  let ref
  const options = {...opts}
  this.loadedAll = false
  const exclusionFlag = 'fetching' + capitalize(options.page) + 'Page'
  this[exclusionFlag] = true
  if (options.page != null) {
    if (options.remove == null) {
      options.remove = false
    }
    if ((ref = this.urls) != null ? ref[options.page] : void 0) {
      options.url = this.urls[options.page]
      options.data = ''
    }
  } else if (options.reset == null) {
    options.reset = true
  }
  if (options.fetchOptions != null) {
    options.data = options.fetchOptions
  }
  this.trigger('beforeFetch', this, options)
  if (options.page != null) {
    this.trigger('beforeFetch:' + options.page, this, options)
  }
  let xhr = null
  options.dataFilter = (function (_this) {
    return function (data) {
      _this[exclusionFlag] = false
      _this._setStateAfterFetch(xhr, options)
      return data
    }
  })(this)
  const dfd = options.dfd || $.Deferred()
  xhr = PaginatedCollection.__super__.fetch.call(this, options).done(
    (function (_this) {
      return function (response, text, _xhr) {
        let ref1
        _this.trigger('fetch', _this, response, options)
        if (options.page != null) {
          _this.trigger('fetch:' + options.page, _this, response, options)
        }
        if (!((ref1 = _this.urls) != null ? ref1.next : void 0)) {
          // eslint-disable-next-line prefer-spread
          _this.trigger.apply(_this, ['fetched:last'].concat(slice.call(arguments)))
        }
        if (_this.loadAll && _this.urls.next != null) {
          return setTimeout(function () {
            return _this.fetch({
              page: 'next',
              dfd,
            })
          })
        } else {
          return dfd.resolve(response, text, xhr)
        }
      }
    })(this)
  )
  dfd.abort = xhr.abort
  dfd.success = dfd.done
  dfd.error = dfd.fail
  return dfd
}

PaginatedCollection.prototype.canFetch = function (page) {
  return this.urls != null && this.urls[page] != null
}

PaginatedCollection.prototype._setStateAfterFetch = function (xhr, options) {
  let base, match, perPage, ref, ref1, ref2, ref3, ref4
  if (this._urlCache == null) {
    this._urlCache = []
  }
  const urlIsNotCached = ((ref = options.url), indexOf.call(this._urlCache, ref) < 0)
  if (!urlIsNotCached) {
    this._urlCache.push(options.url)
  }
  const firstRequest = !this.atLeastOnePageFetched
  const setBottom =
    firstRequest || (((ref1 = options.page) === 'next' || ref1 === 'bottom') && urlIsNotCached)
  const setTop =
    firstRequest || (((ref2 = options.page) === 'prev' || ref2 === 'top') && urlIsNotCached)
  const oldUrls = this.urls
  this.urls = this._parsePageLinks(xhr)
  if (setBottom && this.urls.next != null) {
    this.urls.bottom = this.urls.next
  } else if (!this.urls.next) {
    delete this.urls.bottom
  } else {
    this.urls.bottom = oldUrls.bottom
  }
  if (setTop && this.urls.prev != null) {
    this.urls.top = this.urls.prev
  } else if (!this.urls.prev) {
    delete this.urls.top
  } else {
    this.urls.top = oldUrls.top
  }
  const url = (ref3 = this.urls.first) != null ? ref3 : this.urls.next
  if (url != null) {
    perPage = parseInt(url.match(this.perPageRegex)[1], 10)
    ;((base = this.options != null ? this.options : (this.options = {})).params != null
      ? base.params
      : (base.params = {})
    ).per_page = perPage
  }
  if (this.urls.last && (match = this.urls.last.match(this.pageRegex))) {
    this.totalPages = parseInt(match[1], 10)
  }
  if (!((ref4 = this.urls) != null ? ref4.next : void 0)) {
    this.loadedAll = true
  }
  return (this.atLeastOnePageFetched = true)
}

PaginatedCollection.prototype._parsePageLinks = function (xhr) {
  const linkHeader = xhr.getResponseHeader('link')
  if (!linkHeader) return {}

  const links = linkHeader.split(',')
  return links.reduce((result, link) => {
    const key = link.match(this.nameRegex)[1]
    const val = link.match(this.linkRegex)[1]
    result[key] = val
    return result
  }, {})
}

export default PaginatedCollection

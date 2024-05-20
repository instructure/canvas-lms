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
import template from '../../jst/PaginatedView.handlebars'

extend(PaginatedView, Backbone.View)

function PaginatedView() {
  return PaginatedView.__super__.constructor.apply(this, arguments)
}

PaginatedView.prototype.paginationLoaderTemplate = template

// set default scroll container to window.document.body, because as of jquery 2.0, $(window).is(':visible') is no longer supported, see https://bugs.jquery.com/ticket/14709/
PaginatedView.prototype.paginationScrollContainer = window.document.body

PaginatedView.prototype.distanceTillFetchNextPage = 100

// options
//   fetchOptions: options passed to the collection's fetch function
PaginatedView.prototype.initialize = function (options) {
  const ret = PaginatedView.__super__.initialize.call(this, options)
  this.fetchOptions = options.fetchOptions
  this.bindPaginationEvents()
  this.paginationStopped = false
  return ret
}

PaginatedView.prototype.render = function () {
  const ret = PaginatedView.__super__.render.apply(this, arguments)
  if (this.collection.fetchingNextPage) {
    this.showPaginationLoader()
  }
  this.startPaginationListener()
  return ret
}

PaginatedView.prototype.showPaginationLoader = function () {
  if (this.$paginationLoader == null) {
    this.$paginationLoader = $(this.paginationLoaderTemplate())
  }
  return this.placePaginationLoader()
}

PaginatedView.prototype.placePaginationLoader = function () {
  let ref
  return (ref = this.$paginationLoader) != null ? ref.insertAfter(this.el) : void 0
}

PaginatedView.prototype.hidePaginationLoader = function () {
  let ref
  return (ref = this.$paginationLoader) != null ? ref.remove() : void 0
}

PaginatedView.prototype.distanceToBottom = function () {
  const $container = $(this.paginationScrollContainer)
  const containerScrollHeight =
    $container[0] === window ? $(document).height() : $container[0].scrollHeight
  return containerScrollHeight - $container.scrollTop() - $container.height()
}

PaginatedView.prototype.startPaginationListener = function () {
  if (this.paginationStopped) {
    return
  }
  const fn = $.proxy(this.fetchNextPageIfNeeded, this)
  $(this.paginationScrollContainer).on('scroll.pagination:' + this.cid, fn)
  $(this.paginationScrollContainer).on('resize.pagination:' + this.cid, fn)
  return this.fetchNextPageIfNeeded()
}

PaginatedView.prototype.stopPaginationListener = function () {
  this.paginationStopped = true
  return $(this.paginationScrollContainer).off('.pagination:' + this.cid)
}

PaginatedView.prototype.fetchNextPageIfNeeded = function () {
  // let the call stack play out before checking the scroll position.
  return setTimeout(
    (function (_this) {
      return function () {
        if (_this.collection.fetchingNextPage) {
          return
        }
        if (!_this.collection.urls || !_this.collection.urls.next) {
          if (_this.collection.length) {
            _this.stopPaginationListener()
          }
          return
        }
        const shouldFetchNextPage =
          _this.distanceToBottom() < _this.distanceTillFetchNextPage || !_this.collection.length
        if ($(_this.paginationScrollContainer).is(':visible') && shouldFetchNextPage) {
          return _this.collection.fetch({
            page: 'next',
            ..._this.fetchOptions,
          })
        }
      }
    })(this),
    0
  )
}

PaginatedView.prototype.bindPaginationEvents = function () {
  this.collection.on('beforeFetch:next', this.showPaginationLoader, this)
  this.collection.on('fetch:next', this.hidePaginationLoader, this)
  return this.collection.on('all', this.fetchNextPageIfNeeded, this)
}

export default PaginatedView

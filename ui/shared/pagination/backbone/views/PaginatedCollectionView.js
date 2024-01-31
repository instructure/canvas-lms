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
import CollectionView from '@canvas/backbone-collection-view'
import template from '../../jst/paginatedCollection.handlebars'

extend(PaginatedCollectionView, CollectionView)

// General purpose lazy-load view. It must have a PaginatedCollection.
//
// TODO: We should replace all PaginatedView instances with this
//
// example:
//
//   new PaginatedCollectionView
//     collection: somePaginatedCollection
//     itemView: SomeItemView

function PaginatedCollectionView() {
  this.showLoadingIndicator = this.showLoadingIndicator.bind(this)
  this.hideLoadingIndicator = this.hideLoadingIndicator.bind(this)
  this.checkScroll = this.checkScroll.bind(this)
  this.detachScroll = this.detachScroll.bind(this)
  this.attachScroll = this.attachScroll.bind(this)
  this.resetScrollContainer = this.resetScrollContainer.bind(this)
  return PaginatedCollectionView.__super__.constructor.apply(this, arguments)
}

PaginatedCollectionView.prototype.defaults = {
  // Distance to begin fetching the next page
  buffer: 500,
  // Container with observed scroll position, can be a jQuery element, raw
  // dom node, or selector
  scrollContainer: window,
}

// Adds a loading indicator element
PaginatedCollectionView.prototype.els = {
  ...CollectionView.prototype.els,
  '.paginatedLoadingIndicator': '$loadingIndicator',
}

PaginatedCollectionView.optionProperty('scrollableElement')

PaginatedCollectionView.optionProperty('scrollContainer')

// Whether the collection should keep fetching pages until below the
// viewport. Defaults to false (i.e. just do one fetch per scroll)
PaginatedCollectionView.optionProperty('autoFetch')

// Whether the collection should keep fetching pages until the last
// page is reached.  Defaults to false
PaginatedCollectionView.optionProperty('fetchItAll')

PaginatedCollectionView.prototype.template = template

// Initializes
PaginatedCollectionView.prototype.initialize = function () {
  PaginatedCollectionView.__super__.initialize.apply(this, arguments)
  return this.initScrollContainer()
}

// Set the scroll container after the view has been created.
// Useful if the view is created before the container is rendered.
PaginatedCollectionView.prototype.resetScrollContainer = function (container) {
  this.detachScroll()
  this.scrollContainer = container
  this.initScrollContainer()
  return this.attachScroll()
}

// Extends parent to detach scroll container event
//
// @api private
PaginatedCollectionView.prototype.attachCollection = function () {
  PaginatedCollectionView.__super__.attachCollection.apply(this, arguments)
  this.listenTo(this.collection, 'reset', this.attachScroll)
  this.listenTo(this.collection, 'fetched:last', this.detachScroll)
  this.listenTo(this.collection, 'beforeFetch', this.showLoadingIndicator)
  if (this.autoFetch || this.fetchItAll) {
    return this.listenTo(
      this.collection,
      'fetch',
      (function (_this) {
        return function () {
          return setTimeout(_this.checkScroll)
        }
      })(this)
    )
  } else {
    return this.listenTo(this.collection, 'fetch', this.hideLoadingIndicator)
  }
}

// Sets instance properties regarding the scrollContainer
//
// @api private
PaginatedCollectionView.prototype.initScrollContainer = function () {
  this.$scrollableElement = this.scrollableElement ? $(this.scrollableElement) : this.$el
  this.scrollContainer = $(this.scrollContainer)
  return (this.heightContainer =
    this.scrollContainer[0] === window ? $(document.body) : this.scrollContainer)
}

// Attaches scroll event to scrollContainer
//
// @api private
PaginatedCollectionView.prototype.attachScroll = function () {
  const scroll = 'scroll.pagination:' + this.cid
  const resize = 'resize.pagination:' + this.cid
  this.scrollContainer.on(scroll, this.checkScroll)
  return this.scrollContainer.on(resize, this.checkScroll)
}

// Removes the scoll event from scrollContainer
//
// @api private
PaginatedCollectionView.prototype.detachScroll = function () {
  return this.scrollContainer.off('.pagination:' + this.cid)
}

// Determines if we need to fetch the collection's next page
//
// @api public
PaginatedCollectionView.prototype.checkScroll = function () {
  let ref, ref1
  if (this.collection.fetchingPage || this.collection.fetchingNextPage || !this.$el.length) {
    return
  }
  const elementBottom =
    (((ref = this.$scrollableElement.position()) != null ? ref.top : void 0) || 0) +
    this.$scrollableElement.height() -
    ((ref1 = this.heightContainer.position()) != null ? ref1.top : void 0)
  const distanceToBottom =
    elementBottom - this.scrollContainer.scrollTop() - this.scrollContainer.height()
  if (
    (this.fetchItAll || distanceToBottom < this.options.buffer) &&
    this.collection.canFetch('next')
  ) {
    return this.collection.fetch({
      page: 'next',
    })
  } else {
    return this.hideLoadingIndicator()
  }
}

// Remove scroll event if view is removed
//
// @api public
PaginatedCollectionView.prototype.remove = function () {
  this.detachScroll()
  return PaginatedCollectionView.__super__.remove.apply(this, arguments)
}

// Hides the loading indicator after render
//
// @api private
PaginatedCollectionView.prototype.afterRender = function () {
  PaginatedCollectionView.__super__.afterRender.apply(this, arguments)
  if (!this.collection.fetchingPage) {
    return this.hideLoadingIndicator()
  }
}

// Hides the loading indicator
//
// @api private
PaginatedCollectionView.prototype.hideLoadingIndicator = function () {
  let ref
  return (ref = this.$loadingIndicator) != null ? ref.hide() : void 0
}

// Shows the loading indicator
//
// @api private
PaginatedCollectionView.prototype.showLoadingIndicator = function () {
  let ref
  return (ref = this.$loadingIndicator) != null ? ref.show() : void 0
}

export default PaginatedCollectionView

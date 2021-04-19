#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import _ from 'underscore'
import CollectionView from '@canvas/backbone-collection-view'
import template from '../../jst/paginatedCollection.handlebars'

##
# General purpose lazy-load view. It must have a PaginatedCollection.
#
# TODO: We should replace all PaginatedView instances with this
#
# example:
#
#   new PaginatedCollectionView
#     collection: somePaginatedCollection
#     itemView: SomeItemView

export default class PaginatedCollectionView extends CollectionView

  defaults:

    ##
    # Distance to begin fetching the next page

    buffer: 500

    ##
    # Container with observed scroll position, can be a jQuery element, raw
    # dom node, or selector

    scrollContainer: window

  ##
  # Adds a loading indicator element

  els: _.extend({}, CollectionView::els,
    '.paginatedLoadingIndicator': '$loadingIndicator'
  )

  @optionProperty 'scrollableElement'
  @optionProperty 'scrollContainer'

  ##
  # Whether the collection should keep fetching pages until below the
  # viewport. Defaults to false (i.e. just do one fetch per scroll)
  @optionProperty 'autoFetch'

  ##
  # Whether the collection should keep fetching pages until the last
  # page is reached.  Defaults to false
  @optionProperty 'fetchItAll'

  template: template

  ##
  # Initializes the view

  initialize: ->
    super
    @initScrollContainer()

  ##
  # Set the scroll container after the view has been created.
  # Useful if the view is created before the container is rendered.

  resetScrollContainer: (container) =>
    @detachScroll()
    @scrollContainer = container
    @initScrollContainer()
    @attachScroll()

  ##
  # Extends parent to detach scroll container event
  #
  # @api private

  attachCollection: ->
    super
    @listenTo @collection, 'reset', @attachScroll
    @listenTo @collection, 'fetched:last', @detachScroll
    @listenTo @collection, 'beforeFetch', @showLoadingIndicator
    if @autoFetch or @fetchItAll
      @listenTo @collection, 'fetch', => setTimeout @checkScroll # next tick so events don't stomp on each other
    else
      @listenTo @collection, 'fetch', @hideLoadingIndicator

  ##
  # Sets instance properties regarding the scrollContainer
  #
  # @api private

  initScrollContainer: ->
    @$scrollableElement = if @scrollableElement
      $ @scrollableElement
    else
      @$el
    @scrollContainer = $ @scrollContainer
    @heightContainer = if @scrollContainer[0] is window
      # window has no position
      $ document.body
    else
      @scrollContainer

  ##
  # Attaches scroll event to scrollContainer
  #
  # @api private

  attachScroll: =>
    scroll = "scroll.pagination:#{@cid}"
    resize = "resize.pagination:#{@cid}"
    @scrollContainer.on scroll, @checkScroll
    @scrollContainer.on resize, @checkScroll

  ##
  # Removes the scoll event from scrollContainer
  #
  # @api private

  detachScroll: =>
    @scrollContainer.off ".pagination:#{@cid}"

  ##
  # Determines if we need to fetch the collection's next page
  #
  # @api public

  checkScroll: =>
    return if @collection.fetchingPage or @collection.fetchingNextPage or not @$el.length
    elementBottom = (@$scrollableElement.position()?.top || 0) +
      @$scrollableElement.height() -
      @heightContainer.position()?.top
    distanceToBottom = elementBottom -
      @scrollContainer.scrollTop() -
      @scrollContainer.height()
    if (@fetchItAll || distanceToBottom < @options.buffer) and @collection.canFetch('next')
      @collection.fetch page: 'next'
    else
      @hideLoadingIndicator()

  ##
  # Remove scroll event if view is removed
  #
  # @api public

  remove: ->
    @detachScroll()
    super

  ##
  # Hides the loading indicator after render
  #
  # @api private

  afterRender: ->
    super
    @hideLoadingIndicator() unless @collection.fetchingPage

  ##
  # Hides the loading indicator
  #
  # @api private

  hideLoadingIndicator: =>
    @$loadingIndicator?.hide()

  ##
  # Shows the loading indicator
  #
  # @api private

  showLoadingIndicator: =>
    @$loadingIndicator?.show()

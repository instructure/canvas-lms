#
# Copyright (C) 2012 Instructure, Inc.
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
#

define [
  'Backbone'
  'underscore'
], (Backbone, _) ->

  capitalize = (string = '') ->
    string.charAt(0).toUpperCase() + string.substring(1).toLowerCase()

  class @PaginatedCollection extends Backbone.Collection

    # Matches the name of each link: "next," "prev," "first," or "last."
    nameRegex: /rel="([a-z]+)/

    # Matches the full link, e.g. "/api/v1/accounts/1/users?page=1&per_page=15"
    linkRegex: /^<([^>]+)/

    pageRegex: /\Wpage=(\d+)/

    perPageRegex: /\per_page=(\d+)/

    ##
    # have to do this stuff here or else 'reset' and other events are fired
    # before _setStateAfterFetch has happened, so the state is just barely off
    parse: (response, xhr) ->
      @_urlCache ?= []
      @_lastFetchOptions ?= {}
      @_setStateAfterFetch xhr, @_lastFetchOptions
      @_urlCache.push @_lastFetchOptions.url unless @_lastFetchOptions.url in @_urlCache
      delete @_lastFetchOptions
      super

    ##
    # options.page: 'next', 'prev', 'first', 'last', 'top', 'bottom'
    fetch: (options = {}) ->
      @["fetching#{capitalize options.page}Page"] = true
      if options.page?
        options.url = @urls[options.page] if @urls?
        options.add = true unless options.add?
        # API keeps params intact, kill data here to avoid appending in super
        options.data = ''
      @_lastFetchOptions = options
      @trigger 'beforeFetch', this, options
      @trigger "beforeFetch:#{options.page}", this, options if options.page?
      super(options).done (response, text, xhr) =>
        @["fetching#{capitalize options.page}Page"] = false
        @fetchingNextPage = false
        @trigger 'fetch', this, response, options
        @trigger "fetch:#{options.page}", this, response, options if options.page?
        @trigger 'fetched:last', arguments... unless @urls.next

    canFetch: (page) ->
      @urls? and @urls[page]?

    _setStateAfterFetch: (xhr, options={}) =>
      urlIsNotCached = options.url not in @_urlCache
      firstRequest = !@urls?
      setBottom = firstRequest or (options.page in ['next', 'bottom'] and urlIsNotCached)
      setTop = firstRequest or (options.page in ['prev', 'top'] and urlIsNotCached)
      oldUrls = @urls
      @urls = @_parsePageLinks xhr

      if setBottom and @urls.next?
        @urls.bottom = @urls.next
      else if !@urls.next
        delete @urls.bottom
      else
        @urls.bottom = oldUrls.bottom

      if setTop and @urls.prev?
        @urls.top = @urls.prev
      else if !@urls.prev
        delete @urls.top
      else
        @urls.top = oldUrls.top

      perPage = parseInt(@urls.first.match(@perPageRegex)[1], 10)
      (@options.params ?= {}).per_page = perPage
      @totalPages = parseInt(@urls.last?.match(@pageRegex)[1], 10)
      @atLeastOnePageFetched = true

    _parsePageLinks: (xhr) ->
      linkHeader = xhr.getResponseHeader('link').split(',')
      _.reduce linkHeader, (links, link) =>
        key = link.match(@nameRegex)[1]
        val = link.match(@linkRegex)[1]
        links[key] = val
        links
      , {}


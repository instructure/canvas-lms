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

  class PaginatedCollection extends Backbone.Collection

    # Matches the name of each link: "current", "next," "prev," "first," or "last."
    nameRegex: /rel="([a-z]+)/

    # Matches the full link, e.g. "/api/v1/accounts/1/users?page=1&per_page=15"
    linkRegex: /^<([^>]+)/

    pageRegex: /\Wpage=(\d+)/

    perPageRegex: /\Wper_page=(\d+)/

    initialize: ->
      super
      @urls = {}

    ##
    # options.page: 'current', 'next', 'prev', 'first', 'last', 'top', 'bottom'
    fetch: (options = {}) ->
      options = _.clone(options)
      @loadedAll = false
      exclusionFlag = "fetching#{capitalize options.page}Page"
      @[exclusionFlag] = true
      if options.page?
        options.url = @urls[options.page] if @urls?
        options.remove = false unless options.remove?
        # API keeps params intact, kill data here to avoid appending in super
        options.data = ''
      else
        # we want the first fetch to reset (since a lot of existing code wants a reset event)
        options.reset = true unless options.reset?
      @trigger 'beforeFetch', this, options
      @trigger "beforeFetch:#{options.page}", this, options if options.page?

      # have to do this stuff here or else 'reset' and other events are fired
      # before _setStateAfterFetch has happened, so the state is just barely off
      xhr = null
      options.dataFilter = (data) =>
        @[exclusionFlag] = false
        @_setStateAfterFetch(xhr, options)
        data

      dfd = options.dfd || $.Deferred()
      xhr = super(options).done (response, text, xhr) =>
        @trigger 'fetch', this, response, options
        @trigger "fetch:#{options.page}", this, response, options if options.page?
        unless @urls?.next
          @trigger 'fetched:last', arguments...
          @loadedAll = true
        if @loadAll and @urls.next?
          setTimeout =>
            @fetch page: 'next', dfd: dfd # next tick so we can show loading indicator, etc.
        else
          dfd.resolve(response, text, xhr)
      dfd.abort = xhr.abort
      dfd.success = dfd.done
      dfd.error = dfd.fail
      dfd

    canFetch: (page) ->
      @urls? and @urls[page]?

    _setStateAfterFetch: (xhr, options) =>
      @_urlCache ?= []
      urlIsNotCached = options.url not in @_urlCache
      @_urlCache.push options.url if not urlIsNotCached
      firstRequest = !@atLeastOnePageFetched
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

      url = @urls.first ? @urls.next
      if url?
        perPage = parseInt(url.match(@perPageRegex)[1], 10)
        (@options.params ?= {}).per_page = perPage

      if @urls.last and match = @urls.last.match(@pageRegex)
        @totalPages = parseInt(match[1], 10)

      @atLeastOnePageFetched = true

    _parsePageLinks: (xhr) ->
      linkHeader = xhr.getResponseHeader('link')?.split(',')
      linkHeader ?= []
      _.reduce linkHeader, (links, link) =>
        key = link.match(@nameRegex)[1]
        val = link.match(@linkRegex)[1]
        links[key] = val
        links
      , {}


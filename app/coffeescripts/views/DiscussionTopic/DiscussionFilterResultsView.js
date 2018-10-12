#
# Copyright (C) 2012 - present Instructure, Inc.
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

define [
  'jst/discussions/noResults'
  'jquery'
  'underscore'
  '../DiscussionTopic/FilterEntryView'
  '../DiscussionTopic/EntryCollectionView'
  '../../collections/EntryCollection'
  '../../regexp/rEscape'
], (noResultsTemplate, $, _, FilterEntryView, EntryCollectionView, EntryCollection, rEscape) ->

  class DiscussionFilterResultsView extends EntryCollectionView

    defaults: _.extend({}, EntryCollectionView::defaults,
      descendants: 0
      displayShowMore: true
      threaded: true
    )

    initialize: ->
      super
      @allData = @options.allData

    attach: ->
      @model.on 'change', @renderOrTeardownResults

    setAllReadState: (newReadState) ->
      if @collection?
        @collection.fullCollection.each (entry) ->
          entry.set 'read_state', newReadState

    resetCollection: (models) =>
      collection = new EntryCollection models, perPage: 10
      @collection = collection.getPageAsCollection 0
      @collection.on 'add', @add
      @render()
      # sync read_state changes between @collection and @allData materialized view
      @collection.on 'change:read_state', (entry, read_state) =>
        @trigger 'readStateChanged', entry.id, read_state
        # check if rendered entry exists to visually update
        $el = $("#entry-#{entry.id}")
        if $el.length
          entry = $el.data('view').model
          entry.set 'read_state', read_state if entry

    add: (entry) =>
      view = new FilterEntryView model: entry
      view.render()
      view.on 'click', =>
        @clearModel()
        setTimeout =>
          @trigger 'clickEntry', view.model
        , 1
      @list.append view.el

    toggleRead: (e) ->
      e.preventDefault()
      if @model.get('read_state') is 'read'
        @model.markAsUnread()
      else
        @model.markAsRead()

    clearModel: =>
      @model.reset()

    render: =>
      super if @collection?
      @trigger 'render'
      @$el.removeClass 'hidden'

    renderOrTeardownResults: =>
      if @model.hasFilter()
        results = (entry for id, entry of @allData.flattened)
        for filter, value of @model.toJSON()
          filterFn = @["#{filter}Filter"]
          results = filterFn(value, results) if filterFn
        if results.length
          @resetCollection results
        else
          @renderNoResults()
      else if not @model.hasFilter()
        @$el.addClass 'hidden'
        @trigger 'hide'

    renderNoResults: ->
      @render()
      @$el.html noResultsTemplate

    unreadFilter: (unread, results) =>
      return results unless unread
      unread = _.filter results, (entry) ->
        entry.read_state is 'unread'
      unread.sort (a, b) ->
        Date.parse(a.created_at) - Date.parse(b.created_at)

    queryFilter: (query, results) =>
      regexps = for word in (query ? '').trim().split(/\s+/g)
        new RegExp rEscape(word), 'i'
      return results unless regexps.length
      _.filter results, (entry) ->
        return false if entry.deleted
        concat = """
          #{entry.message}
          #{entry.author.display_name}
        """
        for regexp in regexps
          return false unless regexp.test concat
        true


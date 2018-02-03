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
  'jquery'
  '../DiscussionTopics/DiscussionsSettingsView'
  '../DiscussionTopics/UserSettingsView'
  'i18n!discussion_topics'
  'underscore'
  'jst/announcements/IndexView'
  '../PaginatedView'
  '../DiscussionTopics/SummaryView'
  '../../collections/AnnouncementsCollection'
], ($, DiscussionsSettingsView, UserSettingsView, I18n, _, template, PaginatedView, DiscussionTopicSummaryView, AnnouncementsCollection) ->

  class IndexView extends PaginatedView

    template: template

    el: '#content'

    events:
      'change #onlyUnread, #onlyGraded, #searchTerm' : 'handleFilterChange'
      'input #searchTerm' : 'handleFilterChange'

      # IE doesn't fire 'input' event and doesn't fire 'change' till blur,
      # so have to listen to all keups too.
      'keyup #searchTerm' : 'handleFilterChange'

      'sortupdate' : 'handleSortUpdate'
      'change #lock' : 'toggleLockingSelectedTopics'
      'click #delete' : 'destroySelectedTopics'
      'click #edit_discussions_settings': 'toggleSettingsView'

    initialize: ->
      super
      @attachCollection()
      @render()

    attachCollection: ->
      @collection.on 'remove', => @render() unless @collection.length
      @collection.on 'reset', @render
      @collection.on 'add', @renderList
      @collection.on 'fetch:next', @fetchedNextPage
      @collection.on 'fetched:last', @fetchedLastPage
      @collection.on 'change:selected', @toggleActionsForSelectedDiscussions

    afterRender: ->
      @$('#discussionsFilter').buttonset()
      @renderList()
      @toggleActionsForSelectedDiscussions()
      this

    toggleSettingsView: ->
      @settingsView or= if @options.permissions.change_settings
        new DiscussionsSettingsView()
      else
        new UserSettingsView()
      @settingsView.toggle()

    screenreaderSearchResultCount: ->
      # if count < page limit and we've got the last page, then we've got all the results
      text = ''

      if Object.keys(@activeFilters()).length == 0
        text = I18n.t('Showing all announcements')
      else if !@lastPageFetched
        text = I18n.t({one: 'One result displayed', other: '%{count} results displayed'}, {count: @resultCount})
      else
        text = I18n.t({one: 'One result', other: '%{count} results'}, {count: @resultCount})

      if @$('#searchResultCount').text() != text
        @$('#searchResultCount').text(text)


    renderList: =>
      $list = @$('.discussionTopicIndexList').empty()
      fetching = @collection.fetchingNextPage
      # this is kinda weird. we map with the side effecting add function and use the results, which are either jquery
      # objects or null i think, to determine how many results we have since the add function applies the filter.
      @resultCount = _.filter(@collection.map(@addDiscussionTopicToList), Boolean).length
      gotSomething = @resultCount > 0
      noResults = !gotSomething && !fetching
      filtering = Object.keys(@activeFilters()).length > 0

      @screenreaderSearchResultCount()
      @$('.nothingMatchedFilter').toggle noResults

      makeSortable = gotSomething &&
                     !filtering &&
                     !@isShowingAnnouncements() &&
                     @options.permissions.moderate
      if makeSortable
        $list.sortable
          axis: 'y'
          cancel: 'a'
          containment: $list
          cursor: 'ns-resize'
          handle: '.discussion-drag-handle'
          tolerance: 'pointer'

      else if $list.is(':ui-sortable')
        $list.sortable('destroy')

    addDiscussionTopicToList: (discussionTopic) =>
      if @modelMeetsFilterRequirements(discussionTopic)
        view = new DiscussionTopicSummaryView
          model: discussionTopic
          permissions: @options.permissions
        @$('.discussionTopicIndexList').append view.render().el

    fetchedNextPage: =>
      $list = @$('.discussionTopicIndexList')
      if @collection.length && !$list.length
        @render()
      else
        @renderList()

    fetchedLastPage: =>
      @lastPageFetched = true
      @render() if !@collection.length

    toggleActionsForSelectedDiscussions: =>
      selectedTopics = @selectedTopics()
      atLeastOneSelected = selectedTopics.length > 0
      $actions = @$('#actionsForSelectedDiscussions')
      if atLeastOneSelected
        $actions.removeClass 'screenreader-only'
        $actions.find('button,input').prop('disabled', false)
        checkLock = _.any selectedTopics, (model) -> model.get('locked')
        $actions.buttonset()
      else
        $actions.addClass 'screenreader-only'
        $actions.find('button,input').prop('disabled', true)

    toggleLockingSelectedTopics: ->
      lock = @$('#lock').is(':checked')
      _.invoke @selectedTopics(), 'updateOneAttribute', 'locked', lock

    destroySelectedTopics: ->
      selectedTopics = @selectedTopics()

      message = if @isShowingAnnouncements()
        I18n.t 'confirm_delete_announcement',
          one: 'Are you sure you want to delete this announcement?'
          other: 'Are you sure you want to delete these %{count} announcements?'
        ,
          count: selectedTopics.length
      else
        I18n.t 'confirm_delete_discussion_topic',
          one: 'Are you sure you want to delete this discussion topic?'
          other: 'Are you sure you want to delete these %{count} discussion topics?'
        ,
          count: selectedTopics.length

      if confirm message
        _(selectedTopics).invoke 'destroy'
        @toggleActionsForSelectedDiscussions()

    selectedTopics: ->
      @collection.filter (model) -> model.selected

    modelMeetsFilterRequirements: (model) =>
      _.all @activeFilters(), (fn, key) =>
        fn.call(model, @[key])

    handleSortUpdate: (event, ui) =>
      id = ui.item.data 'id'
      otherId = ui.item.next('.discussion-topic').data 'id'
      @collection.get(id).positionAfter otherId

    activeFilters: ->
      res = {}
      res[key] = fn for key, fn of @filters when @[key]
      res

    handleFilterChange: (event) ->
      input = event.target
      val = if input.type is "checkbox" then input.checked else input.value
      if @[input.id] != val
        @[input.id] = val
        @renderList()
        @collection.trigger 'aBogusEventToCauseYouToFetchNextPageIfNeeded'

    filters:
      onlyGraded: -> @get 'assignment_id'
      onlyUnread: -> (@get('read_state') is 'unread') or @get('unread_count')
      searchTerm: (term) ->
        return unless term
        regexp = new RegExp(term, "ig")
        @get('author')?.display_name?.match(regexp) ||
          @get('title').match(regexp) ||
          @summary().match(regexp)

    isShowingAnnouncements: ->
      @collection.constructor == AnnouncementsCollection

    toJSON: ->
      new_topic_url = @collection.url().replace('/api/v1', '') + '/new'
      if @isShowingAnnouncements()
        new_topic_url = (new_topic_url + '?is_announcement=true')
                        # announcements will have a '?only_announcements=true' at the end, remove it
                        .replace(@collection._stringToAppendToURL, '')
      filterProps = _.pick this, _.keys(@filters)
      collectionProps = _.pick @collection, ['atLeastOnePageFetched', 'length']
      _.extend
        new_topic_url: new_topic_url
        options: @options
        showingAnnouncements: @isShowingAnnouncements()
        lastPageFetched: @lastPageFetched
      , filterProps, collectionProps

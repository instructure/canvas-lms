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
  'underscore'
  'Backbone'
  'i18n!discussion_topics'
  'jst/DiscussionTopics/IndexView'
  './DiscussionsSettingsView'
  './UserSettingsView'
], ($, _, {View}, I18n, template, DiscussionsSettingsView, UserSettingsView) ->

  class IndexView extends View
    template: template

    el: '#content'

    @child 'openDiscussionView',   '.open.discussion-list'
    @child 'lockedDiscussionView', '.locked.discussion-list'
    @child 'pinnedDiscussionView', '.pinned.discussion-list'

    events:
      'click .ig-header .element_toggler': 'toggleDiscussionList'
      'focus .accessibility-warning': 'handleAccessibilityWarningFocus'
      'blur .accessibility-warning': 'handleAccessibilityWarningBlur'
      'keydown .ig-header .element_toggler': 'toggleDiscussionList'
      'click .discussion-list': 'toggleDiscussionListWithVo'
      'click #edit_discussions_settings':  'toggleSettingsView'
      'change #onlyUnread, #onlyGraded':   'filterResults'
      'keyup #searchTerm':                 'filterResults'

    filters:
      onlyGraded:
        active: false
        fn: (model) ->
          model.get('assignment_id')
      onlyUnread:
        active: false
        fn: (model) ->
          model.get('unread_count') > 0 or model.get('read_state') is 'unread'
      searchTerm:
        active: false
        fn: (model, term) ->
          return unless term
          regex = new RegExp(term, 'ig')
          model.get('title').match(regex) or
            model.get('user_name')?.match(regex) or
            model.summary().match(regex)

    collections: ->
      [
        @options.openDiscussionView.collection
        @options.lockedDiscussionView.collection
        @options.pinnedDiscussionView.collection
      ]

    initialize: ->
      super
      @listenTo(@options.pinnedDiscussionView.collection, "add remove", @handleAddRemovePinnedDiscussion)

    afterRender: ->
      @$('#discussionsFilter').buttonset()
      @setAccessibilityWarningState();

    activeFilters: ->
      _.select(@filters, (value, key) => value.active)

    filter: (model, term) =>
      _.all(@activeFilters(), (filter) -> filter.fn.call(model, model, term))

    screenreaderSearchResultCount: _.debounce ->
      text = ''
      if @activeFilters().length > 0
        text = I18n.t({one: 'One result', other: '%{count} results'}, {count: @resultCount})
      else
        text = I18n.t('Showing all discussions')
      @$('#searchResultCount').text(text)
    , 1000

    filterResults: (e) =>
      if e.target.type is 'checkbox'
        @filters[e.target.id].active = $(e.target).prop('checked')
        term = $('#searchTerm').val() if $('#searchTerm').val().length > 0
      else
        @filters[e.target.id].active = $(e.target).val().length > 0
        term = $(e.target).val()

      resultCount = 0
      _.each @collections(), (collection) =>
        collection.each (model) =>
          if @activeFilters().length > 0
            hidden = !@filter(model, term)
            if !hidden
              resultCount += 1
            model.set('hidden', hidden)
          else
            resultCount += 1
            model.set('hidden', false)
      @resultCount = resultCount
      @screenreaderSearchResultCount()

    toggleSettingsView: ->
      @settingsView().toggle()

    toggleDiscussionList: (e) ->
      $currentTarget = $(e.currentTarget)
      # If we get a keydown that is not enter or space, ignore.
      # Otherwise, simulate a click.
      if e.type is 'keydown'
        if e.keyCode in [13, 32]
          e.preventDefault()
          $currentTarget.click()
        return
      $icon = $currentTarget.find('i')
      while $currentTarget.length && $icon.length is 0
        $currentTarget = $currentTarget.parent()
        $icon = $currentTarget.find('i')
      return unless $icon.length
      $icon.toggleClass('icon-mini-arrow-down').toggleClass('icon-mini-arrow-right')

    setAccessibilityWarningState: ->
      if @options.pinnedDiscussionView.collection.length > 1
        $('.accessibility-warning').show()
      else
        $('.accessibility-warning').hide()

    handleAddRemovePinnedDiscussion: ->
      @setAccessibilityWarningState();

    handleAccessibilityWarningFocus: (e) ->
      if @options.pinnedDiscussionView.collection.length > 1
        $accessibilityWarning = $(e.currentTarget)
        $accessibilityWarning.removeClass('screenreader-only')

    handleAccessibilityWarningBlur: (e) ->
      if @options.pinnedDiscussionView.collection.length > 1
        $accessibilityWarning = $(e.currentTarget)
        $accessibilityWarning.addClass('screenreader-only')
    
    toggleDiscussionListWithVo: (e) ->
      # if this event bubbled up from somewhere else, do nothing.
      return unless e.target is e.delegateTarget or e.target.isSameNode?(e.delegateTarget)
      $(e.target).find('.ig-header .element_toggler').first().click()
      false

    settingsView: ->
      @_settingsView or= if @options.permissions.change_settings
        new DiscussionsSettingsView()
      else
        new UserSettingsView()
      @_settingsView

    toJSON: ->
      _.extend {},
        options: @options,
        length: 1,
        atLeastOnePageFetched: true
        new_topic_url: ENV.newTopicURL

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
  'Backbone'
  'underscore'
  'jqueryui/button'
], ({View}, _) ->

  ##
  # requires a MaterializedDiscussionTopic model
  class DiscussionToolbarView extends View

    els:
      '#discussion-search': '$searchInput'
      '#onlyUnread': '$unread'
      '#showDeleted': '$deleted'
      '.disableWhileFiltering': '$disableWhileFiltering'

    events:
      'keyup #discussion-search': 'filterBySearch'
      'change #onlyUnread': 'toggleUnread'
      'change #showDeleted': 'toggleDeleted'
      'click #collapseAll': 'collapseAll'
      'click #expandAll': 'expandAll'

    initialize: ->
      super
      @model.on 'change', @clearInputs

    afterRender: ->
      @$unread.button()
      @$deleted.button()

    filter: @::afterRender

    clearInputs: =>
      return if @model.hasFilter()
      @$searchInput.val ''
      @$unread.prop 'checked', false
      @$unread.button 'refresh'
      @maybeDisableFields()

    filterBySearch: _.debounce ->
      value = @$searchInput.val()
      value = null if value is ''
      @model.set 'query', value
      @maybeDisableFields()
    , 250

    toggleUnread: ->
      # setTimeout so the ui can update the button before the rest
      # do expensive stuff

      setTimeout =>
        @model.set 'unread', @$unread.prop 'checked'
        @maybeDisableFields()
      , 50

    toggleDeleted: ->
      @trigger 'showDeleted', @$deleted.prop('checked')

    collapseAll: ->
      @model.set 'collapsed', true
      @trigger 'collapseAll'

    expandAll: ->
      @model.set 'collapsed', false
      @trigger 'expandAll'

    maybeDisableFields: ->
      @$disableWhileFiltering.attr 'disabled', @model.hasFilter()


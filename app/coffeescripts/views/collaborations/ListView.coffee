#
# Copyright (C) 2013 Instructure, Inc.
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
  'jquery'
  'underscore'
  'compiled/views/PaginatedView'
  'compiled/collections/UserCollection'
  'compiled/collections/GroupCollection'
  'jst/collaborations/collaborator'
], ($, {each, extend, flatten, reject}, PaginatedView, UserCollection, GroupCollection, collaboratorTemplate) ->

  class ListView extends PaginatedView
    # Members to exclude from the collection.
    filteredMembers: []

    events:
      'click a': 'selectCollaborator'

    initialize: (options = {}) ->
      @collection                = @createCollection(options.type)
      @paginationScrollContainer = @$el.parents('.list-wrapper')
      @attachEvents()
      super

    # Internal: Create a collection of the given type.
    #
    # type - The string name of the collection type (default: 'user').
    #
    # Returns a UserCollection or GroupCollection.
    createCollection: (type = 'user') ->
      if type is 'user'
        new UserCollection(comparator: (user) -> user.get('sortable_name'))
      else
        collection = new GroupCollection()
        collection.forCourse = true
        collection

    # Internal: Attach events to the collection.
    #
    # Returns nothing.
    attachEvents: ->
      @collection.on('add remove reset', @render)
                 .on('remove', (model) => @trigger('collection:remove', model))

    render: =>
      @updateFilter([])
      collaboratorsHtml = @collection.map(@renderCollaborator).join('')
      @$el.html(collaboratorsHtml)
      @updateFocus() if @currentIndex? && @hasFocus
      @hasFocus = false
      super

    # Internal: Return HTML for the given collaborator.
    #
    # Returns an HTML string.
    renderCollaborator: (collaborator) =>
      if collaborator.get('id') == @options.currentUser
        ''
      else
        binding = extend collaborator.toJSON(),
          name: collaborator.get('sortable_name') or collaborator.get('name')
          type: collaborator.modelType
        collaboratorTemplate(binding)

    # Internal: Set focus after render.
    #
    # Returns nothing.
    updateFocus: ->
      $target = $(@$el.find('li').get(@currentIndex)).find('a')
      $target = $(@$el.find('li').get(@currentIndex - 1)).find('a') if $target.length is 0
      $target = @$el.parents('.collaborator-picker').find('.members-list') if $target.length is 0
      $target.focus()

    # Internal: Select a collaborator and remove them from the collection.
    #
    # Returns nothing.
    selectCollaborator: (e) ->
      e.preventDefault()
      id = $(e.currentTarget).data('id')
      @currentIndex = $(e.currentTarget).parent().index()
      @hasFocus     = true
      @collection.remove(id)

    # Public: Filter out the given members. We wrap this in a setTimeout to
    # allow Backbone to catch up with itself; without it, the occassional
    # `cid of undefined` error crops up.
    #
    # models - An array of models to filter out of the collection.
    #
    # Returns nothing.
    updateFilter: (models) ->
      setTimeout =>
        @filteredMembers = flatten([@filteredMembers, models])
        each(@filteredMembers, (m) => @collection.remove(m, silent: true))
      , 0

    # Public: Remove the given model from the filter.
    #
    # model - The model to remove from the filter.
    #
    # Returns nothing.
    removeFromFilter: (model) ->
      @filteredMembers = reject @filteredMembers, (m) ->
        m.get('id') is model.get('id')


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
#

define [
  'jquery'
  'underscore'
  'Backbone'
  '../../models/Group'
  '../../models/User'
  '../../collections/CollaboratorCollection'
  'jst/collaborations/collaborator'
], ($, {extend, filter, map}, {View}, Group, User, CollaboratorCollection, collaboratorTemplate) ->

  class MemberListView extends View
    events:
      'click li a': 'removeCollaborator'
      'click .remove-all': 'removeAll'

    initialize: ->
      super
      @collection = @createCollection()
      @cacheElements()
      @attachEvents()

    # Internal: Create a new collection for use w/ this view.
    #
    # Returns a CollaboratorCollection.
    createCollection: ->
      new CollaboratorCollection

    # Internal: Store DOM elements to avoid repeated lookups.
    #
    # Returns nothing.
    cacheElements: ->
      @$list         = @$el.find('ul')
      @$removeBtn    = @$el.find('.remove-button')
      @$instructions = @$el.find('.member-instructions')

    # Internal: Attach events to the collection.
    #
    # Returns nothing.
    attachEvents: ->
      @collection.on('add remove reset', @render)
                 .on('reset sync',  @onFetch)
                 .on('remove', @deselectCollaborator)

    render: =>
      @updateElementVisibility()
      collaboratorsHtml = @collection.map (c) =>
        collaboratorTemplate(extend(c.toJSON(),
                                    type: c.modelType or c.get('type')
                                    collaborator_id: c.get('collaborator_id')
                                    id: c.get('id')
                                    name: c.get('sortable_name') or c.get('name')
                                    selected: true))
      collaboratorsHtml = collaboratorsHtml.join('')
      @$list.html(collaboratorsHtml)
      @updateFocus() if @currentIndex? && @hasFocus
      @hasFocus = false

    # Internal: Manage focus on re-render.
    #
    # Returns nothing.
    updateFocus: ->
      $target = $(@$el.find('li').get(@currentIndex)).find('a')
      $target = $(@$el.find('li').get(@currentIndex - 1)).find('a') if $target.length is 0
      $target = @$el.parents('.collaborator-picker').find('.list-wrapper:first ul:visible') if $target.length is 0
      $target.focus()

    # Internal: Remove a collaborator from this list.
    #
    # e - Event object.
    #
    # Returns nothing.
    removeCollaborator: (e) ->
      e.preventDefault()
      id = $(e.currentTarget).attr('data-id')
      @currentIndex = $(e.target).parent().index()
      @hasFocus     = true
      @collection.remove(id)

    # Internal: Remove all current collaborators.
    #
    # e - Event object.
    #
    # Returns nothing.
    removeAll: (e) ->
      e.preventDefault()
      @collection.remove(@collection.models)
      @currentIndex = 0
      @updateFocus()

    # Internal: Show/hide the remove all btn based on collection size.
    #
    # Returns nothing.
    updateElementVisibility: ->
      if @collection.length is 0
        @$removeBtn.hide()
        @$instructions.show()
      else
        @$removeBtn.show()
        @$instructions.hide()

    deselectCollaborator: (model) =>
      unless model.modelType?
        model = @typecastMember(model)
      @trigger('collection:remove', model)

    # Internal: Convert a collaborator into a user or group.
    #
    # model - The collaborator model to typecast.
    #
    # Returns a user or group model.
    typecastMember: (model) ->
      props = extend(model.toJSON(), id: model.get('collaborator_id'))
      if model.get('type') is 'user'
        new User(extend(props, sortable_name: props.name))
      else
        new Group(props)

    # Internal: Publish contents of the collection.
    #
    # collection - The child collection.
    #
    # Returns nothing.
    publishCollection: (collection) =>
      users  = collection.filter((m) -> m.get('type') is 'user')
      groups = collection.filter((m) -> m.get('type') is 'group')
      @trigger('collection:reset', 'user', map(users, @typecastMember))
      @trigger('collection:reset', 'group', map(groups, @typecastMember))

    onFetch: () =>
      @publishCollection(@collection)
      url = @getNextPage(@currentXHR.getResponseHeader('Link'))
      if url
        @collection.url = url
        @currentXHR = @collection.fetch(add: true)
        $.when(@currentXHR).then(@onFetch)

    getNextPage: (header) ->
      nextPage = filter(header.split(','), (l) -> l.match(/next/))[0]
      return if nextPage then nextPage.match(/http[^>]+/)[0] else false

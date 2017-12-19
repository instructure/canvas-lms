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

define [
  'underscore'
  '../CollectionView'
  './NeverDropView'
  'jst/assignments/NeverDropCollection'
], (_, CollectionView, NeverDropView, template) ->

  class NeverDropCollectionView extends CollectionView
    itemView: NeverDropView

    template: template

    @optionProperty 'canChangeDropRules'

    events:
      'click .add_never_drop': 'addNeverDrop'

    initialize: ->
      # feed all events that should trigger a render
      # through a custom event so that we only render
      # once per batch of changes
      @on 'should-render', _.debounce(@render, 100)
      super

    createItemView: (model) ->
      options =
        canChangeDropRules: @canChangeDropRules
      new @itemView $.extend {}, (@itemViewOptions || {}), {model}, options

    attachCollection: (options) ->
      #listen to events on the collection that keeps track of what we can add
      @collection.availableValues.on 'add', @triggerRender
      @collection.takenValues.on 'add', @triggerRender
      @collection.on 'add', @triggerRender
      @collection.on 'remove', @triggerRender
      @collection.on 'reset', @triggerRender

    # define some attrs here so that we can
    # use declarative translations in the template
    toJSON: ->
      data =
        canChangeDropRules: @canChangeDropRules
        hasAssignments: @collection.availableValues.length > 0
        hasNeverDrops: @collection.takenValues.length > 0

    triggerRender: (model, collection, options)=>
      @trigger 'should-render'

    # add a new select, and mark it for focusing
    # when we re-render the collection
    addNeverDrop: (e) ->
      e.preventDefault()
      if @canChangeDropRules
        model =
          label_id: @collection.ag_id
          focus: true
        @collection.add model

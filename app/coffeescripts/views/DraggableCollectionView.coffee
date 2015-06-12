define [
  'Backbone'
  'jquery'
  'underscore'
  'compiled/views/CollectionView'
], (Backbone, $, _, CollectionView) ->

  class DraggableCollectionView extends CollectionView

    # A Backbone Collection of Models that have an array of items (a child collection)
    @optionProperty 'parentCollection'
    # The key used to find the child collection
    @optionProperty 'childKey'
    # The group's ID
    @optionProperty 'groupId'
    # The group's name within the child
    @optionProperty 'groupKey'
    # the URL to send reorder updates to
    @optionProperty 'reorderURL'
    # the template used to fill empty groups
    @optionProperty 'noItemTemplate'

    sortOptions:
      tolerance: 'pointer'
      opacity: 0.9
      zIndex: 100
      connectWith: '.draggable.collectionViewItems'
      placeholder: 'draggable-dropzone'
      forcePlaceholderSize: true

    render: (drag=true) ->
      super
      @initSort() if drag
      @

    attachCollection: ->
      super
      @collection.on 'add', @_noItemsViewIfEmpty

    initSort: ->
      @$list.sortable(_.extend({}, @sortOptions, scope: @cid))
        .on('sortstart', @modifyPlaceholder)
        .on('sortreceive', @_onReceive)
        .on('sortupdate', @_updateSort)
        .on('sortremove', @_noItemsViewIfEmpty)
      @$list.disableSelection()
      @_noItemsViewIfEmpty()

    modifyPlaceholder: (e, ui) =>
      # Prevent the sortstart action from propagating up.
      e.stopPropagation()
      $(ui.placeholder).data("group", @groupId)

    # If there are no children within the group,
    # add the view that is used when there are no items in a group
    _noItemsViewIfEmpty: =>
      list = @$list.children()
      if list.length == 0
        @insertNoItemView()
      else
        @removeNoItemView()

    insertNoItemView: ->
      @noItems = new Backbone.View
        template: @noItemTemplate
        tagName: "li"
        className: "no-items"
      @$list.append(@noItems.render().el)

    removeNoItemView: ->
      @noItems.remove() if @noItems

    # Find an item without knowing the group it is in
    searchItem: (itemId) ->
      chosen = null
      @parentCollection.find (group) =>
        assignments = group.get(@childKey)
        result = assignments.findWhere id: itemId
        chosen = result if result?
      chosen

    # Internal: get an item's ID from the ui element
    # Assumes that the first child DOM element will have the id in the data-item-id attribute
    _getItemId: (item) ->
      id = item.children(":first").data('item-id')
      id && String(id)

    # Internal: When an item is moved from one group to another
    # Assumes that the first child DOM element will have the id of the model in the data-item-id attribute
    #
    # e - Event object
    # ui - jQueryUI object
    #
    # Returns nothing.
    _onReceive: (e, ui) =>
      item_id = @_getItemId(ui.item)
      model = @searchItem(item_id)
      @_removeFromGroup(model)
      @_addToGroup(model)

    # must explicitly update @empty attribute from CollectionView class so view
    # will properly recognize if it does/doesn't have items on subsequent
    # re-renders, since drag & drop doesn't trigger a render
    _removeFromGroup: (model) ->
      old_group_id = model.get(@groupKey)
      old_group = @parentCollection.findWhere id: old_group_id
      old_children = old_group.get(@childKey)
      old_children.remove(model, {silent: true})
      @empty = _.isEmpty(old_children.models)

    _addToGroup: (model) ->
      model.set(@groupKey, @groupId)
      new_group = @parentCollection.findWhere id: @groupId
      new_children = new_group.get(@childKey)
      new_children.add(model, {silent: true})
      @empty = false if @empty

    # Internal: On a user's sort action, update the sort order on the server.
    #
    # Assumes that the first child DOM element will have the id of the model in the data-item-id attribute
    #
    # e - Event object.
    # ui - jQueryUI object.
    #
    # Returns nothing.
    _updateSort: (e, ui) =>
      e.stopImmediatePropagation(); #parent sortables won't fire

      # if the ui.item is not still inside the view, we only want to
      # resort, not save
      shouldSave = @$(ui.item).length
      #only save the sorting if this is the group that the item is in (moving to)
      id = @_getItemId(ui.item)
      model = @collection.get(id)
      new_index = ui.item.index()

      models = @updateModels(model, new_index, shouldSave)
      if shouldSave
        model.set 'position', new_index + 1
        @collection.sort()
        @_sendPositions(@collection.pluck('id'))
      else
        # will still have the moved model in the collection for now
        @collection.sort()

    updateModels: (model, new_index, inView) =>
      # start at the model's current position because we don't want to include the model in the slice,
      # we'll update it separately
      old_pos = model.get('position')
      if old_pos
        old_index = old_pos - 1

      movedDown = (old_index < new_index)
      #figure out how to slice the models
      slice_args =
        if !inView
          #model is being removed so we need to update everything
          #after it
          model.unset('position')
          [old_index]
        else if not old_pos
          #model is new so we need to update everything after it
          [new_index]
        else if movedDown
          # moved down so slice from old to new
          # we want to include the one at new index
          # so we add 1
          [old_index, new_index + 1]
        else
          # moved up so slice from new to old
          [new_index, old_index + 1]

      #carve out just the models that need updating
      models_to_update = @collection.slice.apply @collection, slice_args
      #update the position on just these models
      _.each models_to_update, (m) ->
        #if the model gets sliced in here, don't update its
        #position as we'll update it later
        if m.id != model.id
          old = m.get('position')
          #if we moved an item down we want to move
          #the shifted items up (so we subtract 1)
          neue = if !inView or movedDown then old - 1 else old + 1
          m.set 'position', neue


    # Internal: sends an array of model_ids as a comma delimited string
    # to the sortURL
    _sendPositions: (ids) ->
      $.post @reorderURL, order: ids.join(",")

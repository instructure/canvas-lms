define [
  'Backbone'
  'underscore'
  'compiled/views/CollectionView'
], (Backbone, _, CollectionView) ->

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
      handle: '.draggable-handle'
      connectWith: '.draggable.collectionViewItems'
      placeholder: 'draggable-dropzone'
      forcePlaceholderSize: true

    render: (drag=true) ->
      super
      @_initSort() if drag
      @

    attachCollection: ->
      super
      @collection.on 'add', @_noItemsViewIfEmpty

    _initSort: ->
      @$list.sortable(_.extend({}, @sortOptions, scope: @cid))
        .on('sortreceive', @_onReceive)
        .on('sortupdate', @_updateSort)
        .on('sortremove', @_noItemsViewIfEmpty)
        .on('sortover', @_noItemsViewIfEmpty)
      @$list.disableSelection()
      @_noItemsViewIfEmpty()

    # If there are no children within the group,
    # add the view that is used when there are no items in a group
    _noItemsViewIfEmpty: =>
      items = @$list.children()
      if items.length == 0
        @noItems = new Backbone.View
          template: @noItemTemplate
          tagName: "li"
          className: "no-items"
        @noItems.render()
        @$list.append(@noItems.el)
      else
        @noItems.remove() if @noItems

    # Find an item without knowing the group it is in
    searchItem: (itemId) ->
      chosen = null
      @parentCollection.find (group) =>
        assignments = group.get(@childKey)
        result = assignments.find (a) =>
          a.id == itemId
        chosen = result if result?
      chosen

    # Internal: get an item's ID from the ui element
    # Assumes that the first child DOM element will have the id in the data-item-id attribute
    _getItemId: (item) ->
      parseInt item.children(":first").data('item-id')

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

      @_noItemsViewIfEmpty()

    _removeFromGroup: (model) ->
      old_group_id = model.get(@groupKey)
      old_group = @parentCollection.find (g) =>
        g.id == old_group_id
      old_children = old_group.get(@childKey)
      old_children.remove(model, {silent: true})

    _addToGroup: (model) ->
      model.set(@groupKey, @groupId)
      new_group = @parentCollection.find (g) =>
        g.id == @groupId
      new_children = new_group.get(@childKey)
      new_children.add(model, {silent: true})

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
      #only save the sorting if this is the group that the item is in (moving to)
      id = @_getItemId(ui.item)
      sibling = @$list.children().find("[data-item-id=" + id + "]")
      if sibling.length > 0
        positions = {}
        positions[id] = ui.item.index() + 1
        for s in ui.item.siblings()
          $s = $(s)
          if $s.hasClass("no-items")
            $s.remove()
          else
            model_id = @_getItemId($s)

            index = $s.prevAll().length
            new_position = index + 1
            positions[model_id] = new_position
            model = @searchItem(model_id)
            model.set('position', new_position)

        @_sendPositions(@_orderPositions(positions))

    # Internal: takes an object of {model_id:position} and returns an array
    # of model_ids in the correct order
    _orderPositions: (positions) ->
      sortable = []
      for id,order of positions
        sortable.push [id,order]
      sortable.sort (a,b) -> a[1] - b[1]
      output = []
      for model in sortable
        output.push model[0]
      output

    # Internal: sends an array of model_ids as a comma delimited string
    # to the sortURL
    _sendPositions: (ids) ->
      $.post @reorderURL, order: ids.join(",")
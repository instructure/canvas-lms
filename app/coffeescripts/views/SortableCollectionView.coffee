define [
  'Backbone'
  'jquery'
  'underscore'
  'compiled/views/CollectionView'
], (Backbone, $, _, CollectionView) ->

  class SortableCollectionView extends CollectionView

    @optionProperty 'sortURL'

    # Public: Default jQuery sortable options
    sortOptions:
      tolerance: 'pointer'
      opacity: 0.9
      zIndex: 100
      placeholder: 'sortable-dropzone'
      forcePlaceholderSize: true

    render: (sort=true) ->
      super
      @_initSort() if sort
      @

    # Internal: Enable sorting of the this view's itemViews.
    #
    # Returns nothing.
    _initSort: ->
      @$list.sortable(_.extend({}, @sortOptions, scope: @cid))
      @$list.on('sortupdate', @_updateSort)
      @$list.disableSelection()


    # Internal: get an item's ID from the ui element
    # Assumes that the first child DOM element will have the id in the data-item-id attribute
    _getItemId: (item) ->
      item.children(":first").data('id')

    # Internal: On a user's sort action, update the sort order on the server.
    #
    # Assumes that the first child DOM element will have the id of the model in the data-id attribute
    #
    # e - Event object.
    # ui - jQueryUI object.
    #
    # Returns nothing.
    _updateSort: (e, ui) =>
      e.stopPropagation()
      positions = {}
      id = @_getItemId(ui.item)
      positions[id] = ui.item.index() + 1
      for s in ui.item.siblings()
        $s = $(s)
        model_id = @_getItemId($s)

        index = $s.prevAll().length
        positions[model_id] = index + 1

      @_updatePositions(positions)

    # Internal: Update the position attributes of all models in the collection
    # to match their DOM position. Mirror changes to server.
    #
    # Returns nothing.
    _updatePositions: (positions) ->
      @collection.each (model, index) ->
        new_position = positions[model.id]
        model.set('position', new_position)

      # make sure the collection stays in order
      @collection.sort()
      @_sendPositions(@_orderPositions(positions))

    # Internal: takes an object of {model_id:position} and returns and array
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
      $.post @sortURL, order: ids.join(",")

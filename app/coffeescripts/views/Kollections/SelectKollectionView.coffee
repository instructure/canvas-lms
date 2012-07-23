define [
  'Backbone'
  'underscore'
  'jst/Kollections/SelectKollectionView'
], (Backbone, _, SelectKollectionViewTemplate) ->

  class SelectKollectionView extends Backbone.View

    template: SelectKollectionViewTemplate

    events:
      'change [name="collection_id"]' : 'handleChange'

    initialize: ->
      @collection.on 'add change sync reset', @render
      @model.on 'change:kollection', @render
      @render()

    render: =>
      modelsKollection = @model.collection
      @$el.html @template @collection.map (kollection) ->
        cid: kollection.cid
        name: kollection.get('name')
        selected: kollection is modelsKollection

    handleChange: (event) ->
      val = event.target.value

      # ask for new Kollection name and add it and persist it.
      if val is 'new' && newName = prompt('Collection Name')
        selectedKollection = @collection.create name: newName
      else
        selectedKollection = @collection.getByCid(val)
      @model.collection = selectedKollection.kollectionItems
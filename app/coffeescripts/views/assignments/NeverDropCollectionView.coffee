define [
  'underscore'
  'compiled/views/CollectionView'
  'compiled/views/assignments/NeverDropView'
  'jst/assignments/NeverDropCollection'
], (_, CollectionView, NeverDropView, template) ->

  class NeverDropCollectionView extends CollectionView
    itemView: NeverDropView

    template: template

    events:
      'click .add_never_drop': 'addNeverDrop'

    initialize: ->
      # feed all events that should trigger a render
      # through a custom event so that we only render
      # once per batch of changes
      @on 'should-render', _.debounce(@render, 100)
      super

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
        hasAssignments: @collection.availableValues.length > 0
        hasNeverDrops: @collection.takenValues.length > 0

    triggerRender: (model, collection, options)=>
      @trigger 'should-render'

    # add a new select, and mark it for focusing
    # when we re-render the collection
    addNeverDrop: (e) ->
      e.preventDefault()
      model =
        label_id: @collection.ag_id
        focus: true
      @collection.add model

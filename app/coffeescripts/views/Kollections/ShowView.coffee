define [
  'Backbone'
  'compiled/models/Kollection'
  'compiled/views/KollectionItems/ShowView'
  'jst/Kollections/ShowView'
], (Backbone, Kollection, KollectionItemShowView, template) ->

  class KollectionShowView extends Backbone.View

    template: template

    el: '#collectionsApp'

    events:
      # TODO abstract handleClick
      'click [data-event]' : 'handleClick'

    initialize: ->
      @model.on 'change', @render
      @model.kollectionItems.on 'reset', @renderCollectionItems
      @model.fetch()
      @model.kollectionItems.fetch()

    render: =>
      super
      @renderCollectionItems()
      this

    renderCollectionItems: =>
      $holder = @$('.kollectionItemsHolder').empty()
      @model.kollectionItems.each (kollectionItem) ->
        view = new KollectionItemShowView(model: kollectionItem)
        $holder.append view.render().el

    # TODO abstract handleClick
    handleClick: (event) =>
      event.preventDefault()
      event.stopPropagation()
      method = $(event.currentTarget).data 'event'
      @[method]?(arguments...)

    createNewItem: ->
      alert 'TODO: pop up a modal to create a new item in this collection'
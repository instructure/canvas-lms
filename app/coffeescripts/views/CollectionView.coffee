define [
  'Backbone'
  'jst/collectionView'
], (Backbone, template) ->

  ##
  # Renders a collection of items with an item view. Binds to a handful of
  # collection events to keep itself up-to-date
  #
  # Example:
  #
  #   peopleCollection = new PeopleCollection
  #   view = new CollectionView
  #     itemView: PersonView
  #     collection: peopleCollection
  #   peopleCollection.add(someThing)
  #   peopleCollection.fetch()
  #   # etc.
  #
  class CollectionView extends Backbone.View

    ##
    # The backbone view rendered for collection items
    @optionProperty 'itemView'

    className: 'collectionView'

    els:
      '.collectionViewItems': '$list'

    ##
    # When using a different template ensure it contains an element with a
    # class of `.collectionViewItems`
    template: template

    ##
    # @api public
    initialize: ->
      super
      @attachCollection()

    ##
    # @api public
    render: =>
      super
      @renderItems() if @collection.length

    ##
    # @api public
    toJSON: -> @options

    ##
    # Attaches all the collection events
    # @api private
    attachCollection: ->
      @collection.on 'reset', @removePreviousItems
      @collection.on 'reset', @render
      @collection.on 'add', @rerenderIfCollection
      @collection.on 'add', @renderItem
      @collection.on 'remove', @removeItem
      @collection.on 'remove', @rerenderUnlessCollection

    ##
    # Ensures item views are removed properly, when we upgrade backbone we can
    # use options.previousModels instead of the DOM.
    # @api private
    removePreviousItems: (models) =>
      @$list.children().each (index, el) =>
        @$(el).data('view').remove()

    ##
    # Renders all collection items
    # @api private
    renderItems: ->
      @collection.each @renderItem

    ##
    # Removes an item
    # @api private
    removeItem: (model) =>
      model.view.remove()

    ##
    # Ensures main template is rerendered when the first item is added
    # @api private
    rerenderIfCollection: =>
      @render() if @collection.length is 1

    ##
    # Ensures the template rerenders when there is no collection
    # @api private
    rerenderUnlessCollection: =>
      @render() unless @collection.length

    ##
    # Renders an item with the `itemView`
    # @api private
    renderItem: (model) =>
      view = new @itemView {model}
      view.render()
      @insertView view

    ##
    # Inserts the item view with respect to the collection comparator.
    # @api private
    insertView: (view) ->
      index = @collection.indexOf view.model
      if index is 0
        @$list.prepend view.el
      else if index is @collection.length - 1
        @$list.append view.el
      else
        @$list.children().eq(index).before view.el


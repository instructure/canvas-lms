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
  #   peopleCollection.add name: 'ryanf', id: 1
  #   peopleCollection.fetch()
  #   # etc.

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
    # Options:
    #
    #  - `itemView` {Backbone.View}
    #  - `collection` {Backbone.Collection}
    #
    # @param {Object} options
    # @api public

    initialize: (options) ->
      super
      @attachCollection()

    ##
    # Renders the main template and the item templates
    #
    # @api public

    render: =>
      super
      @renderItems() if @collection.length
      this

    ##
    # @api public
    toJSON: -> @options

    ##
    # Attaches all the collection events
    #
    # @api private

    attachCollection: ->
      @collection.on 'reset', @renderOnReset
      @collection.on 'add', @renderOnAdd
      @collection.on 'remove', @removeItem
      @collection.on 'remove', @rerenderUnlessCollection

    ##
    # Ensures item views are removed properly, when we upgrade backbone we can
    # use options.previousModels instead of the DOM.
    #
    # @param {Array} models - array of Backbone.Models
    # @api private

    removePreviousItems: (models) =>
      @$list.children().each (index, el) =>
        @$(el).data('view').remove()

    renderOnReset: =>
      @removePreviousItems()
      @render()

    ##
    # Renders all collection items
    #
    # @api private

    renderItems: ->
      @collection.each @renderItem

    ##
    # Removes an item
    #
    # @param {Backbone.Model} model
    # @api private

    removeItem: (model) =>
      model.view.remove()

    ##
    # Ensures main template is rerendered when the first item is added
    #
    # @param {Backbone.Model} model
    # @api private

    renderOnAdd: (model) =>
      if @collection.length is 1
        @render()
      else
        @renderItem model

    ##
    # Ensures the template rerenders when there is no collection
    #
    # @api private

    rerenderUnlessCollection: =>
      @render() unless @collection.length

    ##
    # Renders an item with the `itemView`
    #
    # @param {Backbone.Model} model
    # @api private

    renderItem: (model) =>
      view = new @itemView {model}
      view.render()
      @insertView view

    ##
    # Inserts the item view with respect to the collection comparator.
    #
    # @param {Backbone.View} view
    # @api private

    insertView: (view) ->
      index = @collection.indexOf view.model
      if index is 0
        @prependView view
      else if index is @collection.length - 1
        @appendView view
      else
        @insertViewAtIndex view, index

    insertViewAtIndex: (view, index) ->
      $sibling = @$list.children().eq(index)
      if $sibling.length
        $sibling.before view.el
      else
        @$list.append view.el

    prependView: (view) ->
      @$list.prepend view.el

    appendView: (view) ->
      @$list.append view.el

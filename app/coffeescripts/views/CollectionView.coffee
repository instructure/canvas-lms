define [
  'jquery'
  'Backbone'
  'jst/collectionView'
], ($, Backbone, template) ->

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

    @optionProperty 'itemViewOptions'

    className: 'collectionView'

    els:
      '.collectionViewItems': '$list'

    defaults:
      itemViewOptions: {}

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
      @renderItems() unless @empty
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
      @empty = not @collection.length

    ##
    # Ensures item views are removed properly
    #
    # @param {Array} models - array of Backbone.Models
    # @api private

    removePreviousItems: (models) =>
      for model in models
        model.view?.remove()

    renderOnReset: (models, options) =>
      @empty = not @collection.length
      @removePreviousItems options.previousModels
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
      @empty = not @collection.length
      if @empty
        @render()
      else
        model.view.remove()

    ##
    # Ensures main template is rerendered when the first items are added
    #
    # @param {Backbone.Model} model
    # @api private

    renderOnAdd: (model) =>
      @render() if @empty
      @empty = false
      @renderItem(model)

    ##
    # Renders an item with the `itemView`
    #
    # @param {Backbone.Model} model
    # @api private

    renderItem: (model) =>
      view = @createItemView model
      view.render()
      @attachItemView?(model, view)
      @insertView view

    ##
    # Creates the item view instance, extend this when you need to do things
    # like instantiate with child views, etc.

    createItemView: (model) ->
      new @itemView $.extend {}, (@itemViewOptions || {}), {model}

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

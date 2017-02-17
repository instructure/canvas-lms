define [
  'jquery'
  'node_modules-version-of-backbone'
  'underscore'
  'str/htmlEscape'
  'compiled/util/mixin'
], ($, Backbone, _, htmlEscape, mixin) ->

  ##
  # Extends Backbone.View on top of itself to be 100X more useful
  class Backbone.View extends Backbone.View

    ##
    # Define default options, options passed in to the view will overwrite these
    #
    # @api public

    defaults: {}

    ##
    # Configures elements to cache after render. Keys are css selector strings,
    # values are the name of the property to store on the instance.
    #
    # Example:
    #
    #   class FooView extends Backbone.View
    #     els:
    #       '.toolbar': '$toolbar'
    #       '#main': '$main'
    #
    # @api public

    els: null

    ##
    # Defines a key on the options object to be added as an instance property
    # like `model`, `collection`, `el`, etc.
    #
    # Example:
    #   class SomeView extends Backbone.View
    #     @optionProperty 'foo'
    #   view = new SomeView foo: 'bar'
    #   view.foo #=> 'bar'
    #
    #  @param {String} property
    #  @api public

    @optionProperty: (property) ->
      @__optionProperties__ = (@__optionProperties__ or []).concat [property]

    ##
    # Avoids subclasses that simply add a new template

    @optionProperty 'template'

    ##
    # Defines a child view that is automatically rendered with the parent view.
    # When creating an instance of the parent view the child view is passed in
    # as an `optionProperty` on the key `name` and its element will be set to
    # the first match of `selector` in the parent view's template.
    #
    # Example:
    #   class SearchView
    #     @child 'inputFilterView', '.filter'
    #     @child 'collectionView', '.results'
    #
    #   view = new SearchView
    #     inputFilterView: new InputFilterView
    #     collectionView: new CollectionView
    #   view.inputFilterView? #=> true
    #   view.collectionView? #=> true
    #
    # @param {String} name
    # @param {String} selector
    # @api public

    @child: (name, selector) ->
      @optionProperty name
      @__childViews__ ?= []
      @__childViews__ = @__childViews__.concat [{name, selector}]

    ##
    # Initializes the view.
    #
    # - Stores the view in the element data as 'view'
    # - Sets @model.view and @collection.view to itself
    #
    # @param {Object} options
    # @api public

    initialize: (options) ->
      @options = _.extend {}, @defaults, options
      @setOptionProperties()
      @storeChildrenViews()
      @$el.data 'view', this
      @_setViewProperties()
      # magic from mixin
      fn.call this for fn in @__initialize__ if @__initialize__
      @attach()
      this

    # Store all children views for easy access.
    #   ie:
    #      @view.children # {@view1, @view2}
    #
    # @api private

    storeChildrenViews: ->
      return unless @constructor.__childViews__
      @children = _.map @constructor.__childViews__, (viewObj) => @[viewObj.name]

    ##
    # Sets the option properties
    #
    # @api private

    setOptionProperties: ->
      for property in @constructor.__optionProperties__
        @[property] = @options[property] if @options[property] isnt undefined


    ##
    # Renders the view, calls render hooks
    #
    # @api public

    render: =>
      @renderEl()
      @_afterRender()
      this

    ##
    # Renders the HTML for the element
    #
    # @api public

    renderEl: ->
      @$el.html @template(@toJSON()) if @template

    ##
    # Caches elements from `els` config
    #
    # @api private

    cacheEls: ->
      @[name] = @$(selector) for selector, name of @els if @els

    ##
    # Internal afterRender
    #
    # @api private

    _afterRender: ->
      @cacheEls()
      @createBindings()
      # TODO: remove this when `options.views` is removed
      @renderViews() if @options.views
      # renderChildViews must come after cacheEls so we don't cache all the
      # child views elements, bind them to model data, etc.
      @renderChildViews()
      @afterRender()

    ##
    # Define in subclasses to add behavior to your view, ie. creating
    # datepickers, dialogs, etc.
    #
    # Example:
    #
    #   class SomeView extends Backbone.View
    #     els: '.dialog': '$dialog'
    #     afterRender: ->
    #       @$dialog.dialog()
    #
    # @api private

    afterRender: ->
      # magic from `mixin`
      fn.call this for fn in @__afterRender__ if @__afterRender__

    ##
    # Define in subclasses to attach your collection/model events
    #
    # Example:
    #
    #   class SomeView extends Backbone.View
    #     attach: ->
    #       @model.on 'change', @render
    #
    # @api public

    attach: ->
      # magic from `mixin`
      fn.call this for fn in @__attach__ if @__attach__

    ##
    # Defines the locals for the template with intelligent defaults.
    #
    # Order of defaults, highest priority first:
    #
    # 1. `@model.present()`
    # 2. `@model.toJSON()`
    # 3. `@collection.present()`
    # 4. `@collection.toJSON()`
    # 5. `@options`
    #
    # Using `present` is encouraged so that when a model or collection is saved
    # to the app it doesn't send along non-persistent attributes.
    #
    # Also adds the view's `cid`.
    #
    # @api public

    toJSON: ->
      model = @model or @collection
      json = if model
        if model.present
          model.present()
        else
          model.toJSON()
      else
        @options
      json.cid = @cid
      json.ENV = window.ENV if window.ENV?
      json

    ##
    # Finds, renders, and assigns all child views defined with `View.child`.
    #
    # @api private

    renderChildViews: ->
      return unless @constructor.__childViews__
      for {name, selector} in @constructor.__childViews__
        console?.warn?("I need a child view '#{name}' but one was not provided") unless @[name]?
        continue unless @[name] # don't blow up if the view isn't present (or it's explicitly set to false)
        target = @$ selector
        @[name].setElement target
        @[name].render()
      null

    ##
    # Binds a `@model` data to the element's html. Whenever the data changes
    # the view is updated automatically. The value will be html-escaped by
    # default, but the view can define a format method to specify other
    # formatting behavior with `@format`.
    #
    # Example:
    #
    #   <div data-bind="foo">{I will always mirror @model.get('foo') in here}</div>
    #
    # @api private

    ###
    xsslint safeString.method format
    ###

    createBindings: (index, el) =>
      @$('[data-bind]').each (index, el) =>
        $el = $ el
        attribute = $el.data 'bind'
        @model.on "change:#{attribute}", (model, value) =>
          $el.html @format attribute, value

    ##
    # Formats bound attributes values before inserting into the element when
    # using `data-bind` in the template.
    #
    # @param {String} attribute
    # @param {String} value
    # @api private

    format: (attribute, value) ->
      htmlEscape value

    ##
    # Use in cases where normal links occur inside elements with events.
    #
    # Example:
    #
    #   class RecentItemsView
    #     events:
    #       'click .header': 'expand'
    #       'click .header a': 'stopPropagation'
    #
    # @param {$Event} event
    # @api public

    stopPropagation: (event) ->
      event.stopPropagation()

    ##
    # Mixes in objects to a view's definition, being mindful of certain
    # properties (like events) that need to be merged also.
    #
    # @param {Object} mixins...
    # @api public

    @mixin: (mixins...) ->
      mixin this, mixins...

    ##
    # DEPRECATED - don't use views option, use `child` constructor method
    renderViews: ->
      _.each @options.views, @renderView

    ##
    # DEPRECATED
    renderView: (view, selector) =>
      target = @$("##{selector}")
      target = @$(".#{selector}") unless target.length
      view.setElement target
      view.render()
      @[selector] ?= view

    hide: -> @$el.hide()
    show: -> @$el.show()
    toggle: -> @$el.toggle()

    # Set view property for attached model/collection objects. If
    # @setViewProperties is set to false, view properties will
    # not be set.
    #
    # Example:
    #   class SampleView extends Backbone.View
    #     setViewProperties: false
    #
    # @api private
    _setViewProperties: ->
      return if @setViewProperties == false
      @model.view = this if @model
      @collection.view = this if @collection
      return

  Backbone.View


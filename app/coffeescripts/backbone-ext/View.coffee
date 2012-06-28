define [
  'use!vendor/backbone'
  'underscore'
], (Backbone, _) ->

  ##
  # Extends Backbone.View on top of itself with some added features
  # we use regularly
  class Backbone.View extends Backbone.View

    ##
    # Manages child views and renders them whenever the parent view is rendered.
    # Specify views as key:value pairs of `className: view` where `className` is
    # a CSS className to find the element in which to to append a rendered
    # `view.el`
    #
    # Be sure to call `super` in the parent view's `render` method _after_ the
    # html has been set.
    views: false
      # example: new ExampleView

    ##
    # Extends render to add support for chid views and element filtering
    render: (opts = {}) =>
      @$el.html @template(@toJSON()) if @template

      # cacheEls before filter so we have access to elements in filter
      @cacheEls() if @els
      @filter() unless opts.noFilter is true

      # its important for renderViews to come last so we don't filter
      # and cache all the child views elements
      @renderViews() if @options.views
      this

    ##
    # Caches elements from `els` config
    #
    #   class Foo extends View
    #     els:
    #       '.someSelector': '$somePropertyName'
    #
    # After render is called, the `@$somePropertyName` is now available
    # with the element found in `.someSelector`
    cacheEls: ->
      @[name] = @$(selector) for selector, name of @els if @els

    ##
    # Filters elements to add behavior and bindings. Can be called automatically
    # in `render`, so be careful not to call it twice
    #
    # @api public
    filter: ->
      @$('[data-bind]').each => @createBinding.apply this, arguments
      #@$('[data-behavior]').each => @_createBehavior.apply this, arguments

    ##
    # in charge of getting variables ready to pass to handlebars during render
    # override with your own logic to do something fancy.
    toJSON: ->
      (@model ? @collection)?.toJSON arguments...

    ##
    # Renders all child views
    #
    # @api private
    renderViews: ->
      _.each @options.views, @renderView

    ##
    # Renders a single child view and appends its designated element
    #
    # @api private
    renderView: (view, className) =>
      target = @$('.' + className).first()
      view.setElement target
      view.render()
      @[className] ?= view

    ##
    # Binds a `@model` data to the element's html. Whenever the data changes
    # the view is updated automatically.
    #
    # ex:
    #   <div data-bind="foo">{I will always mirror @model.get('foo') in here}</div>
    #
    # @api public
    createBinding: (index, el) ->
      $el = $ el
      attribute = $el.data 'bind'
      @model.on "change:#{attribute}", (model, value) =>
        $el.html value

    #_createBehavior: (index, el) ->
      # not using this yet

    ##
    # Mixes in objects to a view's definition, being mindful of certain
    # properties (like events) that need to be merged also
    #
    # @param {Object} mixins...
    # @api public
    @mixin: (mixins...) ->
      for mixin in mixins
        for key, prop of mixin
          # don't blow away old events, merge them
          if key is 'events'
            _.extend @::[key], prop
          else
            @::[key] = prop
      this # return this to avoid collecting implicit returned array

  Backbone.View


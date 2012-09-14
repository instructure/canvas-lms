define [
  'use!vendor/backbone'
  'underscore'
  'str/htmlEscape'
], (Backbone, _, h) ->

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
    # Define default options, options passed in to the view will overwrite these
    defaults: {}

    initialize: (options) ->
      @options = _.extend {}, @defaults, @options, options
      super

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
    # Add behavior and bindings to elements. Can be called automatically in
    # `render`, so be careful not to call it twice
    #
    # @api public
    afterRender: ->
      @$('[data-bind]').each @createBinding
      #@$('[data-behavior]').each => @_createBehavior.apply this, arguments

    ##
    # backwards compat for old afterRender name
    filter: @::afterRender

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
    # The value will be html-escaped by default, but the view can define a
    # format method to specify other formatting behavior
    #
    # ex:
    #   <div data-bind="foo">{I will always mirror @model.get('foo') in here}</div>
    #
    # @api public
    createBinding: (index, el) =>
      $el = $ el
      attribute = $el.data 'bind'
      @model.on "change:#{attribute}", (model, value) =>
        $el.html @format?(attribute, value) ? h(value)

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


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
    defaults:

      # can hand a view a template option to avoid subclasses that only add a
      # different template
      template: null

    initialize: (options) ->
      @options = _.extend {}, @defaults, @options, options
      @setTemplate()
      @$el.data 'view', this
      this

    setTemplate: ->
      @template = @options.template if @options.template

    ##
    # Extends render to add support for chid views and element filtering
    render: (opts = {}) =>
      @renderEl()
      @_afterRender()
      this

    renderEl: ->
      @$el.html @template(@toJSON()) if @template

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
    # Internal afterRender
    # @api private
    _afterRender: ->
      @cacheEls() if @els
      @$('[data-bind]').each @createBinding
      @afterRender()
      # its important for renderViews to come last so we don't filter
      # and cache all the child views elements
      @renderViews() if @options.views

    ##
    # Add behavior and bindings to elements.
    afterRender: ->

    ##
    # in charge of getting variables ready to pass to handlebars during render
    # override with your own logic to do something fancy.
    toJSON: ->
      json = ((@model ? @collection)?.toJSON arguments...) || {}
      json.cid = @cid
      json

    ##
    # Renders all child views
    #
    # @api private
    renderViews: ->
      _.each @options.views, @renderView

    ##
    # Renders a single child view and appends its designated element
    # Use ids in your view, not classes. This 
    #
    # @api private
    renderView: (view, selector) =>
      target = @$("##{selector}")
      target = @$(".#{selector}") unless target.length
      view.setElement target
      view.render()
      @[selector] ?= view

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
    # Use in cases where normal links occur inside elements with events
    #   events:
    #     'click .something': 'doStuff'
    #     'click .something a': 'stopPropagation'
    stopPropagation: (event) ->
      event.stopPropagation()

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


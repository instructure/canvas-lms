define [
  'compiled/util/mixin'
  'underscore'
  'vendor/backbone'
  'compiled/backbone-ext/Model/computedAttributes'
  'compiled/backbone-ext/Model/dateAttributes'
  'compiled/backbone-ext/Model/errors'
], (mixin, _, Backbone) ->

  class Backbone.Model extends Backbone.Model

    ##
    # Mixes in objects to a model's definition, being mindful of certain
    # properties (like defaults) that need to be merged also.
    #
    # @param {Object} mixins...
    # @api public

    @mixin: (mixins...) ->
      mixin this, mixins...

    initialize: (attributes, options) ->
      super
      @options = _.extend {}, @defaults, options
      fn.call this for fn in @__initialize__ if @__initialize__
      this

    # Method Summary
    #   Trigger an event indicating an item has started to save. This 
    #   can be used to add a loading icon or trigger another event 
    #   when an model tries to save itself. 
    #
    #   For example, inside of the initializer of the model you want
    #   to show a loading icon you could do something like this
    #
    #   @model.on 'saving', -> console.log "Do something awesome"
    #
    # @api backbone override
    save: ->
      @trigger "saving"
      super

    # Method Summary
    #   Trigger an event indicating an item has started to delete. This
    #   can be used to add a loading icon or trigger an event while the
    #   model is being deleted. 
    #
    #   For example, inside of the initializer of the model you want to 
    #   show a loading icon, you could do something like this. 
    #
    #   @model.on 'destroying', -> console.log 'Do something awesome'
    #
    # @api backbone override
    destroy: ->
      @trigger "destroying"
      super

    ##
    # Increment an attribute by 1 (or the specified amount)
    increment: (key, delta = 1) ->
      @set key, @get(key) + delta

    ##
    # Decrement an attribute by 1 (or the specified amount)
    decrement: (key, delta = 1) ->
      @increment key, -delta

    # Add support for nested attributes on a backbone model. Nested
    # attributes are indicated by a . to seperate each level. You get
    # get nested attributes by doing the following.
    # ie: 
    #   // given {foo: {bar: 'catz'}} 
    #   @get 'foo.bar' // returns catz
    #
    # @api backbone override
    deepGet: (property) ->
      split = property.split "."
      value = @get split.shift()

      # Move through objects until found
      while next = split.shift()
        value = value[next]

      value

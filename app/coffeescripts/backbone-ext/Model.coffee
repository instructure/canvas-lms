define [
  'underscore'
  'use!vendor/backbone'
  'compiled/backbone-ext/Model/computedAttributes'
  'compiled/backbone-ext/Model/dateAttributes'
  'compiled/backbone-ext/Model/errors'
], (_, Backbone) ->

  class Backbone.Model extends Backbone.Model

    ##
    # Define default options, options passed in to the constructor will
    # overwrite these
    defaults: {}

    initialize: (attributes, options) ->
      super
      @options = _.extend {}, @defaults, options

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



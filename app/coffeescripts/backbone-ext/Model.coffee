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



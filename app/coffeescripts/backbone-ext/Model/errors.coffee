define ['underscore', 'use!vendor/backbone'], (_, Backbone) ->

  _.extend Backbone.Model.prototype,

    # normalize (i.e. I18n) and filter errors we get from the API
    normalizeErrors: (errors) ->
      result = {}
      errorMap = @errorMap ? @constructor::errorMap ? {}
      if errors
        for attr, attrErrors of errors when errorMap[attr]
          for error in attrErrors when errorMap[attr][error.type]
            result[attr] ?= []
            result[attr].push errorMap[attr][error.type]
      result

  Backbone.Model


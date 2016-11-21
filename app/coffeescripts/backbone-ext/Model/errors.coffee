define ['underscore', 'node_modules-version-of-backbone'], (_, Backbone) ->

  _.extend Backbone.Model.prototype,

    # normalize (i.e. I18n) and filter errors we get from the API
    normalizeErrors: (errors, validationPolicy) ->
      result = {}
      errorMap = @errorMap ? @constructor::errorMap ? {}
      errorMap = errorMap(validationPolicy) if _.isFunction(errorMap)
      if errors
        for attr, attrErrors of errors when errorMap[attr]
          for error in attrErrors when errorMap[attr][error.type]
            result[attr] ?= []
            result[attr].push errorMap[attr][error.type]
      result

  Backbone.Model


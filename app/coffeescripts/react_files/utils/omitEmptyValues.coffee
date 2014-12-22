define ['underscore'], (_) ->
  omitEmptyValues = (obj) ->
    object = _.clone(obj)
    delete object[key] for key of object when not object[key]?
    object
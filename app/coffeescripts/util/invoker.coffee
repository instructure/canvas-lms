define ->
  (obj) ->
    obj.invoke = (method) ->
      args = [].splice.call arguments, 0, 1
      (@[method] or @.noMethod).apply this, arguments

    unless obj.noMethod
      obj.noMethod = ->

    obj


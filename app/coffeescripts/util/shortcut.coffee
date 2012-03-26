# like rails' delegate, but named shortcut to avoid confusion with $.delegate
define ->
  (Delegator, receiver, methods...) ->
    for method in methods
      do (method) ->
        Delegator::[method] = ->
          @[receiver][method].apply @[receiver], arguments
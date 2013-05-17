# usage
# $(element).click preventDefault (event) ->
#   #do stuff with the event

define ->
  preventDefault = (fn) ->
    (event) ->
      event?.preventDefault()
      fn.apply(this, arguments)
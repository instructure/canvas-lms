define ['require'], (require) ->

  init: ->
    return unless ENV.TOURS
    for tour in ENV.TOURS
      require ["compiled/views/tours/#{tour}"], (tour) ->
        new tour()


define ['require'], (require) ->

  init: ->
    return unless ENV.TOURS
    for tourName in ENV.TOURS
      require ["compiled/views/tours/#{tourName}"], (tour) ->
        new tour name: tourName


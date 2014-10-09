define (require) ->
  EventTracker = require('../event_tracker')
  K = require('../constants')

  class PageBlurred extends EventTracker
    eventType: K.EVT_PAGE_BLURRED

    install: (deliver) ->
      @bind window, 'blur', ->
        deliver()
      , throttle: 5000

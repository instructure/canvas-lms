define (require) ->
  EventTracker = require('../event_tracker')
  K = require('../constants')

  class PageFocused extends EventTracker
    eventType: K.EVT_PAGE_FOCUSED

    install: (deliver) ->
      @bind window, 'focus', ->
        deliver()
      , throttle: 5000
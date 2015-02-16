define (require) ->
  EventTracker = require('../event_tracker')
  K = require('../constants')
  debugConsole = require('compiled/util/debugConsole')

  class SessionStarted extends EventTracker
    eventType: K.EVT_SESSION_STARTED
    options: {
    }

    install: (deliver) ->
      userAgent = navigator.userAgent
      debugConsole.log """
        I've been loaded by #{userAgent}.
        """
      if location.href.indexOf("question") == -1 && location.href.indexOf("take") > 0
        deliver({
            'user_agent': userAgent
          })
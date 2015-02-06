define (require) ->
  eventManager = require('compiled/quizzes/log_auditing')
  (unregister) ->
    if unregister
      eventManager.unregisterAllTrackers()
    if !eventManager.isRunning()
      eventManager.start()
    if eventManager.isDirty()
      eventManager.deliver()
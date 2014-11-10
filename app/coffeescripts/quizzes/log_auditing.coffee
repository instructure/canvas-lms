define (require) ->
  K = require('./log_auditing/constants')
  EventManager = require('./log_auditing/event_manager')
  EventBuffer = require('./log_auditing/event_buffer')
  EventTracker = require('./log_auditing/event_tracker')
  hasLocalStorage = require('compiled/util/hasLocalStorage')
  debugConsole = require('compiled/util/debugConsole')

  # ---------------------------
  # Trackers.
  # ---------------------------
  trackers = []
  trackers.push require('./log_auditing/event_trackers/page_focused')
  trackers.push require('./log_auditing/event_trackers/page_blurred')
  trackers.push require('./log_auditing/event_trackers/question_viewed')
  trackers.push require('./log_auditing/event_trackers/question_flagged')

  eventManager = new EventManager()

  # Register all event trackers
  trackers.forEach (factory) ->
    eventManager.registerTracker(factory)

  # Configure the EventBuffer to use localStorage if it's available:
  if hasLocalStorage
    debugConsole.debug('QuizLogAuditing: will be using localStorage.')
    EventBuffer.setStorageAdapter(K.EVT_STORAGE_LOCAL_STORAGE)

  eventManager.options.deliveryUrl = ENV.QUIZ_SUBMISSION_EVENTS_URL

  eventManager
define [
  'ember'
  'jquery'
], (Ember,$) ->
  $(document.body).addClass 'context_modules2'

  # Ember.LOG_BINDING = true
  # Ember.ENV.RAISE_ON_DEPRECATION = true
  # Ember.LOG_STACKTRACE_ON_DEPRECATION = true

  Ember.Application.extend
    rootElement: '#content'
    # LOG_TRANSITIONS: true
    # LOG_TRANSITIONS_INTERNAL: true
    # LOG_VIEW_LOOKUPS: true
    # LOG_ACTIVE_GENERATION: true

define ['../main'], (Application) ->
  karmaLoaded = window.__karma__
  Ember.LOG_VERSION = !karmaLoaded
  startApp = ->
    App = null
    Ember.run.join ->
      App = Application.create
        LOG_ACTIVE_GENERATION: !karmaLoaded
        LOG_MODULE_RESOLVER: !karmaLoaded
        LOG_TRANSITIONS: !karmaLoaded
        LOG_TRANSITIONS_INTERNAL: !karmaLoaded
        LOG_VIEW_LOOKUPS: !karmaLoaded
        rootElement: '#fixtures'
        history: 'none'
      App.Router.reopen history: 'none'
      App.setupForTesting()
      App.injectTestHelpers()
    window.App = App
    App

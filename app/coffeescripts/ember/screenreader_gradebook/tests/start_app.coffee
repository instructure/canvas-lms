define ['../main'], (Application) ->
  startApp = () ->
    App = null
    Ember.run.join ->
      App = Application.create
        LOG_ACTIVE_GENERATION: yes
        LOG_MODULE_RESOLVER: yes
        LOG_TRANSITIONS: yes
        LOG_TRANSITIONS_INTERNAL: yes
        LOG_VIEW_LOOKUPS: yes
        rootElement: '#fixtures'
      App.Router.reopen history: 'none'
      App.setupForTesting()
      App.injectTestHelpers()
    window.App = App
    App



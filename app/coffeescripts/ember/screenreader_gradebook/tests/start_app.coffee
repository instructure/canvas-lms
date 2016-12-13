define ['../main', 'ember'], (Application, Ember) ->
  startApp = () ->
    App = null
    Ember.run.join ->
      App = Application.create
        rootElement: '#fixtures'
      App.Router.reopen history: 'none'
      App.setupForTesting()
      App.injectTestHelpers()
    window.App = App
    App

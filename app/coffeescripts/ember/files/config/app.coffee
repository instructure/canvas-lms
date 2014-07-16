define ['ember'], (Ember) ->

  rootURL = '/courses/1/files'

  App = Ember.Application.extend
    rootElement: '#content'
    LOG_TRANSITIONS: true
    LOG_TRANSITIONS_INTERNAL: true
    Router: Ember.Router.extend
      location: 'history'
      rootURL: rootURL

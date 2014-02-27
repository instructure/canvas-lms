define [
  'ember'
  '../shared/environment'
  '../../shared/components/ic_actions_component'
  '../../shared/components/ic_publish_icon_component'
  './date_transform'
], (Ember, env) ->

  env.setEnv(window.ENV)

  Ember.$.ajaxPrefilter (options, originalOptions, xhr) ->
    options.dataType = 'json'
    options.headers = 'Accept': 'application/vnd.api+json'

  Ember.Application.extend

    rootElement: '#content'

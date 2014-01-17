define [
  'ember',
  '../../shared/components/ic_actions_component'
  '../../shared/components/ic_publish_icon_component'
], (Ember) ->

  Ember.$.ajaxPrefilter (options, originalOptions, xhr) ->
    options.dataType = 'json'
    options.headers = 'Accept': 'application/vnd.api+json'

  Ember.Application.extend

    rootElement: '#content'

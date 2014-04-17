define [
  'ember'
  '../shared/environment'
  '../shared/util'
  '../../shared/components/ic_actions_component'
  '../../shared/components/ic_publish_icon_component'
  './date_transform'
], (Ember, env, Util) ->
  Ember.Util = Util
  Ember.onLoad 'Ember.Application', (Application) ->
    Application.initializer
      name: 'env'
      initialize: (container, application) ->
        env.setEnv(window.ENV)

  Ember.Inflector.inflector.irregular('quizStatistics', 'quizStatistics')
  Ember.Inflector.inflector.irregular('questionStatistics', 'questionStatistics')
  Ember.Inflector.inflector.irregular('progress', 'progress')
  Ember.Inflector.inflector.irregular('summaryStatistics', 'summaryStatistics')

  Ember.$.ajaxPrefilter 'json', (options, originalOptions, xhr) ->
    options.dataType = 'json'
    options.headers = 'Accept': 'application/vnd.api+json'

  Ember.Application.extend

    rootElement: '#content'

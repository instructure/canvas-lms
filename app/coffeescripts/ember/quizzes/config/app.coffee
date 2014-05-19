define [
  'ember'
  '../shared/environment'
  '../shared/util'
  '../../screenreader_gradebook/components/fast_select_component'
  '../../shared/components/ic_actions_component'
  '../../shared/components/ic_publish_icon_component'
  './date_transform'
], (Ember, env, Util, FastSelectComponent, ConfirmDialogComponent, FormDialogComponent) ->
  Ember.Util = Util

  Ember.onLoad 'Ember.Application', (Application) ->
    Application.initializer
      name: 'SharedComponents'
      initialize: (container, application) ->
        container.register 'component:fast-select', FastSelectComponent
    Application.initializer
      name: 'environment'
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

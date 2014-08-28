define [
  'ember',
  'i18n!quiz_overview_route',
  '../shared/title_builder'
], (Em, I18n, titleBuilder) ->

  Em.Route.extend
    model: ->
      @modelFor 'quiz'

    afterModel: (quiz, transition) ->
      title = quiz.get('title')
      desc = I18n.t('overview', 'Overview')
      titleBuilder([title, desc])

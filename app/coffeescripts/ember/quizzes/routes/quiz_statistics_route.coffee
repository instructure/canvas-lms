define [
  'ember',
  '../mixins/redirect',
  'i18n!quiz_statistics_route'
  '../shared/title_builder'
  '../mixins/routes/loading_overlay'
], (Ember, Redirect, I18n, titleBuilder, LoadingOverlayMixin) ->
  {RSVP} = Ember
  RC_QUIZ_TOO_LARGE = /operation not available for large quizzes/

  Ember.Route.extend Redirect, LoadingOverlayMixin,
    beforeModel: (transition) ->
      @set 'error', null
      @validateRoute('canManage', 'quiz.show')

    model: (transition, options) ->
      quiz = @modelFor('quiz')
      quiz.get('quizStatistics').then((items)->
        # use the latest statistics report available:
        items.sortBy('createdAt').get('lastObject')
      ).then((latestStatistics)->
        # load the reports, we need these to be able to generate if requested
        quiz.get('quizReports').then ->
          latestStatistics
      ).catch (error) =>
        jqXHR = (error || {}).jqXHR

        if jqXHR && jqXHR.status && jqXHR.responseText.match(RC_QUIZ_TOO_LARGE)
          @set 'error', 'stats_too_large'
        else
          @set 'error', 'unknown'

        RSVP.resolve([])

    afterModel: () ->
      title = @modelFor('quiz').get('title')
      desc = I18n.t('quiz_statistics', "Statistics")
      titleBuilder([title, desc])

    actions:
      showDiscriminationIndexHelp: ->
        @render 'quiz/statistics/questions/multiple_choice/discrimination_index_help',
          into: 'application'
          outlet: 'modal'

      didTransition: ->
        if error = @get('error')
          @controllerFor('quizStatistics').set('error', error)
        else if @modelFor('quizStatistics').get('uniqueCount') < 1
          @controllerFor('quizStatistics').set('error', 'stats_empty')
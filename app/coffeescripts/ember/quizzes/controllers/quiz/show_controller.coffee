define [
  'ember'
  'i18n!quiz_show'
], (Em, I18n) ->

  Ember.ObjectController.extend
    legacyQuizSubmissionVersionsReady: Ember.computed.and('quizSubmissionVersionsHtml', 'didLoadQuizSubmissionVersionsHtml')

    timeLimitWithMinutes: (->
      I18n.t('time_limit_minutes', "%{limit} minutes", {limit: @get("timeLimit")})
    ).property('timeLimit')

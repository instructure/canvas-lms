define [
  'ember'
  'i18n!quiz_show'
], (Em, I18n) ->

  Ember.ObjectController.extend
    timeLimitWithMinutes: (->
      I18n.t('time_limit_minutes', "%{limit} minutes", {limit: @get("timeLimit")})
    ).property('timeLimit')


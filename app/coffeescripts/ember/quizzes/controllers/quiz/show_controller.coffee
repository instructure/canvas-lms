define [
  'ember'
  '../../mixins/legacy_submission_html'
  'i18n!quiz_show'
], (Em, LegacySubmissions, I18n) ->

  Ember.ObjectController.extend LegacySubmissions,
    timeLimitWithMinutes: (->
      I18n.t('time_limit_minutes', "%{limit} minutes", {limit: @get("timeLimit")})
    ).property('timeLimit')


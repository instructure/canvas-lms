define [
  'i18n!course_statistics'
  'jquery'
  'underscore'
  'Backbone'
  'jst/recentStudent'
], (I18n, $, _, Backbone, RecentStudentTemplate) ->

  class RecentStudentView extends Backbone.View

    tagName: 'li'

    template: RecentStudentTemplate

    toJSON: ->
      data = @model.toJSON()
      if data.last_login?
        date = $.fudgeDateForProfileTimezone(new Date(data.last_login))
        data.last_login = I18n.t '#time.event', '%{date} at %{time}',
          date: I18n.l('#date.formats.short', date)
          time: I18n.l('#time.formats.tiny', date)
      else
        data.last_login = I18n.t 'unknown', 'unknown'
      data

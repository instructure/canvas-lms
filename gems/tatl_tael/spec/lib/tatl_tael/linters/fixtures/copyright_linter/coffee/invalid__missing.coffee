import Backbone from 'Backbone'

class CalendarEvent extends Backbone.Model

  urlRoot: '/api/v1/calendar_events/'

  dateAttributes: ['created_at', 'end_at', 'start_at', 'updated_at']

  present: ->
    result = Backbone.Model::toJSON.call(this)
    result.newRecord = !result.id
    result


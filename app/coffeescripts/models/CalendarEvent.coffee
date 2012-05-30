define ['Backbone'], ({Model}) ->

  class CalendarEvent extends Model

    url: 'api/v1/calendar_events'

    defaults:
      title: 'No Title'
      start_at: null
      end_at: null
      context_code: null

    toJSON: ->
      calendar_event: super


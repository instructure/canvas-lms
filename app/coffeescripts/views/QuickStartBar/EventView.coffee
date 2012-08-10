define [
  'i18n!dashboard'
  'jquery'
  'underscore'
  'compiled/views/QuickStartBar/BaseItemView'
  'compiled/models/CalendarEvent'
  'jst/quickStartBar/event'
  'compiled/jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, $, _, BaseItemView, CalendarEvent, template) ->

  class EventView extends BaseItemView

    template: template

    contextSearchOptions:
      fakeInputWidth: '100%'
      contexts: ENV.CONTEXTS
      placeholder: "Type the name of a class to add this to..."
      selector:
        baseData:
          type: 'course'
        preparer: (postData, data, parent) ->
          for row in data
            row.noExpand = true
        browser: false

    save: (json) ->
      date = @$('.datetime_suggest').text()
      json.start_at = date
      json.end_at = date
      delete json.date
      dfds = _.map json.context_code, (code) =>
        model = new CalendarEvent json
        model.set 'context_code', code
        model.save().done ->
      $.when(dfds...).done ->
        $.flashMessage I18n.t 'event_created', 'Event created'

    @type:  'event'
    @title: -> super 'event', 'Event'

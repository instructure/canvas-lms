define [
  'jquery'
  'underscore'
  'i18n!calendar.edit'
  'Backbone'
  'jst/calendar/editCalendarEventFull'
  'wikiSidebar'
  'compiled/object/unflatten'
  'tinymce.editor_box'
  'compiled/tinymce'
], ($, _, I18n, Backbone, editCalendarEventFullTemplate, wikiSidebar, unflatten) ->

  ##
  # View for editing a calendar event on it's own page
  class EditCalendarEventView extends Backbone.View

    el: $('#content')

    template: editCalendarEventFullTemplate

    events:
      'submit form': 'submit'
      'change [name="use_section_dates"]': 'toggleUseSectionDates'
      'click .delete_link': 'destroyModel'

    initialize: ->
      @model.fetch().done =>
        if ENV.NEW_CALENDAR_EVENT_ATTRIBUTES
          attrs = @model.parse(ENV.NEW_CALENDAR_EVENT_ATTRIBUTES)
          # if start and end are at the beginning of a day, assume it is an all day date
          attrs.all_day = !!attrs.start_at?.equals(attrs.end_at) and attrs.start_at.equals(attrs.start_at.clearTime())
          @model.set(attrs)

        @render()
      @model.on 'change:use_section_dates', @toggleUsingSectionClass

    render: =>
      @$el.html @template(@model.toJSON('forView'))

      @$(".date_field").date_field()
      @$(".time_field").time_field()
      $textarea = @$('textarea').editorBox()
      wikiSidebar.init() unless wikiSidebar.inited
      wikiSidebar.attachToEditor($textarea).show()
      this

    destroyModel: =>
      msg = I18n.t "confirm_delete_calendar_event", "Are you sure you want to delete this calendar event?"
      if confirm(msg)
        @$el.disableWhileLoading @model.destroy success: =>
          @redirectWithMessage I18n.t('event_deleted', "%{event_title} deleted successfully", event_title: @model.get('title'))


    # boilerplate that could be replaced with data bindings
    toggleUsingSectionClass: =>
      @$('#editCalendarEventFull').toggleClass 'use_section_dates', @model.get('use_section_dates')
    toggleUseSectionDates: =>
      @model.set 'use_section_dates', !@model.get('use_section_dates')

    redirectWithMessage: (message) ->
      $.flashMessage message
      window.location = @model.get('return_to_url') if @model.get('return_to_url')

    submit: (event) ->
      event?.preventDefault()
      eventData = unflatten @$el.getFormData()
      # force use_section_dates to boolean, so it doesnt cause 'change' if it is '1'
      eventData.use_section_dates = !!eventData.use_section_dates
      _.each [eventData].concat(eventData.child_event_data), @setStartEnd

      @$el.disableWhileLoading @model.save eventData, success: =>
        @redirectWithMessage I18n.t 'event_saved', 'Event Saved Successfully'

    setStartEnd: (obj) ->
      return unless obj
      obj.start_at = Date.parse obj.start_date+' '+obj.start_time
      obj.end_at   = Date.parse obj.start_date+' '+obj.end_time

    @type:  'event'
    @title: -> super 'event', 'Event'

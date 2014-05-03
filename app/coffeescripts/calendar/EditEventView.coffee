define [
  'jquery'
  'underscore'
  'i18n!calendar.edit'
  'Backbone'
  'jst/calendar/editCalendarEventFull'
  'compiled/views/calendar/MissingDateDialogView'
  'wikiSidebar'
  'compiled/object/unflatten'
  'tinymce.editor_box'
  'compiled/tinymce'
], ($, _, I18n, Backbone, editCalendarEventFullTemplate, MissingDateDialogView, wikiSidebar, unflatten) ->

  ##
  # View for editing a calendar event on it's own page
  class EditCalendarEventView extends Backbone.View

    el: $('#content')

    template: editCalendarEventFullTemplate

    events:
      'submit form': 'submit'
      'change #use_section_dates': 'toggleUseSectionDates'
      'click .delete_link': 'destroyModel'
      'click .switch_event_description_view': 'toggleHtmlView'

    initialize: ->
      super
      @model.fetch().done =>
        if ENV.NEW_CALENDAR_EVENT_ATTRIBUTES
          attrs = @model.parse(ENV.NEW_CALENDAR_EVENT_ATTRIBUTES)
          # if start and end are at the beginning of a day, assume it is an all day date
          attrs.all_day = !!attrs.start_at?.equals(attrs.end_at) and attrs.start_at.equals(attrs.start_at.clearTime())
          @model.set(attrs)

        @render()
      @model.on 'change:use_section_dates', @toggleUsingSectionClass

    render: =>
      super

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
      $('.show_if_using_sections input').prop('disabled', !@model.get('use_section_dates'))
    toggleUseSectionDates: (e) =>
      @model.set 'use_section_dates', !@model.get('use_section_dates')
      @updateRemoveChildEvents(e)
    toggleHtmlView: (event) ->
      event?.preventDefault()
      $("textarea[name=description]").editorBox('toggle')
      # hide the clicked link, and show the other toggle link.
      # todo: replace .andSelf with .addBack when JQuery is upgraded.
      $(event.currentTarget).siblings('a').andSelf().toggle()

    updateRemoveChildEvents: (e) ->
      value = if $(e.target).prop('checked') then '' else '1'
      $('input[name=remove_child_events]').val(value)

    redirectWithMessage: (message) ->
      $.flashMessage message
      window.location = @model.get('return_to_url') if @model.get('return_to_url')

    submit: (event) ->
      event?.preventDefault()
      eventData = unflatten @$el.getFormData()
      eventData.use_section_dates = eventData.use_section_dates is '1'
      _.each [eventData].concat(eventData.child_event_data), @setStartEnd
      delete eventData.child_event_data if eventData.remove_child_events == '1'

      if $('#use_section_dates').prop('checked')
        dialog = new MissingDateDialogView
          validationFn: ->
            $fields = $('[name*=start_date]:visible').filter -> $(this).val() is ''
            if $fields.length > 0 then $fields else true
          labelFn   : (input) -> $(input).parents('tr').prev().find('label').text()
          success   : ($dialog) =>
            $dialog.dialog('close')
            @$el.disableWhileLoading @model.save eventData, success: =>
              @redirectWithMessage I18n.t 'event_saved', 'Event Saved Successfully'
            $dialog.remove()
        return if dialog.render()

      @saveEvent(eventData)

    saveEvent: (eventData) ->
      @$el.disableWhileLoading @model.save eventData, success: =>
        @redirectWithMessage I18n.t 'event_saved', 'Event Saved Successfully'

    setStartEnd: (obj) ->
      return unless obj
      obj.start_at = $.unfudgeDateForProfileTimezone(Date.parse obj.start_date+' '+obj.start_time)
      obj.end_at   = $.unfudgeDateForProfileTimezone(Date.parse obj.start_date+' '+obj.end_time)

    @type:  'event'
    @title: -> super 'event', 'Event'

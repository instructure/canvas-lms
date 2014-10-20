define [
  'jquery'
  'underscore'
  'i18n!calendar.edit'
  'timezone'
  'Backbone'
  'jst/calendar/editCalendarEventFull'
  'compiled/views/calendar/MissingDateDialogView'
  'wikiSidebar'
  'compiled/object/unflatten'
  'compiled/util/deparam'
  'tinymce.editor_box'
  'compiled/tinymce'
], ($, _, I18n, tz, Backbone, editCalendarEventFullTemplate, MissingDateDialogView, wikiSidebar, unflatten, deparam) ->

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
        picked_params = _.pick(deparam(), 'start_date', 'start_time', 'end_time', 'title', 'description', 'location_name', 'location_address')

        attrs = @model.parse(picked_params)
        # if start and end are at the beginning of a day, assume it is an all day date
        attrs.all_day = !!attrs.start_at?.equals(attrs.end_at) and attrs.start_at.equals(attrs.start_at.clearTime())
        @model.set(attrs)

        @render()

        # populate inputs with params passed through the url
        _.each _.keys(picked_params), (key) =>
          $e = @$el.find("input[name='#{key}']")
          $e.val(picked_params[key])
          $e.change()

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
      eventData = unflatten @getFormData()
      eventData.use_section_dates = eventData.use_section_dates is '1'
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

    getFormData: ->
      data = @$el.getFormData()

      # pull the true, parsed dates from the inputs to calculate start_at and end_at correctly
      keys = _.filter _.keys(data), ( (key) -> /start_date/.test(key) )
      _.each keys, (start_date_key) =>
        start_time_key = start_date_key.replace(/start_date/, 'start_time')
        end_time_key = start_date_key.replace(/start_date/, 'end_time')
        start_at_key = start_date_key.replace(/start_date/, 'start_at')
        end_at_key = start_date_key.replace(/start_date/, 'end_at')

        start_date = @$el.find("[name='#{start_date_key}']").data('date')
        start_time = @$el.find("[name='#{start_time_key}']").data('date')
        end_time = @$el.find("[name='#{end_time_key}']").data('date')
        return unless start_date

        data = _.omit(data, start_date_key, start_time_key, end_time_key)

        start_at = start_date.toString('yyyy-MM-dd')
        start_at += start_time.toString(' HH:mm') if start_time
        data[start_at_key] = tz.parse(start_at)

        end_at = start_date.toString('yyyy-MM-dd')
        end_at += end_time.toString(' HH:mm') if end_time
        data[end_at_key] = tz.parse(end_at)

      data

    @type:  'event'
    @title: -> super 'event', 'Event'

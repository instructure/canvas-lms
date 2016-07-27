define [
  'jquery'
  'underscore'
  'i18n!calendar.edit'
  'timezone'
  'Backbone'
  'jst/calendar/editCalendarEventFull'
  'compiled/views/calendar/MissingDateDialogView'
  'jsx/shared/rce/RichContentEditor'
  'compiled/object/unflatten'
  'compiled/util/deparam'
  'compiled/views/editor/KeyboardShortcuts'
  'compiled/util/coupleTimeFields'
], ($, _, I18n, tz, Backbone, editCalendarEventFullTemplate, MissingDateDialogView, RichContentEditor, unflatten, deparam, KeyboardShortcuts, coupleTimeFields) ->

  RichContentEditor.preloadRemoteModule()

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
      'change "#duplicate_event': 'duplicateCheckboxChanged'

    initialize: ->
      super
      @model.fetch().done =>
        picked_params = _.pick(deparam(),
          'start_date', 'start_time', 'end_time',
          'title', 'description', 'location_name', 'location_address',
          'duplicate')
        if picked_params.start_date
          picked_params.start_date = $.dateString($.fudgeDateForProfileTimezone(picked_params.start_date), {format: 'medium'})

        attrs = @model.parse(picked_params)
        # if start and end are at the beginning of a day, assume it is an all day date
        attrs.all_day = !!attrs.start_at?.equals(attrs.end_at) and attrs.start_at.equals(attrs.start_at.clearTime())
        @model.set(attrs)

        @render()

        # populate inputs with params passed through the url
        if picked_params.duplicate
          _.each _.keys(picked_params.duplicate), (key) =>
            oldKey = key
            key = "duplicate_#{key}" unless key is "append_iterator"
            picked_params[key] = picked_params.duplicate[oldKey]
            delete picked_params.duplicate[key]

          picked_params.duplicate = !!picked_params.duplicate

        _.each _.keys(picked_params), (key) =>
          $e = @$el.find("input[name='#{key}'], select[name='#{key}']")
          value = if $e.prop('type') is "checkbox"
                    [picked_params[key]]
                  else
                    picked_params[key]
          $e.val(value)
          @enableDuplicateFields($e.val()) if key is "duplicate"
          $e.change()

      @model.on 'change:use_section_dates', @toggleUsingSectionClass

    render: =>
      super

      @$(".date_field").date_field()
      @$(".time_field").time_field()
      @$(".date_start_end_row").each (_, row) =>
        date = $('.start_date', row).first()
        start = $('.start_time', row).first()
        end = $('.end_time', row).first()
        coupleTimeFields(start, end, date)

      $textarea = @$('textarea')
      RichContentEditor.initSidebar()
      RichContentEditor.loadNewEditor($textarea, { focus: true, manageParent: true })

      _.defer(@attachKeyboardShortcuts)
      _.defer(@toggleDuplicateOptions)
      this

    attachKeyboardShortcuts: =>
      $('.switch_event_description_view').first().before((new KeyboardShortcuts()).render().$el)

    toggleDuplicateOptions: =>
      @$el.find(".duplicate_event_toggle_row").toggle(@model.isNew())

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
      RichContentEditor.callOnRCE($("textarea[name=description]"), 'toggle')
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

      if @$el.find('#duplicate_event').prop('checked')
        data.duplicate = {
          count: @$el.find('#duplicate_count').val()
          interval: @$el.find('#duplicate_interval').val()
          frequency: @$el.find('#duplicate_frequency').val()
          append_iterator: @$el.find('#append_iterator').is(":checked")
        }

      data

    @type:  'event'
    @title: -> super 'event', 'Event'

    enableDuplicateFields: (shouldEnable) =>
      elts = @$el.find(".duplicate_fields").find('input')
      disableValue = !shouldEnable
      elts.prop("disabled", disableValue)
      @$el.find('.duplicate_event_row').toggle(!disableValue)

    duplicateCheckboxChanged: (jsEvent, propagate) =>
      @enableDuplicateFields(jsEvent.target.checked)

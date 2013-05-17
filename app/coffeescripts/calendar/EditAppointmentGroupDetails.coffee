define [
  'jquery'
  'underscore'
  'i18n!EditAppointmentGroupDetails'
  'compiled/calendar/TimeBlockList'
  'jst/calendar/editAppointmentGroup'
  'jst/calendar/genericSelect'
  'jst/calendar/sectionCheckboxes'
  'compiled/calendar/ContextSelector'
  'compiled/fn/preventDefault'
  'jquery.ajaxJSON'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
], ($, _, I18n, TimeBlockList, editAppointmentGroupTemplate, genericSelectTemplate, sectionCheckboxesTemplate, ContextSelector, preventDefault) ->

  class EditAppointmentGroupDetails
    constructor: (selector, @apptGroup, @contexts, @closeCB) ->
      @currentContextInfo = null

      $(selector).html editAppointmentGroupTemplate({
        title: @apptGroup.title
        contexts: @contexts
        appointment_group: @apptGroup
      })

      @contextsHash = {}
      @contextsHash[c.asset_string] = c for c in @contexts

      @form = $(selector).find("form")

      @contextSelector = new ContextSelector('.ag-menu-container', @apptGroup, @contexts, @contextsChanged, @toggleContextsMenu)

      if @editing()
        @form.attr('action', @apptGroup.url)

        # Don't let them change a bunch of fields once it's created
        @form.find(".context_id").val(@apptGroup.context_code).attr('disabled', true)
        @form.find("select.context_id").change()

        @disableGroups()
        if @apptGroup.participant_type == 'Group'
          @form.find(".group-signup-checkbox").prop('checked', true)
          @form.find(".group_category").val(@apptGroup.sub_context_codes[0])
        else
          @form.find(".group-signup-checkbox").prop('checked', false)

        $(".reservation_help").click @openHelpDialog
      else
        # FIXME: put this url in ENV json or something
        @form.attr('action', '/api/v1/appointment_groups')

      @form.find('.ag_contexts_selector').click preventDefault @toggleContextsMenu

      timeBlocks = ([appt.start, appt.end, true] for appt in @apptGroup.appointmentEvents || [] )
      @timeBlockList = new TimeBlockList(@form.find(".time-block-list-body"), @form.find(".splitter"), timeBlocks)

      @form.find('[name="slot_duration"]').change (e) =>
        if @form.find('[name="autosplit_option"]').is(":checked")
          @timeBlockList.split(e.target.value)
          @timeBlockList.render()

      @form.find('[name="participant_visibility"]').prop('checked', @apptGroup.participant_visibility == 'protected')

      @form.find(".group-signup-checkbox").change (jsEvent) =>
        checked = !!jsEvent.target.checked
        @form.find('.per_appointment_groups_label').toggle(checked)
        @form.find('.per_appointment_users_label').toggle(!checked)
        @form.find(".group-signup").toggle(checked)
      @form.find(".group-signup-checkbox").change()

      $perSlotCheckbox = @form.find('[name="per_slot_option"]')
      $perSlotInput =    @form.find('[name="participants_per_appointment"]')
      slotChangeHandler = (e) => @perSlotChange($perSlotCheckbox, $perSlotInput)
      $.merge($perSlotCheckbox, $perSlotInput).on 'change', slotChangeHandler
      if @apptGroup.participants_per_appointment > 0
        $perSlotCheckbox.prop('checked', true)
        $perSlotInput.val(@apptGroup.participants_per_appointment)
      else
        $perSlotInput.attr('disabled', true)

      $maxPerStudentCheckbox = @form.find('#max-per-student-option')
      $maxPerStudentInput =    @form.find('[name="max_appointments_per_participant"]')
      maxApptHandler = (e) => @maxStudentAppointmentsChange($maxPerStudentCheckbox, $maxPerStudentInput)
      $.merge($maxPerStudentCheckbox, $maxPerStudentInput).on 'change', maxApptHandler
      maxAppointmentsPerStudent = @apptGroup.max_appointments_per_participant
      $maxPerStudentInput.val(maxAppointmentsPerStudent)
      if maxAppointmentsPerStudent > 0 || @creating()
        $maxPerStudentCheckbox.prop('checked', true)
        $maxPerStudentInput.val('1') if @creating() and $maxPerStudentInput.val() == ''
      else
        $maxPerStudentInput.attr('disabled', true)

      if @apptGroup.workflow_state == 'active'
        @form.find("#appointment-blocks-active-button").attr('disabled', true).prop('checked', true)

    creating: ->
      !@editing()
    editing: ->
      @apptGroup.id?

    perSlotChange: (checkbox, input) ->
      @checkBoxInputChange checkbox, input
      slotLimit = parseInt(input.val())
      @helpIconShowIf checkbox, _.any(@apptGroup.appointments, (a) -> a.child_events_count > slotLimit)

    maxStudentAppointmentsChange: (checkbox, input) ->
      @checkBoxInputChange checkbox, input
      apptLimit = parseInt(input.val())
      apptCounts = {}
      for a in @apptGroup.appointments
        for e in a.child_events
          apptCounts[e.user.id] ||= 0
          apptCounts[e.user.id] += 1
      @helpIconShowIf checkbox, _.any(apptCounts, (count, userId) -> count > apptLimit)

    # show/hide the help icon
    helpIconShowIf: (checkbox, show) ->
      helpIcon = checkbox.closest('li').find('.reservation_help')
      if show and checkbox.is(':checked')
        helpIcon.removeClass('hidden')
      else
        helpIcon.addClass('hidden')

    # enable/disable the input
    checkBoxInputChange: (checkbox, input) ->
      input.val('1') if checkbox.prop('checked') and input.val() == ''
      input.prop('disabled', not checkbox.prop('checked'))

    openHelpDialog: (e) =>
      e.preventDefault()
      $("#options_help_dialog").dialog
        title: I18n.t('affect_reservations', "How will this affect reservations?")
        width: 400

    saveWithoutPublishingClick: (jsEvent) =>
      jsEvent.preventDefault()
      @save(false)

    saveClick: (jsEvent) =>
      jsEvent.preventDefault()
      @save(true)

    save: (publish) =>
      data = @form.getFormData(object_name: 'appointment_group')

      params = {
        'appointment_group[title]': data.title
        'appointment_group[description]': data.description
        'appointment_group[location_name]': data.location
      }

      if data.max_appointments_per_participant_option
        if data.max_appointments_per_participant < 1
          $('[name="max_appointments_per_participant"]').errorBox(
            I18n.t('bad_max_appts', 'You must allow at least one appointment per participant'))
          return false
        else
          params['appointment_group[max_appointments_per_participant]'] = data.max_appointments_per_participant
      else
        params['appointment_group[max_appointments_per_participant]'] = ""

      params['appointment_group[new_appointments]'] = []
      return false unless @timeBlockList.validate()
      for range in @timeBlockList.blocks()
        params['appointment_group[new_appointments]'].push([
          $.dateToISO8601UTC($.unfudgeDateForProfileTimezone(range[0])),
          $.dateToISO8601UTC($.unfudgeDateForProfileTimezone(range[1]))
        ])

      if data.per_slot_option
        if data.participants_per_appointment < 1
          $('[name="participants_per_appointment"]').errorBox(
            I18n.t('bad_per_slot', 'You must allow at least one appointment per time slot'))
          return false
        else
          params['appointment_group[participants_per_appointment]'] = data.participants_per_appointment
      else
        params['appointment_group[participants_per_appointment]'] = ""

      if publish && @apptGroup.workflow_state != 'active'
        params['appointment_group[publish]'] = '1'

      params['appointment_group[participant_visibility]'] = if data.participant_visibility == '1' then 'protected' else 'private'

      # get the context/section info from @contextSelector instead
      delete data['context_codes[]']
      delete data['sections[]']

      contextCodes = @contextSelector.selectedContexts()
      if contextCodes.length == 0
        $('.ag_contexts_selector').errorBox(I18n.t 'context_required', 'You need to select a calendar')
        return
      else
        params['appointment_group[context_codes]'] = contextCodes

      if @creating()
        if data.use_group_signup == '1' && data.group_category_id
          params['appointment_group[sub_context_codes]'] = [data.group_category_id]
        else
          sections = @contextSelector.selectedSections()
          params['appointment_group[sub_context_codes]'] = sections if sections

        # TODO: Provide UI for specifying this
        params['appointment_group[min_appointments_per_participant]'] = 1

      onSuccess = => @closeCB(true)
      onError = =>

      method = if @editing() then 'PUT' else 'POST'

      deferred = $.ajaxJSON @form.attr('action'), method, params, onSuccess, onError
      @form.disableWhileLoading(deferred)

    contextsChanged: (contextCodes, sectionCodes) =>
      # dropdown text
      if sectionCodes.length == 0 and contextCodes.length == 0
        @form.find('.ag_contexts_selector').text(I18n.t 'select_calendars', 'Select Calendars')
      else
        if contextCodes.length > 0
          contextCode = contextCodes[0]
          text = @contextsHash[contextCode].name
          if contextCodes.length > 1
            text += I18n.t('and_n_contexts', ' and %{n} others', n: contextCodes.length - 1)
          @form.find('.ag_contexts_selector').text(text)
        if sectionCodes.length > 0
          sectionCode = sectionCodes[0]
          section = _.chain(@contexts)
                     .pluck('course_sections')
                     .flatten()
                     .find((s) -> s.asset_string == sectionCode)
                     .value()
          text = section.name
          if sectionCodes.length > 1
            text += I18n.t('and_n_sectionCodes', ' and %{n} others', n: sectionCodes.length - 1)
          @form.find('.ag_contexts_selector').text(text)

      # group selector
      context = @contextsHash[contextCodes[0]]
      if contextCodes.length == 1 and sectionCodes.length == 0 and context.group_categories?.length > 0
        @enableGroups(context)
        if @apptGroup.sub_context_codes.length > 0
          @form.find('[name=group_category_id]').prop('disabled', true)
      else
        @disableGroups()

    disableGroups: ->
      @form.find(".group-signup-checkbox").attr('disabled', true)
      @form.find("group-signup").hide()

    enableGroups: (contextInfo) ->
      @form.find(".group-signup-checkbox").attr('disabled', false)
      groupsInfo =
        cssClass: 'group_category'
        name: 'group_category_id'
        collection: contextInfo.group_categories
      @form.find(".group_select").html(genericSelectTemplate(groupsInfo))
      @form.find("group-signup").show()

    toggleContextsMenu: (jsEvent) =>
      $('.ag_contexts_menu').toggleClass('hidden')

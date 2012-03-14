define [
  'jquery'
  'i18n!EditAppointmentGroupDetails'
  'compiled/calendar/TimeBlockList'
  'jst/calendar/editAppointmentGroup'
  'jst/calendar/genericSelect'
  'jquery.ajaxJSON'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
], ($, I18n, TimeBlockList, editAppointmentGroupTemplate, genericSelectTemplate) ->

  class EditAppointmentGroupDetails
    constructor: (selector, @apptGroup, @contextChangeCB, @closeCB) ->
      @currentContextInfo = null
      $(selector).html editAppointmentGroupTemplate({
        title: @apptGroup.title
        contexts: @apptGroup.contexts
        appointment_group: @apptGroup
      })
      @form = $(selector).find("form")

      @form.find("select.context_id").change(@contextChange).change()

      if @apptGroup.id
        @form.attr('action', @apptGroup.url)

        # Don't let them change a bunch of fields once it's created
        @form.find(".context_id").val(@apptGroup.context_code).attr('disabled', true)
        @form.find("select.context_id").change()

        @form.find(".group_category").attr('disabled', true)
        @form.find(".course_section").attr('disabled', true)
        @form.find(".group-signup-checkbox").attr('disabled', true)
        if @apptGroup.participant_type == 'Group'
          @form.find(".group-signup-checkbox").prop('checked', true)
          @form.find(".group_category").val(@apptGroup.sub_context_code)
        else
          @form.find(".group-signup-checkbox").prop('checked', false)
          if @apptGroup.sub_context_code
            @form.find(".course_section").val(@apptGroup.sub_context_code)
          else
            @form.find(".course_section").val("all")
      else
        @form.attr('action', @currentContextInfo.create_appointment_group_url)

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
        @form.find(".section-signup").toggle(!checked)
        @form.find(".group-signup").toggle(checked)
      @form.find(".group-signup-checkbox").change()

      @form.find('[name="per_slot_option"]').change (jsEvent) =>
        checkbox = jsEvent.target
        input = @form.find('[name="participants_per_appointment"]')
        if checkbox.checked
          input.attr('disabled', false)
          input.val('1') if input.val() == ''
        else
          input.attr('disabled', true)
      if @apptGroup.participants_per_appointment > 0
        @form.find('[name="per_slot_option"]').prop('checked', true)
        @form.find('[name="participants_per_appointment"]').val(@apptGroup.participants_per_appointment)
      else
        @form.find('[name="participants_per_appointment"]').attr('disabled', true)

      maxPerStudentInput = @form.find('[name="max_appointments_per_participant"]')
      maxAppointmentsPerStudent = @apptGroup.max_appointments_per_participant || 1
      maxPerStudentInput.val(maxAppointmentsPerStudent)
      maxPerStudentCheckbox = @form.find('#max-per-student-option')
      maxPerStudentCheckbox.change ->
        maxPerStudentInput.prop('disabled', not maxPerStudentCheckbox.prop('checked'))
      if maxAppointmentsPerStudent > 0
        maxPerStudentCheckbox.prop('checked', true)
      else
        maxPerStudentInput.attr('disabled', true)

      if @apptGroup.workflow_state == 'active'
        @form.find("#appointment-blocks-active-button").attr('disabled', true).prop('checked', true)

    contextInfoForCode: (code) ->
      for context in @apptGroup.contexts
        if context.asset_string == code
          return context
      return null

    saveWithoutPublishingClick: (jsEvent) =>
      jsEvent.preventDefault()
      @save(false)

    saveClick: (jsEvent) =>
      jsEvent.preventDefault()
      @save(true)

    save: (publish) =>
      data = @form.getFormData(object_name: 'appointment_group')
      create = @apptGroup.id == undefined

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

      if data.per_slot_option == '1' && data.participants_per_appointment
        params['appointment_group[participants_per_appointment]'] = data.participants_per_appointment

      if publish && @apptGroup.workflow_state != 'active'
        params['appointment_group[publish]'] = '1'

      params['appointment_group[participant_visibility]'] = if data.participant_visibility == '1' then 'protected' else 'private'

      if create
        params['appointment_group[context_code]'] = data.context_code

        if data.use_group_signup == '1' && data.group_category_id
          params['appointment_group[sub_context_code]'] = data.group_category_id
        else if data.section_id && data.section_id != 'all'
          params['appointment_group[sub_context_code]'] = data.section_id

        # TODO: Provide UI for specifying this
        params['appointment_group[min_appointments_per_participant]'] = 1

      onSuccess = => @closeCB(true)
      onError = => 

      method = if @apptGroup.id then 'PUT' else 'POST'

      deferred = $.ajaxJSON @form.attr('action'), method, params, onSuccess, onError
      @form.disableWhileLoading(deferred)

    contextChange: (jsEvent) =>
      context = $(jsEvent.target).val()
      @currentContextInfo = @contextInfoForCode(context)
      @apptGroup.contextInfo = @currentContextInfo
      if @currentContextInfo == null then return

      # Update the sections and groups lists in the scheduler
      if @currentContextInfo.course_sections
        sectionsInfo =
          cssClass: 'course_section'
          name: 'section_id'
          collection: [ { id: 'all', name: "All Sections"} ].concat @currentContextInfo.course_sections
        @form.find(".section_select").html(genericSelectTemplate(sectionsInfo))

      if !@currentContextInfo.group_categories || @currentContextInfo.group_categories.length == 0
        @form.find(".group-signup-checkbox").attr('disabled', true).prop('checked', false).change()
      else if @currentContextInfo.group_categories
        @form.find(".group-signup-checkbox").attr('disabled', false)
        groupsInfo =
          cssClass: 'group_category'
          name: 'group_category_id'
          collection: @currentContextInfo.group_categories
        @form.find(".group_select").html(genericSelectTemplate(groupsInfo))

      @contextChangeCB(context)

      # Update the edit and more options links with the new context, if this is a new group
      if !@apptGroup.id
        @form.attr('action', @currentContextInfo.create_appointment_group_url)

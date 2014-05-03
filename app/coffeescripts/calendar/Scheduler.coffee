define [
  'jquery',
  'underscore'
  'i18n!calendar'
  'jst/calendar/appointmentGroupList'
  'jst/calendar/schedulerRightSideAdminSection'
  'compiled/calendar/EditAppointmentGroupDialog'
  'compiled/calendar/MessageParticipantsDialog'
  'jst/calendar/deleteItem'
  'compiled/util/semanticDateRange'
  'jquery.instructure_date_and_time'
  'jqueryui/dialog'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'vendor/jquery.spin'
], ($, _, I18n, appointmentGroupListTemplate, schedulerRightSideAdminSectionTemplate, EditAppointmentGroupDialog, MessageParticipantsDialog, deleteItemTemplate, semanticDateRange) ->

  class Scheduler
    constructor: (selector, @calendar) ->
      @div = $ selector
      @contexts = @calendar.contexts

      @listDiv = @div.find(".appointment-list")

      @div.delegate('.view_calendar_link', 'click', @viewCalendarLinkClick)
      @listDiv.delegate('.edit_link', 'click', @editLinkClick)
      @listDiv.delegate('.message_link', 'click', @messageLinkClick)
      @listDiv.delegate('.delete_link', 'click', @deleteLinkClick)
      @listDiv.delegate('.show_event_link', 'click', @showEventLinkClick)

      if @canManageAGroup()
        @div.addClass('can-manage')
        @rightSideAdminSection = $(schedulerRightSideAdminSectionTemplate())
        @rightSideAdminSection.find(".create_link").click @createClick

        @appointmentGroupContexts = _.filter @contexts, (c) ->
          c.can_create_appointment_groups

      $.subscribe "CommonEvent/eventSaved", @eventSaved
      $.subscribe "CommonEvent/eventDeleted", @eventDeleted

    createClick: (jsEvent) =>
      jsEvent.preventDefault()

      group = {
        context_codes: []
        sub_context_codes: []
      }

      @createDialog = new EditAppointmentGroupDialog(group, @appointmentGroupContexts, @dialogCloseCB)
      @createDialog.show()

    dialogCloseCB: (saved) =>
      if saved
        @calendar.dataSource.clearCache()
        @loadData()

    eventSaved: (event) =>
      if @active
        @calendar.dataSource.clearCache()
        @loadData()

    eventDeleted: (event) =>
      if @active
        @calendar.dataSource.clearCache()
        @loadData()

    toggleListMode: (showListMode)->
      if showListMode
        delete @viewingGroup
        @calendar.updateFragment appointment_group_id: null
        @showList()
        if @canManageAGroup()
          $('#right-side .rs-section').hide()

          @rightSideAdminSection.appendTo('#right-side')
        else
          $('#right-side-wrapper').hide()
      else
        $('#right-side-wrapper').show()
        $('#right-side .rs-section').not("#undated-events-section, #calendar-feed").show()
        # we have to .detach() because of the css that puts lines under each .rs-section except the last,
        # if we just .hide() it would still be there so the :last-child selector would apply to it,
        # not the last _visible_ element
        @rightSideAdminSection?.detach()

    show: =>
      $("#undated-events-section, #calendar-feed").hide()
      @active = true
      @div.show()
      @loadData()
      @toggleListMode(true)

    hide: =>
      $("#undated-events-section, #calendar-feed").show()
      @active = false
      @div.hide()
      @toggleListMode(false)
      @calendar.displayAppointmentEvents = null
      $.publish "Calendar/restoreVisibleContextList"

    canManageAGroup: =>
      for contextInfo in @contexts
        if contextInfo.can_create_appointment_groups
          return true
      false

    loadData: =>
      if not @loadingDeferred || (@loadingDeferred && not @loadingDeferred.isResolved())
        @loadingDeferred = new $.Deferred()

      @groups = {}
      @loadingDiv ?= $('<div id="scheduler-loading" />').appendTo(@div).spin()

      @calendar.dataSource.getAppointmentGroups @canManageAGroup(), (data) =>
        for group in data
          @groups[group.id] = group
        @redraw()
        @loadingDeferred.resolve()

    redraw: =>
      @loadingDiv.hide()

      if @groups
        groups = []
        for id, group of @groups
          for timeId, time of group.reserved_times
            time.formatted_time = semanticDateRange(time.start_at, time.end_at)

          # look up the context names for the group
          group.contexts = _.filter(@contexts, (c) -> c.asset_string in group.context_codes)

          group.published = group.workflow_state == "active"

          groups.push group

        html = appointmentGroupListTemplate
          appointment_groups: groups
          canManageAGroup: @canManageAGroup()
        @listDiv.find(".list-wrapper").html html

        if @viewingGroup
          @viewingGroup = @groups[@viewingGroup.id]
          if @viewingGroup
            @listDiv.find(".appointment-group-item[data-appointment-group-id='#{@viewingGroup.id}']").addClass('active')
            @calendar.displayAppointmentEvents = @viewingGroup
          else
            @toggleListMode(true)

      $.publish "Calendar/refetchEvents"

    viewCalendarLinkClick: (jsEvent) =>
      jsEvent.preventDefault()
      @viewCalendarForElement $(jsEvent.target)

    showEventLinkClick: (jsEvent) =>
      jsEvent.preventDefault()
      group = @viewCalendarForElement $(jsEvent.target)

      eventId = $(jsEvent.target).data('event-id')
      if eventId
        for appointmentEvent in group.object.appointmentEvents
          for childEvent in appointmentEvent.object.childEvents when childEvent.id == eventId
            @calendar.gotoDate(childEvent.start)
            return

    viewCalendarForElement: (el) =>
      thisItem = el.closest(".appointment-group-item")
      groupId = thisItem.data('appointment-group-id')
      thisItem.addClass('active')
      group = @groups?[groupId]
      @viewCalendarForGroup(@groups?[groupId])
      group

    viewCalendarForGroupId: (id) =>
      @loadData()
      @loadingDeferred.done =>
        @viewCalendarForGroup @groups?[id]

    viewCalendarForGroup: (group) =>
      @calendar.updateFragment appointment_group_id: group.id
      @toggleListMode(false)
      @viewingGroup = group

      @loadingDeferred.done =>
        @div.addClass('showing-single')

        @calendar.showSchedulerSingle();
        if @viewingGroup.start_at
          @calendar.gotoDate($.fudgeDateForProfileTimezone(@viewingGroup.start_at))
        else
          @calendar.gotoDate(new Date())

        @calendar.displayAppointmentEvents = @viewingGroup
        $.publish "Calendar/refetchEvents"
        @redraw()

    doneClick: (jsEvent) =>
      jsEvent?.preventDefault()
      @toggleListMode(true)

    showList: =>
      @div.removeClass('showing-single')
      @listDiv.find('.appointment-group-item').removeClass('active')

      @calendar.calendar.hide()
      @calendar.displayAppointmentEvents = null

    editLinkClick: (jsEvent) =>
      jsEvent.preventDefault()
      group = @groups?[$(jsEvent.target).closest(".appointment-group-item").data('appointment-group-id')]
      return unless group

      @calendar.dataSource.getEventsForAppointmentGroup group, (events) =>
        @loadData()
        @loadingDeferred.done =>
          group = @groups[group.id]
          @createDialog = new EditAppointmentGroupDialog(group, @appointmentGroupContexts, @dialogCloseCB)
          @createDialog.show()

    deleteLinkClick: (jsEvent) =>
      jsEvent.preventDefault()
      group = @groups?[$(jsEvent.target).closest(".appointment-group-item").data('appointment-group-id')]
      return unless group

      $("<div />").confirmDelete
        url: group.url
        message: $ deleteItemTemplate(message: I18n.t('confirm_appointment_group_deletion', "Are you sure you want to delete this appointment group?"), details: I18n.t('appointment_group_deletion_details', "Deleting it will also delete any appointments that have been signed up for by students."))
        dialog: {title: I18n.t('confirm_deletion', "Confirm Deletion")}
        prepareData: ($dialog) => {cancel_reason: $dialog.find('#cancel_reason').val() }
        confirmed: =>
          $(jsEvent.target).closest(".appointment-group-item").addClass("event_pending")
        success: =>
          @calendar.dataSource.clearCache()
          @loadData()

    messageLinkClick: (jsEvent) =>
      jsEvent.preventDefault()
      group = @groups?[$(jsEvent.target).closest(".appointment-group-item").data('appointment-group-id')]
      @messageDialog = new MessageParticipantsDialog(group: group, dataSource: @calendar.dataSource)
      @messageDialog.show()

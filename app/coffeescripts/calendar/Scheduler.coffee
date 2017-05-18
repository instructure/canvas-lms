#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery',
  'underscore'
  'i18n!calendar'
  'compiled/util/fcUtil'
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
  'spin.js/jquery.spin'
  'compiled/behaviors/activate'
], ($, _, I18n, fcUtil, appointmentGroupListTemplate, schedulerRightSideAdminSectionTemplate, EditAppointmentGroupDialog, MessageParticipantsDialog, deleteItemTemplate, semanticDateRange) ->

  class Scheduler
    constructor: (selector, @calendar) ->
      @div = $ selector
      @contexts = @calendar.contexts

      @listDiv = @div.find(".appointment-list")

      @div.delegate('.view_calendar_link', 'click keyclick', @viewCalendarLinkClick)
      @div.activate_keyclick('.view_calendar_link')
      @listDiv.delegate('.edit_link', 'click', @editLinkClick)
      @listDiv.delegate('.message_link', 'click', @messageLinkClick)
      @listDiv.delegate('.delete_link', 'click', @deleteLinkClick)
      @listDiv.delegate('.show_event_link', 'click keyclick', @showEventLinkClick)
      @listDiv.activate_keyclick('.show_event_link')

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
      if not @loadingDeferred || (@loadingDeferred && @loadingDeferred.isResolved())
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
            appointmentGroup = @listDiv.find(".appointment-group-item[data-appointment-group-id='#{@viewingGroup.id}']")
            appointmentGroup.addClass('active')
            appointmentGroup.find('h3 .view_calendar_link').focus()
            @calendar.displayAppointmentEvents = @viewingGroup
          else
            @toggleListMode(true)

      $.publish "Calendar/refetchEvents"
      if (@viewingGroup)
        @calendar.showSchedulerSingle(@viewingGroup)

    viewCalendarLinkClick: (jsEvent) =>
      jsEvent.preventDefault()
      if not @viewingGroup
        $.screenReaderFlashMessageExclusive(I18n.t('Scheduler shown'))
      @viewCalendarForElement $(jsEvent.target)

    showEventLinkClick: (jsEvent) =>
      if not @viewingGroup
        $.screenReaderFlashMessageExclusive(I18n.t('Scheduler shown'))
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
      @viewCalendarForGroup(group)
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

        if @viewingGroup.start_at
          @calendar.gotoDate(fcUtil.wrap(@viewingGroup.start_at))
        else
          @calendar.gotoDate(fcUtil.now())

        @calendar.displayAppointmentEvents = @viewingGroup
        $.publish "Calendar/refetchEvents"
        @redraw()

    doneClick: (jsEvent) =>
      jsEvent?.preventDefault()
      @toggleListMode(true)

    showList: =>
      @div.removeClass('showing-single')
      target = @listDiv.find('.appointment-group-item.active h3 .view_calendar_link')
      @listDiv.find('.appointment-group-item').removeClass('active')

      @calendar.hideAgendaView()
      @calendar.displayAppointmentEvents = null
      target.focus()

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

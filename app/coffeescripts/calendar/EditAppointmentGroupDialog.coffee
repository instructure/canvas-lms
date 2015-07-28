define [
  'jquery'
  'i18n!calendar'
  'compiled/calendar/EditAppointmentGroupDetails'
  'jst/calendar/editAppointmentGroup'
  'jqueryui/dialog'
], ($, I18n, EditAppointmentGroupDetails, editAppointmentGroupTemplate) ->

  dialog = $('<div id="edit_event"><div class="wrapper"></div>').appendTo('body').dialog
    autoOpen: false
    width: 'auto'
    resizable: false
    title: I18n.t('titles.edit_appointment_group', "Edit Appointment Group")
  # this is dumb, but it prevents the columns from wrapping when
  # the context selector drop down gets too long
  dialog.dialog('widget').find('#edit_event').css('overflow', 'visible')

  class EditAppointmentGroupDialog
    constructor: (@apptGroup, @contexts, @parentCloseCB) ->
      @currentContextInfo = null

    closeCB: (saved) =>
      dialog.dialog('close')
      @parentCloseCB(saved)

    show: =>
      @appointmentGroupsForm = new EditAppointmentGroupDetails(dialog.find(".wrapper"), @apptGroup, @contexts, @closeCB)

      buttons = if @apptGroup.workflow_state == 'active'
        [
          text: I18n.t 'save_changes', 'Save Changes'
          class: 'btn-primary'
          click: @appointmentGroupsForm.saveClick
        ]
      else
        [
          text: I18n.t 'save', 'Save'
          click: @appointmentGroupsForm.saveWithoutPublishingClick
        ,
          text: I18n.t 'save_and_publish', 'Save & Publish'
          class: 'btn-primary'
          click: @appointmentGroupsForm.saveClick
        ]

      dialog.dialog('option', 'buttons', buttons).dialog('open')

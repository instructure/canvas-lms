define [
  'jquery'
  'i18n!calendar'
  'compiled/calendar/EditAppointmentGroupDetails'
  'jst/calendar/editAppointmentGroup'
  'jquery.instructure_jquery_patches'
], ($, I18n, EditAppointmentGroupDetails, editAppointmentGroupTemplate) ->

  dialog = $('<div id="edit_event"><div class="wrapper"></div>').appendTo('body').dialog
    autoOpen: false
    width: 'auto'
    resizable: false
    title: I18n.t('titles.edit_appointment_group', "Edit Appointment Group")

  class EditAppointmentGroupDialog
    constructor: (@apptGroup, @parentCloseCB) ->
      @currentContextInfo = null

    contextChange: (newContext) =>
      # TODO: update the color?

    closeCB: (saved) =>
      dialog.dialog('close')
      @parentCloseCB(saved)

    show: =>
      @appointmentGroupsForm = new EditAppointmentGroupDetails(dialog.find(".wrapper"), @apptGroup, @contextChange, @closeCB)

      buttons = if @apptGroup.workflow_state == 'active'
        [
          text: I18n.t 'save_changes', 'Save Changes'
          click: @appointmentGroupsForm.saveClick
        ]
      else
        [
          text: I18n.t 'save_and_publish', 'Save & Publish'
          'class' : 'ui-button-primary'
          click: @appointmentGroupsForm.saveClick
        ,
          text: I18n.t 'save', 'Save'
          click: @appointmentGroupsForm.saveWithoutPublishingClick
        ]

      dialog.dialog('option', 'buttons', buttons).dialog('open')

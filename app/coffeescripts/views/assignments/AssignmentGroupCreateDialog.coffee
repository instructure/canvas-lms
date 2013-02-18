define [
  'i18n!assignments'
  'Backbone'
  'jquery'
  'jst/assignments/AssignmentGroupCreateDialog'
  'jquery.toJSON'
  'jquery.instructure_forms'
  'jquery.disableWhileLoading'
  'compiled/jquery.rails_flash_notifications'
  'compiled/jquery/fixDialogButtons'
], (I18n, {View}, $, template) ->

  class AssignmentGroupCreateDialog extends View

    events:
      submit: 'createAssignmentGroup'
      'click .cancel-button': 'cancel'

    tagName: 'div'

    render: =>
      @$el.html template()
      @$el.dialog(
        title: I18n.t('titles.add_assignment_group', "Add Assignment Group"),
        width: 'auto'
        modal: true
      ).fixDialogButtons()
      this

    createAssignmentGroup: (event) =>
      event.preventDefault()
      event.stopPropagation()
      disablingDfd = new $.Deferred()
      @$el.disableWhileLoading disablingDfd
      $.ajaxJSON "/courses/#{ENV.CONTEXT_ID}/assignment_groups",
        'POST',
        @$el.find('form').toJSON(),
        (data) =>
          disablingDfd.resolve()
          @closeDialog()
          @trigger 'assignmentGroup:created', data.assignment_group

    cancel: =>
      @trigger 'assignmentGroup:canceled'
      @closeDialog()

    closeDialog: =>
      @$el.dialog 'close'
      @trigger 'close'

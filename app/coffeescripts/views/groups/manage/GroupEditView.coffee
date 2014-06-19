define [
  'i18n!groups'
  'underscore'
  'compiled/views/DialogFormView'
  'jst/groups/manage/groupEdit'
  'jst/EmptyDialogFormWrapper'
], (I18n, _, DialogFormView, template, wrapper) ->

  class GroupEditView extends DialogFormView

    @optionProperty 'groupCategory'

    defaults:
      width: 550
      title: I18n.t "edit_group", "Edit Group"

    template: template

    wrapperTemplate: wrapper

    className: 'dialogFormView group-edit-dialog form-horizontal form-dialog'

    events: _.extend {},
      DialogFormView::events
      'click .dialog_closer': 'close'

    translations:
      too_long: I18n.t "name_too_long", "Name is too long"

    validateFormData: (data, errors) ->
      if !$("[name=max_membership]")[0].validity.valid
        {"max_membership": [{message: I18n.t('max_membership_number', 'Max membership must be a number') }]}

    openAgain: ->
      super
      # reset the form contents
      @render()
      # auto-focus the first input
      @$('input:first').focus()

    toJSON: ->
      _.extend super,
        role: @groupCategory.get('role')

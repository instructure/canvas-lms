define [
  'i18n!groups'
  'underscore'
  'compiled/views/DialogFormView'
  'jst/groups/manage/groupEdit'
  'jst/EmptyDialogFormWrapper'
], (I18n, _, DialogFormView, template, wrapper) ->

  class GroupEditView extends DialogFormView

    @optionProperty 'groupCategory'
    @optionProperty 'student'

    defaults:
      width: 550
      title: I18n.t "edit_group", "Edit Group"

    els:
      '[name=max_membership]': '$maxMembership'

    template: template

    wrapperTemplate: wrapper

    className: 'dialogFormView group-edit-dialog form-horizontal form-dialog'

    attach: ->
      if @model
        @model.on('change', @refreshIfNameOnlyMode, this)

    refreshIfNameOnlyMode: ->
      if @options.nameOnly
        window.location.reload()


    events: _.extend {},
      DialogFormView::events
      'click .dialog_closer': 'close'

    translations:
      too_long: I18n.t "name_too_long", "Name is too long"

    validateFormData: (data, errors) ->
      if @$maxMembership.length > 0 and !@$maxMembership[0].validity.valid
        {"max_membership": [{message: I18n.t('max_membership_number', 'Max membership must be a number') }]}

    openAgain: ->
      super
      # reset the form contents
      @render()
      # auto-focus the first input
      @$('input:first').focus()

    toJSON: ->
      json = _.extend super,
        role: @groupCategory.get('role')
        nameOnly: @options.nameOnly
      json


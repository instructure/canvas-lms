define [
  'i18n!groups'
  'underscore'
  'compiled/views/DialogFormView'
  'jst/groups/manage/groupEdit'
  'jst/EmptyDialogFormWrapper'
], (I18n, _, DialogFormView, template, wrapper) ->

  class GroupEditView extends DialogFormView

    defaults:
      width: 550
      title: I18n.t "edit_group", "Edit Group"
      # Default to edit mode. Set to "false" for adding mode.
      editing: true

    template: template

    wrapperTemplate: wrapper

    className: 'dialogFormView group-edit-dialog form-horizontal form-dialog'

    events:
      _.extend {},
      DialogFormView::events,
      'click .dialog_closer': 'close'

    translations:
      too_long: I18n.t "name_too_long", "Name is too long"

    initialize: (options) ->
      super
      @options.title = I18n.t "add_group", "Add Group" if !@options.editing

    openAgain: ->
      super
      # reset the form contents
      @render()
      # auto-focus the first input
      @$el.find('input:first').focus()

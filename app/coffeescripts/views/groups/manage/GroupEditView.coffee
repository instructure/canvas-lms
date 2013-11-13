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
      # Default to edit mode. Set to "false" for adding mode.
      editing: true

    template: template

    wrapperTemplate: wrapper

    className: 'dialogFormView group-edit-dialog form-horizontal form-dialog'

    events: _.extend {},
      DialogFormView::events
      'click .dialog_closer': 'close'

    translations:
      too_long: I18n.t "name_too_long", "Name is too long"

    initialize: (options) ->
      super
      @options.title = I18n.t "add_group", "Add Group" if !@options.editing

    close: ->
      super
      # detach our custom handler from the bound element
      $(document).off 'keyup', @checkEsc
      # return focus using the closure from our parent view
      @options.focusReturnsTo?().focus()

    openAgain: ->
      super
      # reset the form contents
      @render()
      # auto-focus the first input
      @$el.find('input:first').focus()
      # attach a custom handler because the bound element is outside this view's scope
      $(document).on 'keyup', @checkEsc
      # override jQueryUI escKey handler to use our own
      @$el.dialog("option", "closeOnEscape", false)

    checkEsc: (e) =>
      @close() if e.keyCode is 27 # escape

    toJSON: ->
      json = super
      if groupCategory = @model.collection?.category
        json.role = groupCategory.get('role')
      else
        json.role = @groupCategory.get('role')
      json

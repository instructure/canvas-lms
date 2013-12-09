define [
  'i18n!groups'
  'compiled/views/DialogFormView'
  'jst/groups/manage/randomlyAssignMembers'
  'jst/EmptyDialogFormWrapper'
], (I18n, DialogFormView, template, wrapper) ->

  class RandomlyAssignMembersView extends DialogFormView

    defaults:
      title: I18n.t "randomly_assigning_members", "Randomly Assigning Students"
      width: 450
      height: 200

    template: template

    wrapperTemplate: wrapper

    className: 'form-dialog'

    events:
      'click .dialog_closer': 'close'
      'click .randomly-assign-members-confirm': 'randomlyAssignMembers'

    randomlyAssignMembers: (e) ->
      e.preventDefault()
      e.stopPropagation()
      @model.assignUnassignedMembers()
      @close()

    close: ->
      super
      # detach our custom handler from the bound element
      $(document).off 'keyup', @checkEsc
      # return focus using the closure from our parent view
      @options.focusReturnsTo?().focus()

    openAgain: ->
      super
      # attach a custom handler because the bound element is outside this view's scope
      $(document).on 'keyup', @checkEsc
      # override jQueryUI escKey handler to use our own
      @$el.dialog("option", "closeOnEscape", false)

    checkEsc: (e) =>
      @close() if e.keyCode is 27 # escape

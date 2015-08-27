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

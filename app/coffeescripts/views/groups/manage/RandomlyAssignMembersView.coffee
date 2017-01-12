define [
  'i18n!groups'
  'compiled/views/DialogFormView'
  'compiled/views/groups/manage/GroupCategoryCloneView'
  'jst/groups/manage/randomlyAssignMembers'
  'jst/EmptyDialogFormWrapper'
], (I18n, DialogFormView, GroupCategoryCloneView, template, wrapper) ->

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
      @close()

      groupHasSubmission = false
      for group in @model.groups().models
        if group.get('has_submission')
          groupHasSubmission = true
          break
      if groupHasSubmission
        @cloneCategoryView = new GroupCategoryCloneView
          model: @model
          openedFromCaution: true
        @cloneCategoryView.open()
        @cloneCategoryView.on "close", =>
          if @cloneCategoryView.cloneSuccess
            window.location.reload()
          else if @cloneCategoryView.changeGroups
            @model.assignUnassignedMembers()
      else
        @model.assignUnassignedMembers()

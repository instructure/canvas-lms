define [
  'i18n!groups'
  'underscore'
  'compiled/views/DialogFormView'
  'compiled/views/groups/manage/GroupCategoryCloneView'
  'jst/groups/manage/randomlyAssignMembers'
  'jst/EmptyDialogFormWrapper'
], (I18n, _, DialogFormView, GroupCategoryCloneView, template, wrapper) ->

  class RandomlyAssignMembersView extends DialogFormView

    defaults:
      title: I18n.t "randomly_assigning_members", "Randomly Assigning Students"
      width: 450
      height: 250

    template: template

    wrapperTemplate: wrapper

    className: 'form-dialog'

    events:
      'click .dialog_closer': 'close'
      'click .randomly-assign-members-confirm': 'randomlyAssignMembers'

    els:
      'input[name=group_by_section]': '$group_by_section'

    openAgain: =>
      super
      groups = @model.groups().models
      if _.any(groups, (group) -> group.usersCount() > 0 || !!group.get('max_membership'))
        @disableCheckbox(@$group_by_section, I18n.t("Cannot restrict by section unless groups are empty and not limited in size"))
      else if ENV.student_section_count && ENV.student_section_count > groups.length
        @disableCheckbox(@$group_by_section, I18n.t("Must have at least 1 group per section"))
      else
        @enableCheckbox(@$group_by_section)

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
        @model.assignUnassignedMembers(@getFormData().group_by_section == "1")

    disableCheckbox: (box, message) ->
      # shamelessly copypasted from assignments/EditView
      box.prop('checked', false).prop("disabled", true).parent().attr('data-tooltip', 'top').data('tooltip', {disabled: false}).attr('title', message)
      label = box.parent()
      @checkboxAccessibleAdvisory(box).text(message)

    enableCheckbox: (box) ->
      if box.prop("disabled")
        box.removeProp("disabled").parent().timeoutTooltip().timeoutTooltip('disable').removeAttr('data-tooltip').removeAttr('title')
        @checkboxAccessibleAdvisory(box).text('')

    checkboxAccessibleAdvisory: (box) ->
      label = box.parent()
      advisory = label.find('span.screenreader-only.accessible_label')
      advisory = $('<span class="screenreader-only accessible_label"></span>').appendTo(label) unless advisory.length
      advisory
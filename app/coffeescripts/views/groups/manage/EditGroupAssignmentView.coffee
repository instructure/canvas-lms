define [
  'jquery'
  'underscore'
  'i18n!EditGroupAssignmentView'
  'compiled/views/DialogFormView'
  'compiled/collections/GroupCollection'
  'jst/groups/manage/editGroupAssignment'
  'jst/EmptyDialogFormWrapper'
], ($, _, I18n, DialogFormView, GroupCollection, template, wrapper) ->

  class EditGroupAssignmentView extends DialogFormView

    @optionProperty 'group'

    els:
      '.single-select': '$singleSelectList'

    defaults:
      title: I18n.t "move_to", "Move To"
      width: 450
      height: 350

    template: template

    wrapperTemplate: wrapper

    className: 'form-dialog'

    events:
      'click .dialog_closer': 'close'
      'click .set-group': 'setGroup'

    openAgain: ->
      super
      # reset the form contents
      @render()
      # auto-focus the select element
      @$singleSelectList.focus()

    setGroup: (e) =>
      e.preventDefault()
      e.stopPropagation()
      targetGroup = @$('option:selected').val()
      if targetGroup then @group.collection.category.reassignUser(@model, @group.collection.get(targetGroup))
      @close()
      # focus override to the user's new group heading if they're moved
      $("[data-id='#{targetGroup}'] .group-heading")?.focus()

    getFilteredGroups: ->
      new GroupCollection @group.collection.filter (g) => g isnt @group

    toJSON: ->
      groupCollection = @getFilteredGroups()
      hasGroups = groupCollection.length > 0
      {
        allFull: hasGroups and groupCollection.models.every (g) -> g.isFull()
        groupId: @group.id
        userName: @model.get('name')
        groups: groupCollection.toJSON()
      }

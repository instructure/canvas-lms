define [
  'i18n!EditGroupAssignmentView'
  'compiled/views/DialogFormView'
  'compiled/collections/GroupCollection'
  'jst/groups/manage/editGroupAssignment'
  'jst/EmptyDialogFormWrapper'
], (I18n, DialogFormView, GroupCollection, template, wrapper) ->

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

    close: ->
      super
      # detach our custom handler from the bound element
      $(document).off 'keyup', @checkEsc
      # return focus using the element from our parent view
      @focusTarget?.focus()

    openAgain: ->
      super
      # reset the form contents
      @render()
      # auto-focus the select element
      @$singleSelectList.focus()
      # attach a custom handler because the bound element is outside this view's scope
      $(document).on 'keyup', @checkEsc
      # override jQueryUI escKey handler to use our own
      @$el.dialog("option", "closeOnEscape", false)

    checkEsc: (e) =>
      @close() if e.keyCode is 27 # escape

    setGroup: (e) =>
      e.preventDefault()
      e.stopPropagation()
      targetGroup = @$('option:selected').val()
      if targetGroup then @model.moveTo targetGroup
      @close()

    getFilteredGroups: ->
      new GroupCollection @collection.filter (g) => g isnt @group

    toJSON: ->
      groupCollection = @getFilteredGroups()
      hasGroups = groupCollection.length > 0
      {
        allFull: hasGroups && groupCollection.models.every (g) -> g.isFull()
        groupId: @group.get('id')
        userName: @model.get('name')
        groups: groupCollection.toJSON()
      }

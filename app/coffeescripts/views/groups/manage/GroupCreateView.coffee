define [
  'i18n!groups'
  'underscore'
  'compiled/views/groups/manage/GroupEditView'
], (I18n, _, GroupEditView) ->

  class GroupCreateView extends GroupEditView

    setFocusAfterError: ->
      @$('#groupEditSaveButton').focus()

    defaults: _.extend {},
      GroupEditView::defaults,
      title: I18n.t "add_group", "Add Group"

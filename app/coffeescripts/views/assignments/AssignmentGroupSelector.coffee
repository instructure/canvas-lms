define [
  'Backbone'
  'underscore'
  'jquery'
  'compiled/views/assignments/AssignmentGroupCreateDialog'
  'jst/assignments/AssignmentGroupSelector'
], (Backbone, _, $, AssignmentGroupCreateDialog, template) ->

  class AssignmentGroupSelector extends Backbone.View

    template: template

    ASSIGNMENT_GROUP_ID = '#assignment_group_id'

    els: do ->
      els = {}
      els["#{ASSIGNMENT_GROUP_ID}"] = '$assignmentGroupId'
      els

    events: do ->
      events = {}
      events["change #{ASSIGNMENT_GROUP_ID}"] = 'showAssignmentGroupCreateDialog'
      events

    @optionProperty 'parentModel'
    @optionProperty 'assignmentGroups'

    showAssignmentGroupCreateDialog: =>
      if @$assignmentGroupId.val() is 'new'
        @dialog = new AssignmentGroupCreateDialog().render()
        @dialog.on 'assignmentGroup:created', (group) =>
          $newGroup = $('<option>')
          $newGroup.val(group.id)
          $newGroup.text(group.name)
          @$assignmentGroupId.prepend $newGroup
          @$assignmentGroupId.val(group.id)
        @dialog.on 'assignmentGroup:canceled', =>
          @$assignmentGroupId.val(@assignmentGroups[0].id)

    toJSON: =>
      assignmentGroups: @assignmentGroups
      assignmentGroupId: @parentModel.assignmentGroupId()
      frozenAttributes: @parentModel.frozenAttributes()

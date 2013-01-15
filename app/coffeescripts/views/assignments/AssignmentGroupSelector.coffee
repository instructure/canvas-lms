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

    initialize: ->
      super
      @parentModel = @options.parentModel
      @assignmentGroups = @options.assignmentGroups

    events: do ->
      events = {}
      events[ "change #{ASSIGNMENT_GROUP_ID}" ] = 'showAssignmentGroupCreateDialog'
      events

    showAssignmentGroupCreateDialog: =>
      if @$assignmentGroupID.val() is 'new'
        @dialog = new AssignmentGroupCreateDialog().render()
        @dialog.on 'assignmentGroup:created', (group) =>
          $newGroup = $('<option>')
          $newGroup.val(group.id)
          $newGroup.text(group.name)
          @$assignmentGroupID.prepend $newGroup
          @$assignmentGroupID.val(group.id)
        @dialog.on 'assignmentGroup:canceled', =>
          @$assignmentGroupID.val(@assignmentGroups[0].id)

    render: =>
      super
      @_findElements()
      this

    toJSON: =>
      assignmentGroups: @assignmentGroups
      frozenAttributes: @parentModel.frozenAttributes()

    _findElements: =>
      @$assignmentGroupID = @find ASSIGNMENT_GROUP_ID

    find: ( selector ) => @$el.find selector

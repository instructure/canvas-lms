define [
  'Backbone'
  'jst/assignments/TeacherIndex'
], (Backbone, template) ->

  class TeacherIndexView extends Backbone.View

    template: template

    @child 'assignmentGroupsView', '[data-view=assignmentGroups]'

    @child 'inputFilterView', '[data-view=inputFilter]'

    @child 'createGroupView', '[data-view=createGroup]'

    @child 'createAssignmentView', '[data-view=createAssignment]'

    els:
      '#addGroup': '$addGroupButton'
      '#addAssignment': '$addAssignmentButton'

    afterRender: ->
      # child views so they get rendered automatically, need to stop it
      @createGroupView.hide()
      @createAssignmentView.hide()

define [
  'Backbone'
  'jst/assignments/TeacherIndex'
], (Backbone, template) ->

  class TeacherIndexView extends Backbone.View
    template: template
    el: '#content'

    @child 'assignmentGroupsView', '[data-view=assignmentGroups]'
    @child 'inputFilterView', '[data-view=inputFilter]'
    @child 'createGroupView', '[data-view=createGroup]'
    @child 'assignmentSettingsView', '[data-view=assignmentSettings]'

    els:
      '#addGroup': '$addGroupButton'
      '#assignmentSettingsCog': '$assignmentSettingsButton'

    afterRender: ->
      # child views so they get rendered automatically, need to stop it
      @createGroupView.hide()
      @assignmentSettingsView.hide()
      # its trigger would not be rendered yet, set it manually
      @assignmentSettingsView.setTrigger @$assignmentSettingsButton
      @createGroupView.setTrigger @$addGroupButton

define [
  'Backbone'
  'jst/assignments/IndexView'
], (Backbone, template) ->

  class IndexView extends Backbone.View

    template: template
    el: '#content'

    @child 'assignmentGroupsView', '[data-view=assignmentGroups]'
    @child 'inputFilterView', '[data-view=inputFilter]'
    @child 'createGroupView', '[data-view=createGroup]'
    @child 'assignmentSettingsView', '[data-view=assignmentSettings]'
    @child 'showByView', '[data-view=showBy]'

    els:
      '#addGroup': '$addGroupButton'
      '#assignmentSettingsCog': '$assignmentSettingsButton'

    afterRender: ->
      # need to hide child views and set trigger manually

      if @createGroupView
        @createGroupView.hide()
        @createGroupView.setTrigger @$addGroupButton

      if @assignmentSettingsView
        @assignmentSettingsView.hide()
        @assignmentSettingsView.setTrigger @$assignmentSettingsButton

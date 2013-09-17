define [
  'i18n!groups'
  'Backbone'
  'compiled/views/groups/manage/RandomlyAssignMembersView'
  'jst/groups/manage/groupCategoryDetail'
], (I18n, {View}, RandomlyAssignMembersView, template) ->

  class GroupCategoryDetailView extends View

    template: template

    els:
      '.randomly-assign-members': '$randomlyAssignMembersLink'

    initialize: (options) ->
      super
      @randomlyAssignUsersView = new RandomlyAssignMembersView
        model: options.model

    attach: ->
      @collection.on 'add remove reset', @render
      @collection.on 'remove', => @model.unassignedUsers().fetch()

    afterRender: ->
      # its trigger will not be rendered yet, set it manually
      @randomlyAssignUsersView.setTrigger @$randomlyAssignMembersLink

    toJSON: ->
      json = super
      json.groupCountText = I18n.t "group_count", {one: "1 group", other: "%{count} groups"}, count: @model.groupsCount()
      json.studentOrganizedOrSelfSignupRestricted = @model.get('role') is "student_organized" or @model.get('self_signup') is "restricted"
      json

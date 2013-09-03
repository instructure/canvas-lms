define [
  'underscore'
  'Backbone'
  'jst/assignments/IndexView'
  'jst/assignments/NoAssignmentsSearch'
], (_, Backbone, template, NoAssignments) ->

  class IndexView extends Backbone.View

    template: template
    el: '#content'

    @child 'assignmentGroupsView', '[data-view=assignmentGroups]'
    @child 'createGroupView', '[data-view=createGroup]'
    @child 'assignmentSettingsView', '[data-view=assignmentSettings]'
    @child 'showByView', '[data-view=showBy]'

    events:
      'keyup #search_term': 'search'

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

    search: _.debounce ->
      @filterResults()
    , 200

    filterResults: =>
      term = $('#search_term').val()
      if term == ""
        #show all
        @collection.each (group) =>
          group.groupView.endSearch()

        #remove noAssignments placeholder
        if @noAssignments?
          @noAssignments.remove()
          @noAssignments = null
      else
        regex = new RegExp(@cleanSearchTerm(term), 'ig')
        #search
        atleastoneGroup = false
        @collection.each (group) =>
          atleastoneGroup = true if group.groupView.search(regex)

        #add noAssignments placeholder
        if !atleastoneGroup
          unless @noAssignments
            @noAssignments = new Backbone.View
              template: NoAssignments
              tagName: "li"
              className: "item-group-condensed"
            ul = @assignmentGroupsView.$el.children(".collectionViewItems")
            ul.append(@noAssignments.render().el)
        else
          #remove noAssignments placeholder
          if @noAssignments?
            @noAssignments.remove()
            @noAssignments = null

    cleanSearchTerm: (text) ->
      text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
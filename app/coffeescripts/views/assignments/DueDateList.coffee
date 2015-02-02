define [
  'Backbone'
  'underscore'
  'compiled/views/assignments/DueDateView' # Single DueDateItem
  'compiled/views/assignments/SectionDropdownView' # Dropdown for a section
], (Backbone, _, DueDateView, SectionDropdownView) ->

  # Class Summary
  #   Manage showing and updating a list of due dates.
  #   DueDates are represented as AssignmentOverrides 
  #   so this takes a list of AssignmentOverrrides.
  class DueDateList extends Backbone.View

    initialize: (options) ->
      super
      @dueDateList = @model
      @dueDateViews = []
      @dueDateList.overrides.forEach (override) =>
        @addDueDateView override, false
      @dueDateList.overrides.on 'add', @addDueDateView
      @dueDateList.overrides.on 'change:course_section_id', @reRenderSections

    _removeDueDateView: (override) =>
      @dueDateViews = _.reject @dueDateViews, ( dueDateView ) ->
        dueDateView.model == override
      @dueDateList.overrides.remove override
      override.off()
      @reRenderSections()
      @hideOrShowRemoveButtons()
      @trigger 'remove:override'

    reRenderSections: =>
      _.each @dueDateViews, (dueDateView) =>
        dueDateView.reRenderSections @dueDateList
          .availableSectionsPlusOverride( dueDateView.model )

    updateOverrides: =>
      _.each @dueDateViews, (dueDateView) -> dueDateView.updateOverride()

    validateBeforeSave: (data, errors) =>
      for override in (data.assignment_overrides || [] )
        @dueDateViews[0].validateBeforeSave(override,errors)
      errors

    afterRender: =>
      _.each @dueDateViews, (view) =>
        @$el.append view.render().el
      @hideOrShowRemoveButtons()

    hideOrShowRemoveButtons: =>
      firstDueDateView = @dueDateViews[0]
      if firstDueDateView?
        if @dueDateViews.length > 1
          firstDueDateView.showRemoveButton()
        else
          firstDueDateView.hideRemoveButton()

    _generateDueDateView: ( assignmentOverride ) ->
      new DueDateView
        model: assignmentOverride
        views:
          'section-list' : new SectionDropdownView
            sections:
              @dueDateList.availableSectionsPlusOverride(assignmentOverride)
            override: assignmentOverride

    getOverrides: => @overrides.toJSON()

    addDueDateView: ( assignmentOverride, render = true ) =>
      dueDateView = @_generateDueDateView assignmentOverride
      dueDateView.on 'remove', @_removeDueDateView
      @dueDateViews.push dueDateView
      @hideOrShowRemoveButtons()
      if render
        $row = dueDateView.render().$el
        @$el.append $row
        @reRenderSections()
        $row.find(".section-list").focus()

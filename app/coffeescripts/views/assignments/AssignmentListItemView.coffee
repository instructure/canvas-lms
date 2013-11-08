define [
  'i18n!assignments'
  'Backbone'
  'underscore'
  'compiled/views/PublishIconView'
  'compiled/views/assignments/DateDueColumnView'
  'compiled/views/assignments/DateAvailableColumnView'
  'compiled/views/assignments/CreateAssignmentView'
  'compiled/views/MoveDialogView'
  'compiled/fn/preventDefault'
  'jst/assignments/AssignmentListItem'
  'jst/assignments/_assignmentListItemScore'
  'compiled/util/round'
  'jqueryui/tooltip'
  'compiled/behaviors/tooltip'
], (I18n, Backbone, _, PublishIconView, DateDueColumnView, DateAvailableColumnView, CreateAssignmentView, MoveDialogView, preventDefault, template, scoreTemplate, round) ->

  class AssignmentListItemView extends Backbone.View
    tagName: "li"
    className: "assignment"
    template: template

    @child 'publishIconView',         '[data-view=publish-icon]'
    @child 'dateDueColumnView',       '[data-view=date-due]'
    @child 'dateAvailableColumnView', '[data-view=date-available]'
    @child 'editAssignmentView',      '[data-view=edit-assignment]'
    @child 'moveAssignmentView', '[data-view=moveAssignment]'

    els:
      '.edit_assignment': '$editAssignmentButton'
      '.move_assignment': '$moveAssignmentButton'

    events:
      'click .delete_assignment': 'onDelete'
      'click .tooltip_link': preventDefault ->

    messages:
      confirm: I18n.t('confirms.delete_assignment', 'Are you sure you want to delete this assignment?')
      ag_move_label: I18n.beforeLabel 'assignment_group_move_label', 'Assignment Group'

    initialize: ->
      super
      @initializeChildViews()

      # we need the following line in order to access this view later
      @model.assignmentView = @

      @model.on('change:hidden', @toggleHidden)

      if @canManage()
        @model.on('change:published', @updatePublishState)

        # re-render for attributes we are showing
        attrs = ["name", "points_possible", "due_at", "lock_at", "unlock_at", "modules"]
        observe = _.map(attrs, (attr) -> "change:#{attr}").join(" ")
        @model.on(observe, @render)
      @model.on 'change:submission', @updateScore

    initializeChildViews: ->
      @publishIconView    = false
      @editAssignmentView = false
      @vddDueColumnView   = false
      @dateAvailableColumnView = false
      @moveAssignmentView = false

      if @canManage()
        @publishIconView    = new PublishIconView(model: @model)
        @editAssignmentView = new CreateAssignmentView(model: @model)
        @moveAssignmentView = new MoveDialogView
          model: @model
          nested: true
          parentCollection: @model.collection.view?.parentCollection
          parentLabelText: @messages.ag_move_label
          parentKey: 'assignment_group_id'
          childKey: 'assignments'
          saveURL: -> "#{ENV.URLS.assignment_sort_base_url}/#{@parentListView.value()}/reorder"

      @dateDueColumnView       = new DateDueColumnView(model: @model)
      @dateAvailableColumnView = new DateAvailableColumnView(model: @model)

    updatePublishState: =>
      @$('.ig-row').toggleClass('ig-published', @model.get('published'))

    # call remove on children so that they can clean up old dialogs.
    render: ->
      @toggleHidden(@model, @model.get('hidden'))
      @publishIconView.remove()         if @publishIconView
      @editAssignmentView.remove()      if @editAssignmentView
      @dateDueColumnView.remove()       if @dateDueColumnView
      @dateAvailableColumnView.remove() if @dateAvailableColumnView
      @moveAssignmentView.remove() if @moveAssignmentView

      super
      # reset the model's view property; it got overwritten by child views
      @model.view = this if @model

    afterRender: ->
      @createModuleToolTip()

      if @editAssignmentView
        @editAssignmentView.hide()
        @editAssignmentView.setTrigger @$editAssignmentButton

      if @moveAssignmentView
        @moveAssignmentView.hide()
        @moveAssignmentView.setTrigger @$moveAssignmentButton

      @updateScore() unless @canManage()

    toggleHidden: (model, hidden) =>
      @$el.toggleClass('hidden', hidden)
      @$el.toggleClass('search_show', !hidden)

    createModuleToolTip: =>
      link = @$el.find('.tooltip_link')
      if link.length > 0
        link.tooltip
          position:
            my: 'center bottom'
            at: 'center top-10'
            collision: 'fit fit'
          tooltipClass: 'center bottom vertical'
          content: ->
            $(link.data('tooltipSelector')).html()

    toJSON: ->
      data = @model.toView()
      data.canManage = @canManage()
      data = @_setJSONForGrade(data) unless data.canManage

      # can move items if there's more than one parent
      # collection OR more than one in the model's collection
      data.canMove = @model.collection.view?.parentCollection?.length > 1 or @model.collection.length > 1

      if data.canManage
        data.spanWidth      = 'span3'
        data.alignTextClass = ''
      else
        data.spanWidth      = 'span4'
        data.alignTextClass = 'align-right'

      if modules = @model.get('modules')
        moduleName = modules[0]
        has_modules = modules.length > 0
        joinedNames = modules.join(",")
        _.extend data, {
          modules: modules
          module_count: modules.length
          module_name: moduleName
          has_modules: has_modules
          joined_names: joinedNames
        }
      else
        data

    onDelete: (e) =>
      e.preventDefault()
      @delete() if confirm(@messages.confirm)

    delete: ->
      @model.destroy()
      @$el.remove()

    canManage: ->
      ENV.PERMISSIONS.manage

    _setJSONForGrade: (json) ->
      if submission = @model.get('submission')
        submissionJSON = submission.toJSON()
        grade = submission.get('grade')
        if typeof grade is 'number' && !isNaN(grade)
          submissionJSON.grade = round grade, round.DEFAULT
        json.submission = submissionJSON
      pointsPossible = json.pointsPossible

      if typeof pointsPossible is 'number' && !isNaN(pointsPossible)
        json.pointsPossible = round pointsPossible, round.DEFAULT
        json.submission.pointsPossible = json.pointsPossible if json.submission?

      json

    updateScore: =>
      json = @model.toView()
      json = @_setJSONForGrade(json) unless @canManage()

      @$('.js-score').html scoreTemplate(json)

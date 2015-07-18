define [
  'i18n!assignments'
  'Backbone'
  'jquery'
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
  'compiled/views/assignments/AssignmentKeyBindingsMixin'
  'jqueryui/tooltip'
  'compiled/behaviors/tooltip'
  'compiled/jquery.rails_flash_notifications'
], (I18n, Backbone, $, _, PublishIconView, DateDueColumnView, DateAvailableColumnView, CreateAssignmentView, MoveDialogView, preventDefault, template, scoreTemplate, round, AssignmentKeyBindingsMixin) ->

  class AssignmentListItemView extends Backbone.View
    @mixin AssignmentKeyBindingsMixin
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
      'keydown': 'handleKeys'

    messages:
      confirm: I18n.t('confirms.delete_assignment', 'Are you sure you want to delete this assignment?')
      ag_move_label: I18n.beforeLabel I18n.t('labels.assignment_group_move_label', 'Assignment Group')

    initialize: ->
      super
      @initializeChildViews()

      # we need the following line in order to access this view later
      @model.assignmentView = @

      @model.on('change:hidden', @toggleHidden)

      if @canManage()
        @model.on('change:published', @updatePublishState)

        # re-render for attributes we are showing
        attrs = ["name", "points_possible", "due_at", "lock_at", "unlock_at", "modules", "published"]
        observe = _.map(attrs, (attr) -> "change:#{attr}").join(" ")
        @model.on(observe, @render)
      @model.on 'change:submission', @updateScore

    initializeChildViews: ->
      @publishIconView    = false
      @editAssignmentView = false
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
          closeTarget: @$el.find('a[id*=manage_link]')
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

      @updateScore() if @canReadGrades()

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

      if @model.isQuiz()
        data.menu_tools = ENV.quiz_menu_tools
        _.each data.menu_tools, (tool) =>
          tool.url = tool.base_url + "&quizzes[]=#{@model.get("quiz_id")}"
      else if @model.isDiscussionTopic()
        data.menu_tools = ENV.discussion_topic_menu_tools
        _.each data.menu_tools, (tool) =>
          tool.url = tool.base_url + "&discussion_topics[]=#{@model.get("discussion_topic")?.id}"
      else
        data.menu_tools = ENV.assignment_menu_tools
        _.each data.menu_tools, (tool) =>
          tool.url = tool.base_url + "&assignments[]=#{@model.get("id")}"

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
      return @$el.find('a[id*=manage_link]').focus() unless confirm(@messages.confirm)
      if @previousAssignmentInGroup()?
        @focusOnAssignment(@previousAssignmentInGroup())
        @delete()
      else
        id = @model.attributes.assignment_group_id
        @delete()
        @focusOnGroupByID(id)

    delete: ->
      @model.destroy success: =>
        $.screenReaderFlashMessage(I18n.t('Assignment was deleted'))
      @$el.remove()

    canManage: ->
      ENV.PERMISSIONS.manage

    gradeStrings: (grade) ->
      pass_fail_map =
        incomplete:
          I18n.t 'incomplete', 'Incomplete'
        complete:
          I18n.t 'complete', 'Complete'

      grade = pass_fail_map[grade] or grade

      'percent':
        nonscreenreader: I18n.t 'grade_percent', '%{grade}%', grade: grade
        screenreader: I18n.t 'grade_percent_screenreader', 'Grade: %{grade}%', grade: grade
      'pass_fail':
        nonscreenreader: "#{grade}"
        screenreader: I18n.t 'grade_pass_fail_screenreader', 'Grade: %{grade}', grade: grade
      'letter_grade':
        nonscreenreader: "#{grade}"
        screenreader: I18n.t 'grade_letter_grade_screenreader', 'Grade: %{grade}', grade: grade
      'gpa_scale':
        nonscreenreader: "#{grade}"
        screenreader: I18n.t 'grade_gpa_scale_screenreader', 'Grade: %{grade}', grade: grade


    _setJSONForGrade: (json) ->
      if submission = @model.get('submission')
        submissionJSON = if submission.present then submission.present() else submission.toJSON()
        score = submission.get('score')
        if typeof score is 'number' && !isNaN(score)
          submissionJSON.score = round score, round.DEFAULT
        json.submission = submissionJSON
        grade = submission.get('grade')
        gradeString = @gradeStrings(grade)[json.gradingType]
        json.submission.gradeDisplay = gradeString?.nonscreenreader
        json.submission.gradeDisplayForScreenreader = gradeString?.screenreader

      pointsPossible = json.pointsPossible

      if typeof pointsPossible is 'number' && !isNaN(pointsPossible)
        json.pointsPossible = round pointsPossible, round.DEFAULT
        json.submission.pointsPossible = json.pointsPossible if json.submission?

      json.submission.gradingType = json.gradingType if json.submission?

      if json.gradingType is 'not_graded'
        json.hideGrade = true
      json

    updateScore: =>
      json = @model.toView()
      json = @_setJSONForGrade(json) unless @canManage()
      @$('.js-score').html scoreTemplate(json)

    canReadGrades: ->
      ENV.PERMISSIONS.read_grades

    goToNextItem: =>
      if @nextAssignmentInGroup()?
        @focusOnAssignment(@nextAssignmentInGroup())
      else if @nextVisibleGroup()?
        @focusOnGroup(@nextVisibleGroup())
      else
        @focusOnFirstGroup()

    goToPrevItem: =>
      if @previousAssignmentInGroup()?
        @focusOnAssignment(@previousAssignmentInGroup())
      else
        @focusOnGroupByID(@model.attributes.assignment_group_id)

    editItem: =>
      @$("#assignment_#{@model.id}_settings_edit_item").click()

    deleteItem: =>
      @$("#assignment_#{@model.id}_settings_delete_item").click()

    addItem: =>
      group_id = @model.attributes.assignment_group_id
      $(".add_assignment", "#assignment_group_#{group_id}").click()

    showAssignment: =>
      $(".ig-title", "#assignment_#{@model.id}")[0].click()

    assignmentGroupView: =>
      @model.collection.view

    visibleAssignments: =>
      @assignmentGroupView().visibleAssignments()

    nextVisibleGroup: =>
      @assignmentGroupView().nextGroup()

    nextAssignmentInGroup: =>
      current_assignment_index = @visibleAssignments().indexOf(@model)
      @visibleAssignments()[current_assignment_index + 1]

    previousAssignmentInGroup: =>
      current_assignment_index = @visibleAssignments().indexOf(@model)
      @visibleAssignments()[current_assignment_index - 1]

    focusOnAssignment: (assignment) =>
      $("#assignment_#{assignment.id}").attr("tabindex",-1).focus()

    focusOnGroup: (group) =>
      $("#assignment_group_#{group.attributes.id}").attr("tabindex",-1).focus()

    focusOnGroupByID: (group_id) =>
      $("#assignment_group_#{group_id}").attr("tabindex",-1).focus()

    focusOnFirstGroup: =>
      $(".assignment_group").filter(":visible").first().attr("tabindex",-1).focus()

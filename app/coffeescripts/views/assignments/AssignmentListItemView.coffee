define [
  'i18n!assignments'
  'Backbone'
  'jquery'
  'underscore'
  'jsx/shared/conditional_release/CyoeHelper'
  'compiled/views/PublishIconView'
  'compiled/views/assignments/DateDueColumnView'
  'compiled/views/assignments/DateAvailableColumnView'
  'compiled/views/assignments/CreateAssignmentView'
  'compiled/views/SisButtonView'
  'compiled/views/MoveDialogView'
  'compiled/fn/preventDefault'
  'jst/assignments/AssignmentListItem'
  'jst/assignments/_assignmentListItemScore'
  'compiled/util/round'
  'compiled/views/assignments/AssignmentKeyBindingsMixin'
  'jqueryui/tooltip'
  'compiled/behaviors/tooltip'
  'compiled/jquery.rails_flash_notifications'
], (I18n, Backbone, $, _, CyoeHelper, PublishIconView, DateDueColumnView, DateAvailableColumnView, CreateAssignmentView, SisButtonView, MoveDialogView, preventDefault, template, scoreTemplate, round, AssignmentKeyBindingsMixin) ->

  class AssignmentListItemView extends Backbone.View
    @mixin AssignmentKeyBindingsMixin
    @optionProperty 'userIsAdmin'

    tagName: "li"
    className: ->
      "assignment#{if @canMove() then '' else ' sort-disabled'}"
    template: template

    @child 'publishIconView',         '[data-view=publish-icon]'
    @child 'dateDueColumnView',       '[data-view=date-due]'
    @child 'dateAvailableColumnView', '[data-view=date-available]'
    @child 'editAssignmentView',      '[data-view=edit-assignment]'
    @child 'sisButtonView',           '[data-view=sis-button]'
    @child 'moveAssignmentView',      '[data-view=moveAssignment]'

    els:
      '.edit_assignment': '$editAssignmentButton'
      '.move_assignment': '$moveAssignmentButton'

    events:
      'click .delete_assignment': 'onDelete'
      'click .tooltip_link': preventDefault ->
      'keydown': 'handleKeys'
      'mousedown': 'stopMoveIfProtected'

    messages:
      confirm: I18n.t('Are you sure you want to delete this assignment?')
      ag_move_label: I18n.beforeLabel I18n.t('Assignment Group')

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
      @sisButtonView = false
      @editAssignmentView = false
      @dateAvailableColumnView = false
      @moveAssignmentView = false

      if @canManage()
        @publishIconView    = new PublishIconView({
          model: @model,
          publishText: I18n.t("Unpublished. Click to publish %{name}", name: @model.get('name')),
          unpublishText: I18n.t("Published. Click to unpublish %{name}", name: @model.get('name'))
        })
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

        if @isGraded() && @model.postToSISEnabled()
          @sisButtonView = new SisButtonView(model: @model)

      @dateDueColumnView       = new DateDueColumnView(model: @model)
      @dateAvailableColumnView = new DateAvailableColumnView(model: @model)

    updatePublishState: =>
      @$('.ig-row').toggleClass('ig-published', @model.get('published'))

    # call remove on children so that they can clean up old dialogs.
    render: ->
      @toggleHidden(@model, @model.get('hidden'))
      @publishIconView.remove()         if @publishIconView
      @sisButtonView.remove()           if @sisButtonView
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
        if @canMove()
          @moveAssignmentView.setTrigger @$moveAssignmentButton

      @updateScore() if @canReadGrades()

    toggleHidden: (model, hidden) =>
      @$el.toggleClass('hidden', hidden)
      @$el.toggleClass('search_show', !hidden)

    stopMoveIfProtected: (e) ->
      e.stopPropagation() unless @canMove()

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

      data.canMove = @canMove()
      data.canDelete = @canDelete()
      data.showAvailability = @model.multipleDueDates() or not @model.defaultDates().available()
      data.showDueDate = @model.multipleDueDates() or @model.singleSectionDueDate()

      data.cyoe = CyoeHelper.getItemData(data.id, @isGraded() && (!@model.isQuiz() || data.is_quiz_assignment))
      data.return_to = encodeURIComponent window.location.pathname

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
      return unless @canDelete()
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

    canDelete: ->
      @userIsAdmin or @model.canDelete()

    canMove: ->
      @userIsAdmin or (@canManage() and @model.canMove())

    canManage: ->
      ENV.PERMISSIONS.manage

    isGraded: ->
      submission_types = @model.get('submission_types')
      submission_types && !submission_types.includes('not_graded') && !submission_types.includes('wiki_page')

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

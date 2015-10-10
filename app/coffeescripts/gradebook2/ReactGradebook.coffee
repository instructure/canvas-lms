define [
  'react'
  'compiled/util/round'
  'compiled/views/InputFilterView'
  'i18n!gradebook2'
  'compiled/gradebook2/GRADEBOOK_TRANSLATIONS'
  'jquery'
  'underscore'
  'compiled/userSettings'
  'vendor/spin'
  'str/htmlEscape'
  # 'compiled/gradebook2/PostGradesDialog'
  'jsx/gradebook/SISGradePassback/PostGradesStore'
  'jsx/gradebook/SISGradePassback/PostGradesApp'
  'jst/gradebook2/column_header'
  'compiled/views/gradebook/SectionMenuView'
  'compiled/views/gradebook/GradingPeriodMenuView'
  'jsx/gradebook/grid/constants'
  'jsx/gradebook/grid/actions/gradebookToolbarActions'
  'jsx/gradebook/grid/actions/studentEnrollmentsActions'
  'jsx/gradebook/grid/stores/assignmentGroupsStore'
  'jsx/gradebook/grid/actions/assignmentGroupsActions'
  'jst/_avatar' #needed by row_student_name
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jqueryui/dialog'
  'jqueryui/tooltip'
  'compiled/behaviors/tooltip'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'jqueryui/mouse'
  'jqueryui/position'
  'jqueryui/sortable'
  'compiled/jquery.kylemenu'
  'compiled/jquery/fixDialogButtons'
], (React, round, InputFilterView, I18n, GRADEBOOK_TRANSLATIONS, $, _,
  userSettings, Spinner, htmlEscape, PostGradesStore, PostGradesApp,
  columnHeaderTemplate, SectionMenuView, GradingPeriodMenuView,
  GradebookConstants, GradebookToolbarActions, StudentEnrollmentsActions,
  AssignmentGroupsStore, AssignmentGroupActions) ->

  class Gradebook
    constructor: (@options) ->
      @initGradingPeriods()
      @initPostGradesStore()
      @showPostGradesButton()
      @initSettingsDropdown()
      @initHeader()
      @attachSearchBarEventHandlers()
      @attachSetWeightsDialogHandlers()

    initGradingPeriods: ->
      @gradingPeriods = ENV.GRADEBOOK_OPTIONS.active_grading_periods

    initPostGradesStore: ->
      @postGradesStore = PostGradesStore
        course:
          id:     @options.context_id
          sis_id: @options.context_sis_id

      @postGradesStore.setSelectedSection @sectionToShow

    showPostGradesButton: ->
      app = new PostGradesApp store: @postGradesStore
      $placeholder = $('.post-grades-placeholder')
      if ($placeholder.length > 0)
        React.renderComponent(app, $placeholder[0])

    initSettingsDropdown: () ->
      preferences = @getInitialToolbarPreferences()
      @initCheckboxes(preferences)
      @initStudentNamesOption(preferences)
      @initArrangeByOption(preferences)
      @initNotesColumnOption(preferences)
      @attachSettingsDropdownEventHandlers(preferences)

    getInitialToolbarPreferences: () ->
      storedSortOrder = @options.gradebook_column_order_settings ||
        { sortType: 'assignment_group' }
      savedPreferences =
        hideStudentNames: userSettings.contextGet('hideStudentNames')
        hideNotesColumn: !@options.teacher_notes || @options.teacher_notes.hidden
        showAttendanceColumns: userSettings.contextGet('showAttendanceColumns')
        showConcludedEnrollments: userSettings.contextGet('showConcludedEnrollments')
        arrangeBy: storedSortOrder.sortType
      _.defaults(savedPreferences, GradebookConstants.DEFAULT_TOOLBAR_PREFERENCES)

    initCheckboxes: (preferences) ->
      $('#show_attendance').prop('checked', preferences.showAttendanceColumns)
      $('#show_concluded_enrollments').prop('checked', preferences.showConcludedEnrollments)

    initStudentNamesOption: (preferences) ->
      namesHidden = preferences.hideStudentNames
      if namesHidden then $('#student_names_toggle').addClass('hide_students')
      displayText = if namesHidden then I18n.t('Show Student Names') else I18n.t('Hide Student Names')
      $('#student_names_toggle').text(displayText)

    initArrangeByOption: (preferences) ->
      $arrangeBy = $('#arrange_by_toggle')
      if preferences.arrangeBy == 'due_date'
        arrangeByData = 'due_date'
        displayText = I18n.t('Arrange Columns by Assignment Group')
      else
        arrangeByData = 'assignment_group'
        displayText = I18n.t('Arrange Columns by Due Date')

      $arrangeBy.data('arrange_by', arrangeByData)
      $arrangeBy.text(displayText)

    initNotesColumnOption: (preferences) ->
      notesHidden = preferences.hideNotesColumn
      if notesHidden then $('#notes_toggle').addClass('hide_notes')
      displayText = if notesHidden then I18n.t('Show Notes Column') else I18n.t('Hide Notes Column')
      $('#notes_toggle').text(displayText)

    attachSettingsDropdownEventHandlers: () ->
      $('#student_names_toggle').click(@studentNamesToggle)
      $('#arrange_by_toggle').click(@arrangeByToggle)
      $('#notes_toggle').click(@notesToggle)
      $('#show_attendance').change -> GradebookToolbarActions.toggleShowAttendanceColumns(@checked)
      $('#show_concluded_enrollments').change(@concludedEnrollmentsChange)

    attachSetWeightsDialogHandlers: () ->
      $.subscribe('assignment_group_weights_changed', @updateAssignmentGroupWeights)
      $('#set-group-weights').click @openSetAssignmentGroupWeightsDialog

    updateAssignmentGroupWeights: (options) ->
      AssignmentGroupActions.replaceAssignmentGroups(options.assignmentGroups)

    openSetAssignmentGroupWeightsDialog: () =>
      assignmentGroups = AssignmentGroupsStore.assignmentGroups.data
      params =
        context: @options
        assignmentGroups: assignmentGroups
      new AssignmentGroupWeightsDialog params

    attachSearchBarEventHandlers: () ->
      $('.gradebook_filter').keyup ->
        searchTerm = $('#gradebook-filter-input').val()
        StudentEnrollmentsActions.search(searchTerm)

    studentNamesToggle: (event) =>
      event.preventDefault()
      $studentNames = $(event.target)
      $studentNames.toggleClass('hide_students')
      hideStudents = $studentNames.hasClass('hide_students')
      displayText = if hideStudents then I18n.t('Show Student Names') else I18n.t('Hide Student Names')

      $studentNames.text(displayText)
      GradebookToolbarActions.toggleStudentNames(hideStudents)

    arrangeByToggle: (event) =>
      event.preventDefault()
      $arrangeBy = $(event.target)
      if $arrangeBy.data('arrange_by') == 'due_date'
        arrangeByData = 'assignment_group'
        displayText = I18n.t('Arrange Columns by Due Date')
      else
        arrangeByData = 'due_date'
        displayText = I18n.t('Arrange Columns by Assignment Group')

      $arrangeBy.data('arrange_by', arrangeByData)
      $arrangeBy.text(displayText)
      GradebookToolbarActions.arrangeColumnsBy(arrangeByData)

    notesToggle: (event) =>
      event.preventDefault()
      $notes = $(event.target)
      $notes.toggleClass('hide_notes')
      hideNotesColumn = $notes.hasClass('hide_notes')
      displayText = if hideNotesColumn then I18n.t('Show Notes Column') else I18n.t('Hide Notes Column')

      $notes.text(displayText)
      GradebookToolbarActions.toggleNotesColumn(hideNotesColumn)

    concludedEnrollmentsChange: () =>
      $showConcludedEnrollments = $('#show_concluded_enrollments')
      if @options.course_is_concluded
        $showConcludedEnrollments.prop('checked', true)
        return alert(I18n.t 'This is a concluded course, so only concluded enrollments are available.')
      userSettings.contextSet 'showConcludedEnrollments', $showConcludedEnrollments.prop('checked')
      StudentEnrollmentsActions.load()

    initHeader: ->
      @gradingPeriodToShow = @getGradingPeriodToShow()
      @drawSectionSelectButton() if @sections_enabled || @course
      @drawGradingPeriodSelectButton() if @options.multiple_grading_periods_enabled
      # don't show the "show attendance" link in the dropdown if there's no attendance assignments
      unless (_.detect @assignments, (a) -> (''+a.submission_types) == 'attendance')
        $('#show_attendance').closest('li').hide()

      $('#gradebook_settings').kyleMenu()
      $('#download_csv').kyleMenu()

    drawSectionSelectButton: () ->
      @sectionMenu = new SectionMenuView(
        el: $('.section-button-placeholder'),
        sections: @sectionList(),
        course: @course,
        showSections: @showSections(),
        showSisSync: @options.post_grades_feature_enabled,
        currentSection: @sectionToShow)
      @sectionMenu.render()

    drawGradingPeriodSelectButton: () ->
      @gradingPeriodMenu = new GradingPeriodMenuView(
        el: $('.multiple-grading-periods-selector-placeholder'),
        periods: @gradingPeriodList(),
        currentGradingPeriod: @gradingPeriodToShow)
      @gradingPeriodMenu.render()

    gradingPeriodList: ->
      _.map @options.active_grading_periods, (period) =>
        { title: period.title, id: period.id, checked: @gradingPeriodToShow == period.id }

    getGradingPeriodToShow: () ->
      currentPeriodId = userSettings.contextGet('gradebook_current_grading_period')

      if currentPeriodId && (@isAllGradingPeriods(currentPeriodId) || @gradingPeriodIsActive(currentPeriodId))
        currentPeriodId
      else
        ENV.GRADEBOOK_OPTIONS.current_grading_period_id

    isAllGradingPeriods: (currentPeriodId) ->
      currentPeriodId == "0"

    gradingPeriodIsActive: (gradingPeriodId) ->
      activePeriodIds = _.pluck(@gradingPeriods, 'id')
      _.contains(activePeriodIds, gradingPeriodId)

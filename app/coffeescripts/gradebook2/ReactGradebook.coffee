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
  'compiled/gradebook2/AssignmentGroupWeightsDialog'
  'jsx/gradebook/grid/stores/sectionsStore'
  'jsx/gradebook/grid/actions/sectionsActions'
  'jsx/gradebook/grid/actions/tableActions'
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
  'vendor/jquery.ba-tinypubsub'
], (React, round, InputFilterView, I18n, GRADEBOOK_TRANSLATIONS, $, _,
  userSettings, Spinner, htmlEscape, PostGradesStore, PostGradesApp,
  columnHeaderTemplate, SectionMenuView, GradingPeriodMenuView,
  GradebookConstants, GradebookToolbarActions, StudentEnrollmentsActions,
  AssignmentGroupsStore, AssignmentGroupActions, AssignmentGroupWeightsDialog,
  SectionsStore, SectionsActions, TableActions) ->

  class Gradebook
    constructor: (@options) ->
      @initGradingPeriods()
      @initSections()
      @initPostGradesStore()
      @showPostGradesButton()
      @initSettingsDropdown()
      @initHeader()
      @attachSearchBarEventHandlers()
      @attachSetWeightsDialogHandlers()

    initGradingPeriods: ->
      @gradingPeriods = @options.active_grading_periods

    initSections: ->
      @sections = {}
      $.subscribe 'currentSection/change', @onSectionChange
      SectionsStore.listen (sectionStoreData) =>
        sections = sectionStoreData.sections
        @sectionToShow = sectionStoreData.selected
        @sections = {}
        if (sections != null && sections != undefined)
          for section in sections
            htmlEscape(section)
            @sections[section.id] = section

          if sections.length > 2 # 2 because a filler "All sections" is inserted
            @drawSectionSelectButton(@sections)


    onSectionChange: (section) ->
      TableActions.enterLoadingState()
      SectionsActions.selectSection(section)
      @sectionToShow = section
      if @sectionToShow
        userSettings.contextSet('grading_show_only_section', @sectionToShow)
      else
        userSettings.contextRemove('grading_show_only_section', @sectionToShow)

    initPostGradesStore: ->
      @postGradesStore = PostGradesStore
        course:
          id:     @options.context_id
          sis_id: @options.context_sis_id

      @postGradesStore.setSelectedSection @sectionToShow

    showPostGradesButton: ->
      app = React.createElement(PostGradesApp, store: @postGradesStore)
      $placeholder = $('.post-grades-placeholder')
      if ($placeholder.length > 0)
        React.render(app, $placeholder[0])

    initSettingsDropdown: () ->
      preferences = @getInitialToolbarPreferences()
      @initCheckboxes(preferences)
      @initStudentNamesOption(preferences)
      @initArrangeByOption(preferences)
      @initNotesColumnOption(preferences)
      @attachSettingsDropdownEventHandlers(preferences)

    sectionList: ->
      _.map @sections, (section, id) =>
        if(section.passback_status)
          date = new Date(section.passback_status.sis_post_grades_status.grades_posted_at)
        { name: section.name, id: id, passback_status: section.passback_status, date: date, checked: @sectionToShow == id }

    drawSectionSelectButton: (sections) ->
      @sectionMenu = new SectionMenuView(
        el: $('.section-button-placeholder'),
        sections: sections,
        course: {name: @options.course_name},
        showSections: sections,
        currentSection: @sectionToShow)
      @sectionMenu.render()

    getInitialToolbarPreferences: () ->
      storedSortOrder = @options.gradebook_column_order_settings ||
        { sortType: 'assignment_group' }
      savedPreferences =
        hideStudentNames: userSettings.contextGet('hideStudentNames')
        hideNotesColumn: !@options.teacher_notes || @options.teacher_notes.hidden
        showAttendanceColumns: userSettings.contextGet('showAttendanceColumns')
        showConcludedEnrollments: userSettings.contextGet('showConcludedEnrollments')
        showInactiveEnrollments: userSettings.contextGet('showInactiveEnrollments')
        arrangeBy: storedSortOrder.sortType
      _.defaults(savedPreferences, GradebookConstants.DEFAULT_TOOLBAR_PREFERENCES)

    initCheckboxes: (preferences) ->
      $('#show_attendance').prop('checked', preferences.showAttendanceColumns)
      $('#show_concluded_enrollments').prop('checked', (
        @options.course_is_concluded || preferences.showConcludedEnrollments)
      )
      $('#show_inactive_enrollments').prop('checked', (
        @options.course_is_concluded || preferences.showInactiveEnrollments)
      )

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
      $('#show_concluded_enrollments').change(@concludedEnrollmentsChange)
      $('#show_inactive_enrollments').change(@inactiveEnrollmentsChange)

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
      userSettings.contextSet 'showConcludedEnrollments', $showConcludedEnrollments.prop('checked')
      StudentEnrollmentsActions.load()

    inactiveEnrollmentsChange: () =>
      $showInactiveEnrollments = $('#show_inactive_enrollments')
      userSettings.contextSet 'showInactiveEnrollments', $showInactiveEnrollments.prop('checked')
      StudentEnrollmentsActions.load()

    initHeader: ->
      @gradingPeriodToShow = @getGradingPeriodToShow()
      @drawGradingPeriodSelectButton() if @options.multiple_grading_periods_enabled

      $('#gradebook_settings').kyleMenu()
      $('#download_csv').kyleMenu()

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

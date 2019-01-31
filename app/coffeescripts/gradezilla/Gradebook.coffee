#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'jquery'
  'underscore'
  'axios'
  'timezone'
  'jsx/gradezilla/DataLoader'
  'react'
  'react-dom'
  'slickgrid.long_text_editor'
  '../views/KeyboardNavDialog'
  'jst/KeyboardNavDialog'
  '../api/gradingPeriodsApi'
  '../api/gradingPeriodSetsApi'
  '../views/InputFilterView'
  'i18nObj'
  'i18n!gradezilla'
  'jsx/shared/helpers/numberHelper'
  '../gradezilla/GradebookTranslations'
  'jsx/gradebook/CourseGradeCalculator'
  'jsx/gradebook/EffectiveDueDates'
  'jsx/gradebook/shared/helpers/GradeFormatHelper'
  '../userSettings'
  'spin.js'
  '../AssignmentMuter'
  '../shared/GradeDisplayWarningDialog'
  '../gradezilla/PostGradesFrameDialog'
  '../util/NumberCompare'
  '../util/natcompare'
  'convert_case'
  'str/htmlEscape'
  'jsx/gradezilla/shared/EnterGradesAsSetting'
  'jsx/gradezilla/shared/SetDefaultGradeDialogManager'
  'jsx/gradezilla/default_gradebook/CurveGradesDialogManager'
  'jsx/gradezilla/default_gradebook/apis/GradebookApi'
  'jsx/gradezilla/default_gradebook/apis/SubmissionCommentApi'
  'jsx/gradezilla/default_gradebook/FinalGradeOverrides'
  'jsx/gradezilla/default_gradebook/GradebookGrid'
  'jsx/gradezilla/default_gradebook/constants/studentRowHeaderConstants'
  'jsx/gradezilla/default_gradebook/GradebookGrid/editors/AssignmentCellEditor/AssignmentRowCellPropFactory'
  'jsx/gradezilla/default_gradebook/components/GradebookMenu'
  'jsx/gradezilla/default_gradebook/components/ViewOptionsMenu'
  'jsx/gradezilla/default_gradebook/components/ActionMenu'
  'jsx/gradezilla/default_gradebook/components/AssignmentGroupFilter'
  'jsx/gradezilla/default_gradebook/components/GradingPeriodFilter'
  'jsx/gradezilla/default_gradebook/components/ModuleFilter'
  'jsx/gradezilla/default_gradebook/components/SectionFilter'
  'jsx/gradezilla/default_gradebook/components/GridColor'
  'jsx/gradezilla/default_gradebook/components/StatusesModal'
  'jsx/gradezilla/default_gradebook/components/SubmissionTray'
  'jsx/gradezilla/default_gradebook/components/GradebookSettingsModal'
  'jsx/gradezilla/default_gradebook/components/AnonymousSpeedGraderAlert'
  'jsx/gradezilla/default_gradebook/constants/colors'
  'jsx/gradezilla/default_gradebook/stores/StudentDatastore'
  'jsx/gradezilla/SISGradePassback/PostGradesStore'
  'jsx/gradezilla/SISGradePassback/PostGradesApp'
  'jsx/gradezilla/SubmissionStateMap'
  'jsx/gradezilla/shared/DownloadSubmissionsDialogManager'
  'jsx/gradezilla/shared/ReuploadSubmissionsDialogManager'
  '../gradezilla/GradebookKeyboardNav'
  'jsx/gradezilla/shared/AssignmentMuterDialogManager'
  'jsx/gradezilla/shared/helpers/assignmentHelper'
  'jsx/gradezilla/shared/helpers/TextMeasure'
  'jsx/grading/helpers/GradeInputHelper'
  'jsx/grading/helpers/OutlierScoreHelper'
  'jsx/grading/LatePolicyApplicator'
  '@instructure/ui-buttons/lib/components/Button'
  '@instructure/ui-icons/lib/Solid/IconSettings'
  'jsx/shared/FlashAlert'
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jqueryui/dialog'
  'jqueryui/tooltip'
  '../behaviors/tooltip'
  '../behaviors/activate'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'jqueryui/position'
  '../jquery.kylemenu'
  '../jquery/fixDialogButtons'
  'jsx/context_cards/StudentContextCardTrigger'
], ($, _, axios, tz, DataLoader, React, ReactDOM, LongTextEditor, KeyboardNavDialog, KeyboardNavTemplate,
  GradingPeriodsApi, GradingPeriodSetsApi, InputFilterView, i18nObj, I18n, numberHelper, GRADEBOOK_TRANSLATIONS,
  CourseGradeCalculator, EffectiveDueDates, GradeFormatHelper, UserSettings, Spinner, AssignmentMuter,
  GradeDisplayWarningDialog, PostGradesFrameDialog, NumberCompare, natcompare, ConvertCase, htmlEscape,
  EnterGradesAsSetting, SetDefaultGradeDialogManager, CurveGradesDialogManager, GradebookApi, SubmissionCommentApi,
  FinalGradeOverrides, GradebookGrid, studentRowHeaderConstants, AssignmentRowCellPropFactory, GradebookMenu, ViewOptionsMenu, ActionMenu,
  AssignmentGroupFilter, GradingPeriodFilter, ModuleFilter, SectionFilter, GridColor, StatusesModal, SubmissionTray,
  GradebookSettingsModal, AnonymousSpeedGraderAlert, { statusColors }, StudentDatastore, PostGradesStore, PostGradesApp, SubmissionStateMap,
  DownloadSubmissionsDialogManager, ReuploadSubmissionsDialogManager, GradebookKeyboardNav,
  AssignmentMuterDialogManager, assignmentHelper, TextMeasure, GradeInputHelper, { default: OutlierScoreHelper },
  LatePolicyApplicator, { default: Button }, { default: IconSettingsSolid }, FlashAlert) ->

  isAdmin = =>
    _.contains(ENV.current_user_roles, 'admin')

  IS_ADMIN = isAdmin()

  htmlDecode = (input) ->
    input && new DOMParser().parseFromString(input, "text/html").documentElement.textContent

  testWidth = (text, minWidth, maxWidth) ->
    width = Math.max(TextMeasure.getWidth(text), minWidth)
    Math.min width, maxWidth

  renderComponent = (reactClass, mountPoint, props = {}, children = null) ->
    component = React.createElement(reactClass, props, children)
    ReactDOM.render(component, mountPoint)

  getAssignmentGroupPointsPossible = (assignmentGroup) ->
    assignmentGroup.assignments.reduce(
      (sum, assignment) -> sum + (assignment.points_possible || 0),
      0
    )

  ASSIGNMENT_KEY_REGEX = /^assignment_(?!group)/
  forEachSubmission = (students, fn) ->
    Object.keys(students).forEach (studentIdx) =>
      student = students[studentIdx]
      Object.keys(student).forEach (key) =>
        if key.match ASSIGNMENT_KEY_REGEX
          fn(student[key])

  ## Gradebook Display Settings
  getInitialGridDisplaySettings = (settings, colors) ->
    selectedPrimaryInfo = if studentRowHeaderConstants.primaryInfoKeys.includes(settings.student_column_display_as)
      settings.student_column_display_as
    else
      studentRowHeaderConstants.defaultPrimaryInfo

    # in case of no user preference, determine the default value after @hasSections has resolved
    selectedSecondaryInfo = settings.student_column_secondary_info

    sortRowsByColumnId = settings.sort_rows_by_column_id || 'student'
    sortRowsBySettingKey = settings.sort_rows_by_setting_key || 'sortable_name'
    sortRowsByDirection = settings.sort_rows_by_direction || 'ascending'

    filterColumnsBy =
      assignmentGroupId: null
      contextModuleId: null
      gradingPeriodId: null

    if settings.filter_columns_by?
      Object.assign(filterColumnsBy, ConvertCase.camelize(settings.filter_columns_by))

    filterRowsBy =
      sectionId: null

    if settings.filter_rows_by?
      Object.assign(filterRowsBy, ConvertCase.camelize(settings.filter_rows_by))

    {
      colors
      enterGradesAs: settings.enter_grades_as || {}
      filterColumnsBy
      filterRowsBy
      selectedPrimaryInfo
      selectedSecondaryInfo
      selectedViewOptionsFilters: settings.selected_view_options_filters || []
      showEnrollments:
        concluded: false
        inactive: false
      showUnpublishedAssignments: true
      showFinalGradeOverrides: false
      sortRowsBy:
        columnId: sortRowsByColumnId # the column controlling the sort
        settingKey: sortRowsBySettingKey # the key describing the sort criteria
        direction: sortRowsByDirection # the direction of the sort
      submissionTray:
        open: false
        studentId: null
        assignmentId: null
        comments: []
        commentsLoaded: false
        commentsUpdating: false
        editedCommentId: null
    }

  ## Gradebook Application State
  getInitialContentLoadStates = ->
    {
      assignmentsLoaded: false
      contextModulesLoaded: false
      overridesColumnUpdating: false
      studentsLoaded: false
      submissionsLoaded: false
      teacherNotesColumnUpdating: false
    }

  getInitialCourseContent = (options) ->
    defaultGradingScheme = null
    if options.default_grading_standard
      defaultGradingScheme = {
        data: options.default_grading_standard
      }

    {
      contextModules: []
      defaultGradingScheme
      gradingSchemes: options.grading_schemes.map(ConvertCase.camelize)
      gradingPeriodAssignments: {}
      assignmentStudentVisibility: {}
      latePolicy: ConvertCase.camelize(options.late_policy) if options.late_policy
    }

  getInitialGradebookContent = (options) ->
    {
      customColumns: if options.teacher_notes then [options.teacher_notes] else []
    }

  getInitialActionStates = () ->
    {
      pendingGradeInfo: []
    }

  anonymousSpeedGraderAlertMountPoint = () ->
    document.querySelector("[data-component='AnonymousSpeedGraderAlert']")

  class Gradebook
    columnWidths =
      assignment:
        min: 10
        default_max: 200
        max: 400
      assignmentGroup:
        min: 35
        default_max: 200
        max: 400
      total:
        min: 95
        max: 400
      total_grade_override:
        min: 95
        max: 400

    hasSections: $.Deferred()

    constructor: (@options) ->
      @gridData = {
        columns: {
          definitions: {}
          frozen: []
          scrollable: []
        }
        rows: []
      }

      @gradebookGrid = new GradebookGrid({
        $container: document.getElementById('gradebook_grid')
        activeBorderColor: '#1790DF' # $active-border-color
        data: @gridData
        editable: @options.gradebook_is_editable
        gradebook: @
      })

      @finalGradeOverrides = new FinalGradeOverrides(@)

      $.subscribe 'assignment_muting_toggled',        @handleAssignmentMutingChange
      $.subscribe 'submissions_updated',              @updateSubmissionsFromExternal

      # emitted by SectionMenuView; also subscribed in OutcomeGradebookView
      $.subscribe 'currentSection/change',            @updateCurrentSection

      # emitted by GradingPeriodMenuView
      $.subscribe 'currentGradingPeriod/change',      @updateCurrentGradingPeriod

      @gridReady = $.Deferred()

      @setInitialState()
      @loadSettings()
      @bindGridEvents()

    # End of constructor

    setInitialState: =>
      @courseContent = getInitialCourseContent(@options)
      @gradebookContent = getInitialGradebookContent(@options)
      @gridDisplaySettings = getInitialGridDisplaySettings(@options.settings, @options.colors)
      @contentLoadStates = getInitialContentLoadStates()
      @actionStates = getInitialActionStates()

      @headerComponentRefs = {}
      @filteredContentInfo =
        invalidAssignmentGroups: []
        mutedAssignments: []
        totalPointsPossible: 0

      @setAssignments({})
      @setAssignmentGroups({})
      @effectiveDueDates = {}

      @students = {}
      @studentViewStudents = {}
      @courseContent.students = new StudentDatastore(@students, @studentViewStudents)

      @initPostGradesStore()
      @initPostGradesLtis()
      @checkForUploadComplete()

    loadSettings: ->
      if @options.grading_period_set
        @gradingPeriodSet = GradingPeriodSetsApi.deserializeSet(@options.grading_period_set)
      else
        @gradingPeriodSet = null
      @show_attendance = !!UserSettings.contextGet 'show_attendance'
      @include_ungraded_assignments = UserSettings.contextGet 'include_ungraded_assignments'
      # preferences serialization causes these to always come
      # from the database as strings
      if @options.course_is_concluded || @options.settings.show_concluded_enrollments == 'true'
        @toggleEnrollmentFilter('concluded', true)
      if @options.settings.show_inactive_enrollments == 'true'
        @toggleEnrollmentFilter('inactive', true)
      @initShowUnpublishedAssignments(@options.settings.show_unpublished_assignments)
      @initShowOverrides(@options.settings.show_final_grade_overrides)
      @initSubmissionStateMap()
      @gradebookColumnSizeSettings = @options.gradebook_column_size_settings
      @setColumnOrder(Object.assign(
        {},
        @options.gradebook_column_order_settings,
        freezeTotalGrade: @options.gradebook_column_order_settings?.freezeTotalGrade == 'true'
      ))
      @teacherNotesNotYetLoaded = !@getTeacherNotesColumn()? || @getTeacherNotesColumn().hidden

      @gotSections(@options.sections)
      @hasSections.then () =>
        if !@getSelectedSecondaryInfo()
          if @sections_enabled
            @gridDisplaySettings.selectedSecondaryInfo = 'section'
          else
            @gridDisplaySettings.selectedSecondaryInfo = 'none'

    bindGridEvents: =>
      @gradebookGrid.events.onColumnsReordered.subscribe (_event, columns) =>
        # determine if assignment columns or custom columns were reordered
        # (this works because frozen columns and non-frozen columns are can't be
        # swapped)

        currentFrozenIds = @gridData.columns.frozen
        updatedFrozenIds = columns.frozen.map((column) => column.id)

        @gridData.columns.frozen = updatedFrozenIds
        @gridData.columns.scrollable = columns.scrollable.map((column) -> column.id)

        if !_.isEqual(currentFrozenIds, updatedFrozenIds)
          currentFrozenColumns = currentFrozenIds.map((columnId) => @gridData.columns.definitions[columnId])
          currentCustomColumnIds = (column.customColumnId for column in currentFrozenColumns when column.type == 'custom_column')
          updatedCustomColumnIds = (column.customColumnId for column in columns.frozen when column.type == 'custom_column')

          if !_.isEqual(currentCustomColumnIds, updatedCustomColumnIds)
            @reorderCustomColumns(updatedCustomColumnIds)
              .then =>
                colsById = _(@gradebookContent.customColumns).indexBy (c) -> c.id
                @gradebookContent.customColumns = _(updatedCustomColumnIds).map (id) -> colsById[id]
        else
          @saveCustomColumnOrder()

        @renderViewOptionsMenu()
        @updateColumnHeaders()

      @gradebookGrid.events.onColumnsResized.subscribe (_event, columns) =>
        columns.forEach (column) =>
          @saveColumnWidthPreference(column.id, column.width)

    initialize: ->
      @setAssignmentGroupsLoaded(false)
      @setStudentsLoaded(false)
      @setSubmissionsLoaded(false)

      dataLoader = DataLoader.loadGradebookData(
        gradebook: @

        courseId: @options.context_id
        perPage: @options.api_max_per_page
        assignmentGroupsURL: @options.assignment_groups_url
        assignmentGroupsParams:
          exclude_response_fields: @fieldsToExcludeFromAssignments
          include: @fieldsToIncludeWithAssignments
        contextModulesURL: @options.context_modules_url
        customColumnsURL: @options.custom_columns_url
        getFinalGradeOverrides: @options.final_grade_override_enabled
        getGradingPeriodAssignments: @gradingPeriodSet?

        sectionsURL: @options.sections_url

        studentsURL: @options.students_stateless_url
        studentsPageCb: @gotChunkOfStudents
        studentsParams: @studentsParams()
        loadedStudentIds: []

        submissionsURL: @options.submissions_url
        submissionsChunkCb: @gotSubmissionsChunk
        submissionsChunkSize: @options.chunk_size
        customColumnDataURL: @options.custom_column_data_url
        customColumnDataPageCb: @gotCustomColumnDataChunk
        customColumnDataParams:
          include_hidden: true
      )

      dataLoader.gotStudentIds.then (response) =>
        @courseContent.students.setStudentIds(response.user_ids)
        @buildRows()

      dataLoader.gotGradingPeriodAssignments?.then @gotGradingPeriodAssignments
      dataLoader.gotAssignmentGroups.then @gotAllAssignmentGroups
      dataLoader.gotCustomColumns.then @gotCustomColumns
      dataLoader.gotStudents.then @gotAllStudents

      @renderedGrid = $.when(
        dataLoader.gotStudentIds,
        dataLoader.gotContextModules,
        dataLoader.gotCustomColumns,
        dataLoader.gotAssignmentGroups,
        dataLoader.gotGradingPeriodAssignments
      ).then(@doSlickgridStuff)

      dataLoader.gotStudents.then () =>
        @setStudentsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

      dataLoader.gotAssignmentGroups.then () =>
        @contentLoadStates.assignmentsLoaded = true
        @renderViewOptionsMenu()
        @updateColumnHeaders()

      dataLoader.gotContextModules.then (contextModules) =>
        @setContextModules(contextModules)
        @contentLoadStates.contextModulesLoaded = true
        @renderViewOptionsMenu()
        @renderFilters()

      dataLoader.gotSubmissions.then () =>
        @setSubmissionsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

      @gridReady.then () =>
        @renderViewOptionsMenu()

    # called from app/jsx/bundles/gradezilla.js
    onShow: ->
      $(".post-grades-button-placeholder").show()
      return if @startedInitializing
      @startedInitializing = true

      if @gridReady.state() != 'resolved'
        @spinner = new Spinner() unless @spinner
        $(@spinner.spin().el).css(
          opacity: 0.5
          top: '55px'
          left: '50%'
        ).addClass('use-css-transitions-for-show-hide').appendTo('#main')
        $('#gradebook-grid-wrapper').hide()
      else
        $('#gradebook_grid').trigger('resize.fillWindowWithMe')

    reloadStudentData: (optionOverrides = {}, afterColumnsUpdated) =>
      @setStudentsLoaded(false)
      @setSubmissionsLoaded(false)
      @renderFilters()

      dataLoaderOptions =
        gradebook: @
        courseId: @options.context_id
        perPage: @options.api_max_per_page
        studentsURL: @options.students_stateless_url
        studentsPageCb: @gotChunkOfStudents
        studentsParams: @studentsParams()
        loadedStudentIds: @courseContent.students.listStudentIds()
        submissionsURL: @options.submissions_url
        submissionsChunkCb: @gotSubmissionsChunk
        submissionsChunkSize: @options.chunk_size
        customColumnIds: @gradebookContent.customColumns.map((column) -> column.id)
        customColumnDataURL: @options.custom_column_data_url
        customColumnDataPageCb: @gotCustomColumnDataChunk
        customColumnDataParams:
          include_hidden: true
        getGradingPeriodAssignments: false

      dataLoader = DataLoader.loadGradebookData(Object.assign(dataLoaderOptions, optionOverrides))

      dataLoader.gotGradingPeriodAssignments?.then (response) =>
        @gotGradingPeriodAssignments(response)
        @updateColumns()
        afterColumnsUpdated() if afterColumnsUpdated

      dataLoader.gotStudentIds.then (response) =>
        @courseContent.students.setStudentIds(response.user_ids)
        @buildRows()

      dataLoader.gotStudents.then () =>
        @setStudentsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

      dataLoader.gotSubmissions.then () =>
        @setSubmissionsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

    loadOverridesForSIS: ->
      return unless @options.post_grades_feature

      assignmentGroupsURL = @options.assignment_groups_url.replace('&include%5B%5D=assignment_visibility', '')
      overrideDataLoader = DataLoader.loadGradebookData(
        assignmentGroupsURL: assignmentGroupsURL
        assignmentGroupsParams:
          exclude_response_fields: @fieldsToExcludeFromAssignments
          include: ['overrides']
        onlyLoadAssignmentGroups: true
      )
      $.when(overrideDataLoader.gotAssignmentGroups).then(@addOverridesToPostGradesStore)

    addOverridesToPostGradesStore: (assignmentGroups) =>
      for group in assignmentGroups
        for assignment in group.assignments
          @assignments[assignment.id].overrides = assignment.overrides if @assignments[assignment.id]
      @postGradesStore.setGradeBookAssignments @assignments

    # dependencies - gridReady
    setAssignmentVisibility: (studentIds) ->
      studentsWithHiddenAssignments = []

      for assignmentId, a of @assignments
        if a.only_visible_to_overrides
          hiddenStudentIds = @hiddenStudentIdsForAssignment(studentIds, a)
          for studentId in hiddenStudentIds
            studentsWithHiddenAssignments.push(studentId)
            @updateSubmission assignment_id: assignmentId, user_id: studentId, hidden: true

      for studentId in _.uniq(studentsWithHiddenAssignments)
        student = @student(studentId)
        @calculateStudentGrade(student)

    hiddenStudentIdsForAssignment: (studentIds, assignment) ->
      # TODO: _.difference is ridic expensive.  may need to do something else
      # for large courses with DA (does that happen?)
      _.difference studentIds, assignment.assignment_visibility

    updateAssignmentVisibilities: (hiddenSub) ->
      assignment = @assignments[hiddenSub.assignment_id]
      filteredVisibility = assignment.assignment_visibility.filter (id) -> id != hiddenSub.user_id
      assignment.assignment_visibility = filteredVisibility

    gotCustomColumns: (columns) =>
      @gradebookContent.customColumns = columns
      columns.forEach (column) =>
        customColumn = @buildCustomColumn(column)
        @gridData.columns.definitions[customColumn.id] = customColumn

    gotCustomColumnDataChunk: (customColumnId, columnData) =>
      studentIds = []

      for datum in columnData
        student = @student(datum.user_id)
        if student? #ignore filtered students
          student["custom_col_#{customColumnId}"] = datum.content
          studentIds.push(student.id)

      @invalidateRowsForStudentIds(_.uniq(studentIds))

    gotAllAssignmentGroups: (assignmentGroups) =>
      @setAssignmentGroupsLoaded(true)
      # purposely passing the @options and assignmentGroups by reference so it can update
      # an assigmentGroup's .group_weight and @options.group_weighting_scheme
      for group in assignmentGroups
        @assignmentGroups[group.id] = group
        for assignment in group.assignments
          assignment.assignment_group = group
          assignment.due_at = tz.parse(assignment.due_at)
          @updateAssignmentEffectiveDueDates(assignment)
          @assignments[assignment.id] = assignment

    gotGradingPeriodAssignments: ({ grading_period_assignments: gradingPeriodAssignments }) =>
      @courseContent.gradingPeriodAssignments = gradingPeriodAssignments

    gotSections: (sections) =>
      @setSections(sections.map(htmlEscape))
      @hasSections.resolve()

      @postGradesStore.setSections @sections

    gotChunkOfStudents: (students) =>
      @courseContent.assignmentStudentVisibility = {}
      for student in students
        student.enrollments = _.filter student.enrollments, (e) ->
          e.type == "StudentEnrollment" || e.type == "StudentViewEnrollment"
        isStudentView = student.enrollments[0].type == "StudentViewEnrollment"
        student.sections = student.enrollments.map (e) -> e.course_section_id

        if isStudentView
          @studentViewStudents[student.id] = htmlEscape(student)
        else
          @students[student.id] = htmlEscape(student)

        @updateStudentAttributes(student)
        @updateStudentRow(student)

      @gridReady.then =>
        @setupGrading(students)

      if @isFilteringRowsBySearchTerm()
        # When filtering, students cannot be matched until loaded. The grid must
        # be re-rendered more aggressively to ensure new rows are inserted.
        @buildRows()
      else
        @gradebookGrid.render()

    ## Post-Data Load Initialization

    doSlickgridStuff: =>
      @initGrid()
      @initHeader()
      @gridReady.resolve()
      @loadOverridesForSIS()

    setupGrading: (students) =>
      # set up a submission for each student even if we didn't receive one
      @submissionStateMap.setup(students, @assignments)
      for student in students
        for assignment_id, assignment of @assignments
          student["assignment_#{assignment_id}"] ?=
            @submissionStateMap.getSubmission student.id, assignment_id
          submissionState = @submissionStateMap.getSubmissionState(student["assignment_#{assignment_id}"])
          student["assignment_#{assignment_id}"].gradeLocked = submissionState.locked
          student["assignment_#{assignment_id}"].gradingType = assignment.grading_type

        student.initialized = true
        @calculateStudentGrade(student)

      studentIds = _.pluck(students, 'id')
      @setAssignmentVisibility(studentIds)

      @invalidateRowsForStudentIds(studentIds)

    resetGrading: =>
      @initSubmissionStateMap()
      @setupGrading(@courseContent.students.listStudents())

    getSubmission: (studentId, assignmentId) =>
      student = @student(studentId)
      student["assignment_#{assignmentId}"]

    updateEffectiveDueDatesFromSubmissions: (submissions) =>
      EffectiveDueDates.updateWithSubmissions(@effectiveDueDates, submissions, @gradingPeriodSet?.gradingPeriods)

    updateAssignmentEffectiveDueDates: (assignment) ->
      assignment.effectiveDueDates = @effectiveDueDates[assignment.id] || {}
      assignment.inClosedGradingPeriod = _.any(assignment.effectiveDueDates, (date) => date.in_closed_grading_period)

    updateStudentAttributes: (student) =>
      student.computed_current_score ||= 0
      student.computed_final_score ||= 0

      student.isConcluded = _.all student.enrollments, (e) ->
        e.enrollment_state == 'completed'
      student.isInactive = _.all student.enrollments, (e) ->
        e.enrollment_state == 'inactive'

      student.cssClass = "student_#{student.id}"

    updateStudentRow: (student) =>
      index = @gridData.rows.findIndex (row) => row.id == student.id
      if index != -1
        @gridData.rows[index] = @buildRow(student)
        @gradebookGrid.invalidateRow(index)

    gotAllStudents: =>
      @setStudentsLoaded(true)
      @renderedGrid.then =>
        @gradebookGrid.gridSupport.columns.updateColumnHeaders(['student'])

    studentsThatCanSeeAssignment: (assignmentId) ->
      @courseContent.assignmentStudentVisibility[assignmentId] ||= (
        assignment = @getAssignment(assignmentId)
        if assignment.only_visible_to_overrides
          _.pick @students, assignment.assignment_visibility...
        else
          @students
      )

    isInvalidSort: =>
      sortSettings = @gradebookColumnOrderSettings

      # This course was sorted by a custom column sort at some point but no longer has any stored
      # column order to sort by
      # let's mark it invalid so it reverts to default sort
      return true if sortSettings?.sortType == 'custom' && !sortSettings?.customOrder

      # This course was sorted by module_position at some point but no longer contains modules
      # let's mark it invalid so it reverts to default sort
      return true if sortSettings?.sortType == 'module_position' && @listContextModules().length == 0

      false

    isDefaultSortOrder: (sortOrder) =>
      not (['due_date', 'name', 'points', 'module_position', 'custom'].includes(sortOrder))

    setColumnOrder: (order) ->
      @gradebookColumnOrderSettings ?= {
        direction: 'ascending'
        freezeTotalGrade: false
        sortType: @defaultSortType
      }

      return unless order

      if order.freezeTotalGrade?
        @gradebookColumnOrderSettings.freezeTotalGrade = order.freezeTotalGrade

      if order.sortType == 'custom' and order.customOrder?
        @gradebookColumnOrderSettings.sortType = 'custom'
        @gradebookColumnOrderSettings.customOrder = order.customOrder
      else if order.sortType? and order.direction?
        @gradebookColumnOrderSettings.sortType = order.sortType
        @gradebookColumnOrderSettings.direction = order.direction

    getColumnOrder: =>
      if @isInvalidSort() || !@gradebookColumnOrderSettings
        direction: 'ascending'
        freezeTotalGrade: false
        sortType: @defaultSortType
      else
        @gradebookColumnOrderSettings

    saveColumnOrder: ->
      unless @isInvalidSort()
        url = @options.gradebook_column_order_settings_url
        $.ajaxJSON(url, 'POST', { column_order: @getColumnOrder() })

    reorderCustomColumns: (ids) ->
      $.ajaxJSON(@options.reorder_custom_columns_url, "POST", order: ids)

    saveCustomColumnOrder: =>
      @setColumnOrder(
        customOrder: @gridData.columns.scrollable
        sortType: 'custom'
      )
      @saveColumnOrder()

    arrangeColumnsBy: (newSortOrder, isFirstArrangement) =>
      unless isFirstArrangement
        @setColumnOrder(newSortOrder)
        @saveColumnOrder()

      columns = @gridData.columns.scrollable.map((columnId) => @gridData.columns.definitions[columnId])
      columns.sort @makeColumnSortFn(newSortOrder)
      @gridData.columns.scrollable = columns.map((column) -> column.id)

      @updateGrid()
      @renderViewOptionsMenu()
      @updateColumnHeaders()

    makeColumnSortFn: (sortOrder) =>
      switch sortOrder.sortType
        when 'due_date' then @wrapColumnSortFn(@compareAssignmentDueDates, sortOrder.direction)
        when 'module_position' then @wrapColumnSortFn(@compareAssignmentModulePositions, sortOrder.direction)
        when 'name' then @wrapColumnSortFn(@compareAssignmentNames, sortOrder.direction)
        when 'points' then @wrapColumnSortFn(@compareAssignmentPointsPossible, sortOrder.direction)
        when 'custom' then @makeCompareAssignmentCustomOrderFn(sortOrder)
        else @wrapColumnSortFn(@compareAssignmentPositions, sortOrder.direction)

    compareAssignmentPositions: (a, b) ->
      diffOfAssignmentGroupPosition = a.object.assignment_group.position - b.object.assignment_group.position
      diffOfAssignmentPosition = a.object.position - b.object.position

      # order first by assignment_group position and then by assignment position
      # will work when there are less than 1000000 assignments in an assignment_group
      return (diffOfAssignmentGroupPosition * 1000000) + diffOfAssignmentPosition

    compareAssignmentDueDates: (a, b) ->
      firstAssignment = a.object
      secondAssignment = b.object
      assignmentHelper.compareByDueDate(firstAssignment, secondAssignment)

    compareAssignmentModulePositions: (a, b) =>
      firstAssignmentModulePosition = @getContextModule(a.object.module_ids[0])?.position
      secondAssignmentModulePosition = @getContextModule(b.object.module_ids[0])?.position

      if firstAssignmentModulePosition? && secondAssignmentModulePosition?
        if firstAssignmentModulePosition == secondAssignmentModulePosition
          # let's determine their order in the module because both records are in the same module
          firstPositionInModule = a.object.module_positions[0]
          secondPositionInModule = b.object.module_positions[0]

          firstPositionInModule - secondPositionInModule
        else
          # let's determine the order of their modules because both records are in different modules
          firstAssignmentModulePosition - secondAssignmentModulePosition
      else if !firstAssignmentModulePosition? && secondAssignmentModulePosition?
        1
      else if firstAssignmentModulePosition? && !secondAssignmentModulePosition?
        -1
      else
        @compareAssignmentPositions(a, b)

    compareAssignmentNames: (a, b) =>
      @localeSort(a.object.name, b.object.name)

    compareAssignmentPointsPossible: (a, b) ->
      a.object.points_possible - b.object.points_possible

    makeCompareAssignmentCustomOrderFn: (sortOrder) =>
      sortMap = {}
      indexCounter = 0
      for assignmentId in sortOrder.customOrder
        sortMap[String(assignmentId)] = indexCounter
        indexCounter += 1
      return (a, b) =>
        # The second lookup for each index is to maintain backwards
        # compatibility with old gradebook sorting on load which only
        # considered assignment ids.
        aIndex = sortMap[a.id]
        aIndex ?= sortMap[String(a.object.id)] if a.object?
        bIndex = sortMap[b.id]
        bIndex ?= sortMap[String(b.object.id)] if b.object?
        if aIndex? and bIndex?
          return aIndex - bIndex
        # if there's a new assignment or assignment group and its
        # order has not been stored, it should come at the end
        else if aIndex? and not bIndex?
          return -1
        else if bIndex?
          return 1
        else
          return @wrapColumnSortFn(@compareAssignmentPositions)(a, b)

    wrapColumnSortFn: (wrappedFn, direction = 'ascending') ->
      (a, b) ->
        return -1 if b.type is 'total_grade_override'
        return  1 if a.type is 'total_grade_override'
        return -1 if b.type is 'total_grade'
        return  1 if a.type is 'total_grade'
        return -1 if b.type is 'assignment_group' and a.type isnt 'assignment_group'
        return  1 if a.type is 'assignment_group' and b.type isnt 'assignment_group'
        if a.type is 'assignment_group' and b.type is 'assignment_group'
          return a.object.position - b.object.position

        [a, b] = [b, a] if direction == 'descending'
        wrappedFn(a, b)

    ## Filtering

    rowFilter: (student) =>
      return true unless @isFilteringRowsBySearchTerm()

      propertiesToMatch = ['name', 'login_id', 'short_name', 'sortable_name', 'sis_user_id']
      pattern = new RegExp(@userFilterTerm, 'i')
      _.any propertiesToMatch, (prop) ->
        student[prop]?.match pattern

    filterAssignments: (assignments) =>
      assignmentFilters = [
        @filterAssignmentBySubmissionTypes,
        @filterAssignmentByPublishedStatus,
        @filterAssignmentByAssignmentGroup,
        @filterAssignmentByGradingPeriod,
        @filterAssignmentByModule
      ]

      matchesAllFilters = (assignment) =>
        assignmentFilters.every ((filter) => filter(assignment))

      assignments.filter(matchesAllFilters)

    filterAssignmentBySubmissionTypes: (assignment) =>
      submissionType = '' + assignment.submission_types
      submissionType isnt 'not_graded' and
        (submissionType isnt 'attendance' or @show_attendance)

    filterAssignmentByPublishedStatus: (assignment) =>
      assignment.published or @gridDisplaySettings.showUnpublishedAssignments

    filterAssignmentByAssignmentGroup: (assignment) =>
      return true unless @isFilteringColumnsByAssignmentGroup()
      @getAssignmentGroupToShow() == assignment.assignment_group_id

    filterAssignmentByGradingPeriod: (assignment) =>
      return true unless @isFilteringColumnsByGradingPeriod()
      assignment.id in (@courseContent.gradingPeriodAssignments[@getGradingPeriodToShow()] or [])

    filterAssignmentByModule: (assignment) =>
      contextModuleFilterSetting = @getFilterColumnsBySetting('contextModuleId')
      return true unless contextModuleFilterSetting
      # Firefox returns a value of "null" (String) for this when nothing is set.  The comparison
      # to 'null' below is a result of that
      return true if contextModuleFilterSetting == '0' || contextModuleFilterSetting == 'null'

      @getFilterColumnsBySetting('contextModuleId') in (assignment.module_ids || [])

    ## Course Content Event Handlers

    handleAssignmentMutingChange: (assignment) =>
      if assignment.anonymize_students
        anonymousColumnIds = [
          @getAssignmentColumnId(assignment.id),
          @getAssignmentGroupColumnId(assignment.assignment_group_id),
          'total_grade',
          'total_grade_override'
        ]

        if @getSortRowsBySetting().columnId in anonymousColumnIds
          @setSortRowsBySetting('student', 'sortable_name', 'ascending')

      @gradebookGrid.gridSupport.columns.updateColumnHeaders([@getAssignmentColumnId(assignment.id)])
      @updateFilteredContentInfo()
      @resetGrading()

    handleSubmissionsDownloading: (assignmentId) =>
      @getAssignment(assignmentId).hasDownloadedSubmissions = true
      @gradebookGrid.gridSupport.columns.updateColumnHeaders([@getAssignmentColumnId(assignmentId)])

    # filter, sort, and build the dataset for slickgrid to read from, then
    # force a full redraw
    buildRows: =>
      @gridData.rows.length = 0 # empty the list of rows

      for student in @courseContent.students.listStudents()
        if @rowFilter(student)
          @gridData.rows.push(@buildRow(student))
          @calculateStudentGrade(student) # TODO: this may not be necessary

      @gradebookGrid.invalidate()

    buildRow: (student) =>
      # because student is current mutable, we need to retain the reference
      student

    gotSubmissionsChunk: (student_submissions) =>
      changedStudentIds = []
      submissions = []

      for data in student_submissions
        changedStudentIds.push(data.user_id)
        student = @student(data.user_id)
        for submission in data.submissions
          submissions.push(submission)
          @updateSubmission(submission)

        student.loaded = true

      @updateEffectiveDueDatesFromSubmissions(submissions)
      _.each @assignments, (assignment) =>
        @updateAssignmentEffectiveDueDates(assignment)

      changedStudentIds = _.uniq(changedStudentIds)
      students = changedStudentIds.map(@student)
      @setupGrading(students)

    student: (id) =>
      @students[id] || @studentViewStudents[id]

    updateSubmission: (submission) =>
      student = @student(submission.user_id)
      submission.submitted_at = tz.parse(submission.submitted_at)
      submission.excused = !!submission.excused
      submission.rawGrade = submission.grade # save the unformatted version of the grade too
      submission.grade = GradeFormatHelper.formatGrade(submission.grade, {
        gradingType: submission.gradingType, delocalize: false
      })
      cell = student["assignment_#{submission.assignment_id}"] ||= {}
      _.extend(cell, submission)

    # this is used after the CurveGradesDialog submit xhr comes back.  it does not use the api
    # because there is no *bulk* submissions#update endpoint in the api.
    # It is different from gotSubmissionsChunk in that gotSubmissionsChunk expects an array of students
    # where each student has an array of submissions.  This one just expects an array of submissions,
    # they are not grouped by student.
    updateSubmissionsFromExternal: (submissions) =>
      columns = @gradebookGrid.grid.getColumns()
      changedColumnHeaders = {}
      changedStudentIds = []

      for submission in submissions
        student = @student(submission.user_id)
        continue unless student # if the student isn't loaded, we don't need to update it

        idToMatch = @getAssignmentColumnId(submission.assignment_id)
        cell = index for column, index in columns when column.id is idToMatch

        unless changedColumnHeaders[submission.assignment_id]
          changedColumnHeaders[submission.assignment_id] = cell

        #check for DA visible
        @updateAssignmentVisibilities(submission) unless submission.assignment_visible
        @updateSubmission(submission)
        @submissionStateMap.setSubmissionCellState(student, @assignments[submission.assignment_id], submission)
        submissionState = @submissionStateMap.getSubmissionState(submission)
        student["assignment_#{submission.assignment_id}"].gradeLocked = submissionState.locked
        @calculateStudentGrade(student)
        changedStudentIds.push(student.id)

      changedColumnIds = Object.keys(changedColumnHeaders).map(@getAssignmentColumnId)
      @gradebookGrid.gridSupport.columns.updateColumnHeaders(changedColumnIds)

      @updateRowCellsForStudentIds(_.uniq(changedStudentIds))

    submissionsForStudent: (student) =>
      allSubmissions = (value for key, value of student when key.match ASSIGNMENT_KEY_REGEX)
      return allSubmissions unless @gradingPeriodSet?
      return allSubmissions unless @isFilteringColumnsByGradingPeriod()

      _.filter allSubmissions, (submission) =>
        studentPeriodInfo = @effectiveDueDates[submission.assignment_id]?[submission.user_id]
        studentPeriodInfo and studentPeriodInfo.grading_period_id == @getGradingPeriodToShow()

    calculateStudentGrade: (student) =>
      if student.loaded and student.initialized
        hasGradingPeriods = @gradingPeriodSet and @effectiveDueDates

        grades = CourseGradeCalculator.calculate(
          @submissionsForStudent(student),
          @assignmentGroups,
          @options.group_weighting_scheme,
          (@gradingPeriodSet if hasGradingPeriods),
          EffectiveDueDates.scopeToUser(@effectiveDueDates, student.id) if hasGradingPeriods
        )

        if @isFilteringColumnsByGradingPeriod()
          grades = grades.gradingPeriods[@getGradingPeriodToShow()]

        finalOrCurrent = if @include_ungraded_assignments then 'final' else 'current'

        for assignmentGroupId, group of @assignmentGroups
          grade = grades.assignmentGroups[assignmentGroupId]
          grade = grade?[finalOrCurrent] || { score: 0, possible: 0, submissions: [] }

          student["assignment_group_#{assignmentGroupId}"] = grade
          for submissionData in grade.submissions
            submissionData.submission.drop = submissionData.drop
        student["total_grade"] = grades[finalOrCurrent]

    ## Grid Styling Methods

    # this is because of a limitation with SlickGrid,
    # when it makes the header row it does this:
    # $("<div class='slick-header-columns' style='width:10000px; left:-1000px' />")
    # if a course has a ton of assignments then it will not be wide enough to
    # contain them all
    fixMaxHeaderWidth: ->
      @$grid.find('.slick-header-columns').width(1000000)

    # SlickGrid doesn't have a blur event for the grid, so this mimics it in
    # conjunction with a click listener on <body />. When we 'blur' the grid
    # by clicking outside of it, save the current field.
    onGridBlur: (e) =>
      @closeSubmissionTray() if @getSubmissionTrayState().open

      # Prevent exiting the cell editor when clicking in the cell being edited.
      editingNode = @gradebookGrid.gridSupport.state.getEditingNode()
      return if editingNode?.contains(e.target)

      activeNode = @gradebookGrid.gridSupport.state.getActiveNode()
      return unless activeNode

      if activeNode.contains(e.target)
        # SlickGrid does not re-engage the editor for the active cell upon single click
        @gradebookGrid.gridSupport.helper.beginEdit()
        return

      className = e.target.className

      # PopoverMenu's trigger sends an event with a target whose className is a SVGAnimatedString
      # This normalizes the className where possible
      if typeof className != 'string'
        if typeof className == 'object'
          className = className.baseVal || ''
        else
          className = ''

      # Do nothing if clicking on another cell
      return if className.match(/cell|slick/)

      @gradebookGrid.gridSupport.state.blur()

    sectionList: () ->
      _.values(@sections)
        .sort((a, b) => (a.id - b.id))
        .map((section) => Object.assign({}, section, {name: htmlEscape.unescape(section.name)}))

    updateSectionFilterVisibility: () ->
      mountPoint = document.getElementById('sections-filter-container')

      if @showSections() and 'sections' in @gridDisplaySettings.selectedViewOptionsFilters
        sectionList = @sectionList()
        props =
          items: sectionList
          onSelect: @updateCurrentSection
          selectedItemId: @getFilterRowsBySetting('sectionId') || '0'
          disabled: !@contentLoadStates.studentsLoaded

        @sectionFilterMenu = renderComponent(SectionFilter, mountPoint, props)
      else
        @updateCurrentSection(null)
        if @sectionFilterMenu
          ReactDOM.unmountComponentAtNode(mountPoint)
          @sectionFilterMenu = null

    updateCurrentSection: (sectionId) =>
      sectionId = if sectionId == '0' then null else sectionId
      currentSection = @getFilterRowsBySetting('sectionId')
      if currentSection != sectionId
        @setFilterRowsBySetting('sectionId', sectionId)
        @postGradesStore.setSelectedSection(sectionId)
        @saveSettings({}, =>
          @updateSectionFilterVisibility()
          @reloadStudentData()
        )

    showSections: ->
      @sections_enabled

    assignmentGroupList: ->
      return [] unless @assignmentGroups
      Object.values(@assignmentGroups).sort((a, b) => (a.position - b.position))

    updateAssignmentGroupFilterVisibility: ->
      mountPoint = document.getElementById('assignment-group-filter-container')
      groups = @assignmentGroupList()

      if groups.length > 1 and 'assignmentGroups' in @gridDisplaySettings.selectedViewOptionsFilters
        props =
          items: groups
          onSelect: @updateCurrentAssignmentGroup
          selectedItemId: @getAssignmentGroupToShow()

        @assignmentGroupFilterMenu = renderComponent(AssignmentGroupFilter, mountPoint, props)
      else
        @updateCurrentAssignmentGroup(null)
        if @assignmentGroupFilterMenu?
          ReactDOM.unmountComponentAtNode(mountPoint)
          @assignmentGroupFilterMenu = null

    updateCurrentAssignmentGroup: (group) =>
      if @getFilterColumnsBySetting('assignmentGroupId') != group
        @setFilterColumnsBySetting('assignmentGroupId', group)
        @saveSettings()
        @resetGrading()
        @updateFilteredContentInfo()
        @updateColumnsAndRenderViewOptionsMenu()
        @updateAssignmentGroupFilterVisibility()

    gradingPeriodList: ->
      @gradingPeriodSet.gradingPeriods.sort((a, b) => (a.startDate - b.startDate))

    updateGradingPeriodFilterVisibility: () ->
      mountPoint = document.getElementById('grading-periods-filter-container')

      if @gradingPeriodSet? and 'gradingPeriods' in @gridDisplaySettings.selectedViewOptionsFilters
        props =
          items: @gradingPeriodList().map((item) => { id: item.id, name: item.title })
          onSelect: @updateCurrentGradingPeriod
          selectedItemId: @getGradingPeriodToShow()

        @gradingPeriodFilterMenu = renderComponent(GradingPeriodFilter, mountPoint, props)
      else
        @updateCurrentGradingPeriod(null)
        if @gradingPeriodFilterMenu?
          ReactDOM.unmountComponentAtNode(mountPoint)
          @gradingPeriodFilterMenu = null

    updateCurrentGradingPeriod: (period) =>
      if @getFilterColumnsBySetting('gradingPeriodId') != period
        @setFilterColumnsBySetting('gradingPeriodId', period)
        @saveSettings()
        @resetGrading()
        @sortGridRows()
        @updateFilteredContentInfo()
        @updateColumnsAndRenderViewOptionsMenu()
        @updateGradingPeriodFilterVisibility()
        @renderActionMenu()

    updateCurrentModule: (moduleId) =>
      if @getFilterColumnsBySetting('contextModuleId') != moduleId
        @setFilterColumnsBySetting('contextModuleId', moduleId)
        @saveSettings()
        @updateFilteredContentInfo()
        @updateColumnsAndRenderViewOptionsMenu()
        @updateModulesFilterVisibility()

    moduleList: ->
      @listContextModules().sort((a, b) => (a.position - b.position))

    updateModulesFilterVisibility: () ->
      mountPoint = document.getElementById('modules-filter-container')

      if @listContextModules()?.length > 0 and 'modules' in @gridDisplaySettings.selectedViewOptionsFilters
        props =
          items: @moduleList()
          onSelect: @updateCurrentModule
          selectedItemId: @getFilterColumnsBySetting('contextModuleId') || '0'

        @moduleFilterMenu = renderComponent(ModuleFilter, mountPoint, props)
      else
        @updateCurrentModule(null)
        if @moduleFilterMenu?
          ReactDOM.unmountComponentAtNode(mountPoint)
          @moduleFilterMenu = null

    initSubmissionStateMap: =>
      @submissionStateMap = new SubmissionStateMap
        hasGradingPeriods: @gradingPeriodSet?
        selectedGradingPeriodID: @getGradingPeriodToShow()
        isAdmin: isAdmin()

    initPostGradesStore: ->
      @postGradesStore = PostGradesStore
        course:
          id:     @options.context_id
          sis_id: @options.context_sis_id
      @postGradesStore.addChangeListener(@updatePostGradesFeatureButton)

      sectionId = @getFilterRowsBySetting('sectionId')
      @postGradesStore.setSelectedSection(sectionId)

    delayedCall: (delay, fn) =>
      setTimeout fn, delay

    initPostGradesLtis: =>
      @postGradesLtis = @options.post_grades_ltis.map (lti) =>
        postGradesLti =
          id: lti.id
          name: lti.name
          onSelect: =>
            postGradesDialog = new PostGradesFrameDialog
              returnFocusTo: document.querySelector("[data-component='ActionMenu'] button")
              baseUrl: lti.data_url
            @delayedCall 10, => postGradesDialog.open()
            window.external_tool_redirect =
              ready: postGradesDialog.close
              cancel: postGradesDialog.close

    updatePostGradesFeatureButton: =>
      @disablePostGradesFeature = !@postGradesStore.hasAssignments() || !@postGradesStore.selectedSISId()
      @gridReady.then =>
        @renderActionMenu()

    initHeader: =>
      @renderGradebookMenus()
      @renderFilters()

      @arrangeColumnsBy(@getColumnOrder(), true)

      @renderGradebookSettingsModal()
      @renderSettingsButton()
      @renderStatusesModal()

      $('#keyboard-shortcuts').click ->
        questionMarkKeyDown = $.Event('keydown', keyCode: 191)
        $(document).trigger(questionMarkKeyDown)

    renderGradebookMenus: =>
      @renderGradebookMenu()
      @renderViewOptionsMenu()
      @renderActionMenu()

    renderGradebookMenu: =>
      mountPoints = document.querySelectorAll('[data-component="GradebookMenu"]')
      props =
        assignmentOrOutcome: @options.assignmentOrOutcome
        courseUrl: @options.context_url,
        learningMasteryEnabled: @options.outcome_gradebook_enabled,
        navigate: @options.navigate
      for mountPoint in mountPoints
        props.variant = mountPoint.getAttribute('data-variant')
        renderComponent(GradebookMenu, mountPoint, props)

    getTeacherNotesViewOptionsMenuProps: ->
      teacherNotes = @getTeacherNotesColumn()
      showingNotes = teacherNotes? and not teacherNotes.hidden
      if showingNotes
        onSelect = => @setTeacherNotesHidden(true)
      else if teacherNotes
        onSelect = => @setTeacherNotesHidden(false)
      else
        onSelect = @createTeacherNotes

      disabled: @contentLoadStates.teacherNotesColumnUpdating || @gridReady.state() != 'resolved'
      onSelect: onSelect
      selected: showingNotes

    getOverridesViewOptionsMenuProps: ->
      disabled: @contentLoadStates.overridesColumnUpdating || @gridReady.state() != 'resolved'
      label: if @options.grading_period_set then I18n.t('Grading Period Overrides') else I18n.t('Overrides')
      onSelect: @toggleOverrides
      selected: @gridDisplaySettings.showFinalGradeOverrides

    getColumnSortSettingsViewOptionsMenuProps: ->
      storedSortOrder = @getColumnOrder()
      criterion = if @isDefaultSortOrder(storedSortOrder.sortType)
        'default'
      else
        storedSortOrder.sortType

      criterion: criterion
      direction: storedSortOrder.direction || 'ascending'
      disabled: not @contentLoadStates.assignmentsLoaded
      modulesEnabled: @listContextModules().length > 0
      onSortByDefault: =>
        @arrangeColumnsBy({ sortType: 'default', direction: 'ascending' }, false)
      onSortByNameAscending: =>
        @arrangeColumnsBy({ sortType: 'name', direction: 'ascending' }, false)
      onSortByNameDescending: =>
        @arrangeColumnsBy({ sortType: 'name', direction: 'descending' }, false)
      onSortByDueDateAscending: =>
        @arrangeColumnsBy({ sortType: 'due_date', direction: 'ascending' }, false)
      onSortByDueDateDescending: =>
        @arrangeColumnsBy({ sortType: 'due_date', direction: 'descending' }, false)
      onSortByPointsAscending: =>
        @arrangeColumnsBy({ sortType: 'points', direction: 'ascending' }, false)
      onSortByPointsDescending: =>
        @arrangeColumnsBy({ sortType: 'points', direction: 'descending' }, false)
      onSortByModuleAscending: =>
        @arrangeColumnsBy({ sortType: 'module_position', direction: 'ascending' }, false)
      onSortByModuleDescending: =>
        @arrangeColumnsBy({ sortType: 'module_position', direction: 'descending' }, false)

    getFilterSettingsViewOptionsMenuProps: =>
      available: @listAvailableViewOptionsFilters()
      onSelect: @updateFilterSettings
      selected: @listSelectedViewOptionsFilters()

    updateFilterSettings: (filters) =>
      @setSelectedViewOptionsFilters(filters)
      @renderViewOptionsMenu()
      @renderFilters()
      @saveSettings()

    getViewOptionsMenuProps: ->
      teacherNotes: @getTeacherNotesViewOptionsMenuProps()
      overrides: @getOverridesViewOptionsMenuProps()
      finalGradeOverrideEnabled: @options.final_grade_override_enabled
      columnSortSettings: @getColumnSortSettingsViewOptionsMenuProps()
      filterSettings: @getFilterSettingsViewOptionsMenuProps()
      showUnpublishedAssignments: @gridDisplaySettings.showUnpublishedAssignments
      onSelectShowUnpublishedAssignments: @toggleUnpublishedAssignments
      onSelectShowStatusesModal: =>
        @statusesModal.open()

    renderViewOptionsMenu: =>
      mountPoint = document.querySelector("[data-component='ViewOptionsMenu']")
      @viewOptionsMenu = renderComponent(ViewOptionsMenu, mountPoint, @getViewOptionsMenuProps())

    getActionMenuProps: =>
      focusReturnPoint = document.querySelector("[data-component='ActionMenu'] button")
      actionMenuProps =
        gradebookIsEditable: @options.gradebook_is_editable
        contextAllowsGradebookUploads: @options.context_allows_gradebook_uploads
        gradebookImportUrl: @options.gradebook_import_url
        currentUserId: @options.currentUserId
        gradebookExportUrl: @options.export_gradebook_csv_url
        postGradesLtis: @postGradesLtis
        postGradesFeature:
          enabled: @options.post_grades_feature? && !@disablePostGradesFeature
          returnFocusTo: focusReturnPoint
          label: @options.sis_name
          store: @postGradesStore
        publishGradesToSis:
          isEnabled: @options.publish_to_sis_enabled
          publishToSisUrl: @options.publish_to_sis_url
        gradingPeriodId: @getGradingPeriodToShow()

      progressData = @options.gradebook_csv_progress

      if @options.gradebook_csv_progress
        actionMenuProps.lastExport =
          progressId: "#{progressData.progress.id}"
          workflowState: progressData.progress.workflow_state

        attachmentData = @options.attachment
        if attachmentData
          actionMenuProps.attachment =
            id: "#{attachmentData.attachment.id}"
            downloadUrl: @options.attachment_url
            updatedAt: attachmentData.attachment.updated_at
      actionMenuProps

    renderActionMenu: =>
      mountPoint = document.querySelector("[data-component='ActionMenu']")
      props = @getActionMenuProps()
      renderComponent(ActionMenu, mountPoint, props)

    renderFilters: =>
      # Sections and grading periods are passed into the constructor, and therefore are always
      # available, whereas assignment groups and context modules are fetched via the DataLoader,
      # so we need to wait until they are loaded to set their filter visibility.
      @updateSectionFilterVisibility()
      @updateAssignmentGroupFilterVisibility() if @contentLoadStates.assignmentGroupsLoaded
      @updateGradingPeriodFilterVisibility()
      @updateModulesFilterVisibility() if @contentLoadStates.contextModulesLoaded
      @renderSearchFilter()

    renderGridColor: =>
      gridColorMountPoint = document.querySelector('[data-component="GridColor"]')
      gridColorProps =
        colors: @getGridColors()
      renderComponent(GridColor, gridColorMountPoint, gridColorProps)

    renderGradebookSettingsModal: =>
      gradebookSettingsModalMountPoint = document.querySelector("[data-component='GradebookSettingsModal']")
      gradebookSettingsModalProps =
        courseId: @options.context_id
        locale: @options.locale
        onClose: => @gradebookSettingsModalButton.focus()
        onLatePolicyUpdate: @onLatePolicyUpdate
        gradedLateSubmissionsExist: @options.graded_late_submissions_exist
      @gradebookSettingsModal = renderComponent(
        GradebookSettingsModal,
        gradebookSettingsModalMountPoint,
        gradebookSettingsModalProps
      )

    renderSettingsButton: =>
      buttonMountPoint = document.getElementById('gradebook-settings-modal-button-container')
      buttonProps =
        id: 'gradebook-settings-button',
        variant: 'icon',
        onClick: @gradebookSettingsModal.open
      iconSettingsSolid = React.createElement(IconSettingsSolid, { title: I18n.t('Gradebook Settings') })
      @gradebookSettingsModalButton = renderComponent(Button, buttonMountPoint, buttonProps, iconSettingsSolid)

    renderStatusesModal: =>
      statusesModalMountPoint = document.querySelector("[data-component='StatusesModal']")
      statusesModalProps =
        onClose: => @viewOptionsMenu.focus()
        colors: @getGridColors()
        afterUpdateStatusColors: @updateGridColors
      @statusesModal = renderComponent(StatusesModal, statusesModalMountPoint, statusesModalProps)

    checkForUploadComplete: () ->
      if UserSettings.contextGet('gradebookUploadComplete')
        $.flashMessage I18n.t('Upload successful')
        UserSettings.contextRemove('gradebookUploadComplete')

    weightedGroups: =>
      @options.group_weighting_scheme == "percent"

    weightedGrades: =>
      @weightedGroups() || !!@gradingPeriodSet?.weighted

    switchTotalDisplay: ({ dontWarnAgain = false } = {}) =>
      if dontWarnAgain
        UserSettings.contextSet('warned_about_totals_display', true)

      @options.show_total_grade_as_points = not @options.show_total_grade_as_points
      $.ajaxJSON @options.setting_update_url, "PUT", show_total_grade_as_points: @options.show_total_grade_as_points
      @gradebookGrid.invalidate()
      if @gridDisplaySettings.showFinalGradeOverrides
        @gradebookGrid.gridSupport.columns.updateColumnHeaders(['total_grade', 'total_grade_override'])
      else
        @gradebookGrid.gridSupport.columns.updateColumnHeaders(['total_grade'])

    togglePointsOrPercentTotals: (cb) =>
      if UserSettings.contextGet('warned_about_totals_display')
        @switchTotalDisplay()
        cb() if typeof cb == 'function'
      else
        dialog_options =
          showing_points: @options.show_total_grade_as_points
          save: @switchTotalDisplay
          onClose: cb
        new GradeDisplayWarningDialog(dialog_options)

    onUserFilterInput: (term) =>
      @userFilterTerm = term
      @buildRows()

    renderSearchFilter: =>
      unless @userFilter
        @userFilter = new InputFilterView(el: '#search-filter-container input')
        @userFilter.on('input', @onUserFilterInput)

      disabled = !@contentLoadStates.studentsLoaded or !@contentLoadStates.submissionsLoaded
      @userFilter.el.disabled = disabled
      @userFilter.el.setAttribute('aria-disabled', disabled)

    setVisibleGridColumns: ->
      parentColumnIds = @gridData.columns.frozen.filter((columnId) -> !/^custom_col_/.test(columnId))
      customColumnIds = @listVisibleCustomColumns().map((column) => @getCustomColumnId(column.id))

      assignments = @filterAssignments(Object.values(@assignments))
      scrollableColumns = assignments.map (assignment) =>
        @gridData.columns.definitions[@getAssignmentColumnId(assignment.id)]

      unless @hideAggregateColumns()
        for assignmentGroupId of @assignmentGroups
          scrollableColumns.push(@gridData.columns.definitions[@getAssignmentGroupColumnId(assignmentGroupId)])

        if @getColumnOrder().freezeTotalGrade
          parentColumnIds.push('total_grade') unless parentColumnIds.includes('total_grade')
        else
          scrollableColumns.push(@gridData.columns.definitions['total_grade'])

        if @gridDisplaySettings.showFinalGradeOverrides
          scrollableColumns.push(@gridData.columns.definitions['total_grade_override'])

      if @gradebookColumnOrderSettings?.sortType
        scrollableColumns.sort @makeColumnSortFn(@getColumnOrder())

      @gridData.columns.frozen = [parentColumnIds..., customColumnIds...]
      @gridData.columns.scrollable = scrollableColumns.map((column) -> column.id)

    updateGrid: ->
      @gradebookGrid.updateColumns()
      @gradebookGrid.invalidate()

    ## Grid Column Definitions

    # Student Column

    buildStudentColumn: ->
      studentColumnWidth = 150
      if @gradebookColumnSizeSettings
        if @gradebookColumnSizeSettings['student']
          studentColumnWidth = parseInt(@gradebookColumnSizeSettings['student'])

      {
        id: 'student'
        type: 'student'
        width: studentColumnWidth
        cssClass: 'meta-cell primary-column student'
        headerCssClass: 'primary-column student'
        resizable: true
      }

    # Custom Column

    buildCustomColumn: (customColumn) =>
      columnId = @getCustomColumnId(customColumn.id)

      id: columnId
      type: 'custom_column'
      field: "custom_col_#{customColumn.id}"
      width: 100
      cssClass: "meta-cell custom_column #{columnId}"
      headerCssClass: "custom_column #{columnId}"
      resizable: true
      editor: LongTextEditor
      customColumnId: customColumn.id
      autoEdit: false
      maxLength: 255

    # Assignment Column

    buildAssignmentColumn: (assignment) ->
      shrinkForOutOfText = assignment && assignment.grading_type == 'points' && assignment.points_possible?
      minWidth = if shrinkForOutOfText then 140 else 90

      columnId = @getAssignmentColumnId(assignment.id)
      fieldName = "assignment_#{assignment.id}"

      if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings[fieldName]
        assignmentWidth = parseInt(@gradebookColumnSizeSettings[fieldName])
      else
        assignmentWidth = testWidth(assignment.name, minWidth, columnWidths.assignment.default_max)

      columnDef =
        id: columnId
        field: fieldName
        object: assignment
        getGridSupport: => @gradebookGrid.gridSupport
        propFactory: new AssignmentRowCellPropFactory(@)
        minWidth: columnWidths.assignment.min
        maxWidth: columnWidths.assignment.max
        width: assignmentWidth
        cssClass: "assignment #{columnId}"
        headerCssClass: "assignment #{columnId}"
        toolTip: assignment.name
        type: 'assignment'
        assignmentId: assignment.id

      unless columnDef.width > columnDef.minWidth
        columnDef.cssClass += ' minimized'
        columnDef.headerCssClass += ' minimized'

      columnDef

    buildAssignmentGroupColumn: (assignmentGroup) ->
      columnId = @getAssignmentGroupColumnId(assignmentGroup.id)
      fieldName = "assignment_group_#{assignmentGroup.id}"

      if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings[fieldName]
        width = parseInt(@gradebookColumnSizeSettings[fieldName])
      else
        width = testWidth(
          assignmentGroup.name, columnWidths.assignmentGroup.min, columnWidths.assignmentGroup.default_max
        )

      {
        id: columnId
        field: fieldName
        toolTip: assignmentGroup.name
        object: assignmentGroup
        minWidth: columnWidths.assignmentGroup.min
        maxWidth: columnWidths.assignmentGroup.max
        width: width
        cssClass: "meta-cell assignment-group-cell #{columnId}"
        headerCssClass: "assignment_group #{columnId}"
        type: 'assignment_group'
        assignmentGroupId: assignmentGroup.id
      }

    buildTotalGradeColumn: ->
      label = I18n.t "Total"

      if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings['total_grade']
        totalWidth = parseInt(@gradebookColumnSizeSettings['total_grade'])
      else
        totalWidth = testWidth(label, columnWidths.total.min, columnWidths.total.max)

      {
        id: "total_grade"
        field: "total_grade"
        toolTip: label
        minWidth: columnWidths.total.min
        maxWidth: columnWidths.total.max
        width: totalWidth
        cssClass: 'total-cell total_grade'
        headerCssClass: 'total_grade'
        type: 'total_grade'
      }

    buildTotalGradeOverrideColumn: ->
      label = I18n.t 'Override'

      if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings['total_grade_override']
        totalWidth = parseInt(@gradebookColumnSizeSettings['total_grade_override'])
      else
        totalWidth = testWidth(label, columnWidths.total_grade_override.min, columnWidths.total_grade_override.max)

      {
        cssClass: 'total-grade-override'
        headerCssClass: 'total-grade-override'
        id: 'total_grade_override'
        maxWidth: columnWidths.total_grade_override.max
        minWidth: columnWidths.total_grade_override.min
        type: 'total_grade_override'
        width: totalWidth
      }

    initGrid: =>
      @updateFilteredContentInfo()

      studentColumn = @buildStudentColumn()
      @gridData.columns.definitions[studentColumn.id] = studentColumn
      @gridData.columns.frozen.push(studentColumn.id)

      for id, assignment of @assignments
        assignmentColumn = @buildAssignmentColumn(assignment)
        @gridData.columns.definitions[assignmentColumn.id] = assignmentColumn

      for id, assignmentGroup of @assignmentGroups
        assignmentGroupColumn = @buildAssignmentGroupColumn(assignmentGroup)
        @gridData.columns.definitions[assignmentGroupColumn.id] = assignmentGroupColumn

      totalGradeColumn = @buildTotalGradeColumn()
      @gridData.columns.definitions[totalGradeColumn.id] = totalGradeColumn

      totalGradeOverrideColumn = @buildTotalGradeOverrideColumn()
      @gridData.columns.definitions[totalGradeOverrideColumn.id] = totalGradeOverrideColumn

      @renderGridColor()
      @createGrid()

    createGrid: () =>
      @setVisibleGridColumns()

      @gradebookGrid.initialize()

      # This is a faux blur event for SlickGrid.
      # Use capture to preempt SlickGrid's internal handlers.
      document.getElementById('application')
        .addEventListener('click', @onGridBlur, true)

      # Grid Events
      @gradebookGrid.grid.onKeyDown.subscribe @onGridKeyDown

      # Grid Body Cell Events
      @gradebookGrid.grid.onBeforeEditCell.subscribe @onBeforeEditCell
      @gradebookGrid.grid.onCellChange.subscribe @onCellChange

      @keyboardNav = new GradebookKeyboardNav({
        gridSupport: @gradebookGrid.gridSupport,
        getColumnTypeForColumnId: @getColumnTypeForColumnId,
        toggleDefaultSort: @toggleDefaultSort,
        openSubmissionTray: @openSubmissionTray
      })

      @gradebookGrid.gridSupport.initialize()

      @gradebookGrid.gridSupport.events.onActiveLocationChanged.subscribe (event, location) =>
        if location.columnId == 'student' && location.region == 'body'
          # In IE11, if we're navigating into the student column from a grade
          # input cell with no text, this focus() call will select the <body>
          # instead of the grades link.  Delaying the call (even with no actual
          # delay) fixes the issue.
          @delayedCall 0, =>
            @gradebookGrid.gridSupport.state.getActiveNode().querySelector('.student-grades-link')?.focus()

      @gradebookGrid.gridSupport.events.onKeyDown.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.handleKeyDown(event)

      @gradebookGrid.gridSupport.events.onNavigatePrev.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @gradebookGrid.gridSupport.events.onNavigateNext.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @gradebookGrid.gridSupport.events.onNavigateLeft.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @gradebookGrid.gridSupport.events.onNavigateRight.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @gradebookGrid.gridSupport.events.onNavigateUp.subscribe (event, location) =>
        if (location.region == 'header')
          # As above, "delay" the call so that we properly focus the header cell
          # when navigating from a grade input cell with no text.
          @delayedCall 0, => @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @onGridInit()

    onGridInit: () ->
      tooltipTexts = {}
      # TODO: this "if @spinner" crap is necessary because the outcome
      # gradebook kicks off the gradebook (unnecessarily).  back when the
      # gradebook was slow, this code worked, but now the spinner may never
      # initialize.  fix the way outcome gradebook loads
      $(@spinner.el).remove() if @spinner
      $('#gradebook-grid-wrapper').show()
      @uid = @gradebookGrid.grid.getUID()

      $('#accessibility_warning').focus ->
        $('#accessibility_warning').removeClass('screenreader-only')
        $('#accessibility_warning').blur ->
          $('#accessibility_warning').addClass('screenreader-only')

      @$grid = $('#gradebook_grid')
        .fillWindowWithMe({
          onResize: => @gradebookGrid.grid.resizeCanvas()
        })

      @$grid.addClass('editable') if @options.gradebook_is_editable

      @fixMaxHeaderWidth()

      @keyboardNav.init()
      keyBindings = @keyboardNav.keyBindings
      @kbDialog = new KeyboardNavDialog().render(KeyboardNavTemplate({keyBindings}))
      $(document).trigger('gridready')

    # Grid Event Handlers

    onGridKeyDown: (event, obj) =>
      return unless obj.row? and obj.cell?

      columns = obj.grid.getColumns()
      column = columns[obj.cell]

      return unless column

      if column.type == 'student' and event.which == 13 # activate link
        event.originalEvent.skipSlickGridDefaults = true

    ## Grid Body Event Handlers

    # The target cell will enter editing mode
    onBeforeEditCell: (event, obj) =>
      if obj.column.type == 'custom_column' && @getCustomColumn(obj.column.customColumnId)?.read_only
        return false
      return true if obj.column.type != 'assignment'

      # Allow editing when the student has been loaded.
      !!@student(obj.item.id)

    # The current cell editor has been changed and is valid
    onCellChange: (event, obj) =>
      { item, column } = obj
      if col_id = column.field.match /^custom_col_(\d+)/
        url = @options.custom_column_datum_url
          .replace(/:id/, col_id[1])
          .replace(/:user_id/, item.id)

        $.ajaxJSON url, "PUT", "column_data[content]": item[column.field]
      else
        # this is the magic that actually updates group and final grades when you edit a cell
        @calculateStudentGrade(item)
        @gradebookGrid.invalidate()

    # Persisted Gradebook Settings

    saveColumnWidthPreference: (id, newWidth) ->
      url = @options.gradebook_column_size_settings_url
      $.ajaxJSON(url, 'POST', {column_id: id, column_size: newWidth})

    saveSettings: ({
      selectedViewOptionsFilters = @listSelectedViewOptionsFilters(),
      showConcludedEnrollments = @getEnrollmentFilters().concluded,
      showInactiveEnrollments = @getEnrollmentFilters().inactive,
      showUnpublishedAssignments = @gridDisplaySettings.showUnpublishedAssignments,
      showFinalGradeOverrides = @gridDisplaySettings.showFinalGradeOverrides,
      studentColumnDisplayAs = @getSelectedPrimaryInfo(),
      studentColumnSecondaryInfo = @getSelectedSecondaryInfo(),
      sortRowsBy = @getSortRowsBySetting(),
      colors = @getGridColors()
    } = {}, successFn, errorFn) =>
      selectedViewOptionsFilters.push('') unless selectedViewOptionsFilters.length > 0
      data =
        gradebook_settings:
          enter_grades_as: @gridDisplaySettings.enterGradesAs
          filter_columns_by: ConvertCase.underscore(@gridDisplaySettings.filterColumnsBy)
          selected_view_options_filters: selectedViewOptionsFilters
          show_concluded_enrollments: showConcludedEnrollments
          show_inactive_enrollments: showInactiveEnrollments
          show_unpublished_assignments: showUnpublishedAssignments
          show_final_grade_overrides: showFinalGradeOverrides
          student_column_display_as: studentColumnDisplayAs
          student_column_secondary_info: studentColumnSecondaryInfo
          filter_rows_by: ConvertCase.underscore(@gridDisplaySettings.filterRowsBy)
          sort_rows_by_column_id: sortRowsBy.columnId
          sort_rows_by_setting_key: sortRowsBy.settingKey
          sort_rows_by_direction: sortRowsBy.direction
          colors: colors

      $.ajaxJSON(@options.settings_update_url, 'PUT', data, successFn, errorFn)

    ## Grid Sorting Methods

    sortRowsBy: (sortFn) ->
      respectorOfPersonsSort = =>
        if _(@studentViewStudents).size()
          (a, b) =>
            if @studentViewStudents[a.id]
              return 1
            else if @studentViewStudents[b.id]
              return -1
            else
              sortFn(a, b)
        else
          sortFn

      @gridData.rows.sort respectorOfPersonsSort()
      @courseContent.students.setStudentIds(_.map(@gridData.rows, 'id'))
      @gradebookGrid.invalidate()

    getStudentGradeForColumn: (student, field) =>
      student[field] || { score: null, possible: 0 }

    getGradeAsPercent: (grade) =>
      if grade.possible > 0
        (grade.score || 0) / grade.possible
      else
        null

    getColumnTypeForColumnId: (columnId) =>
      if columnId.match /^custom_col/
        return 'custom_column'
      else if columnId.match ASSIGNMENT_KEY_REGEX
        return 'assignment'
      else if columnId.match /^assignment_group/
        return 'assignment_group'
      else
        return columnId

    localeSort: (a, b, { asc = true } = {}) ->
      [b, a] = [a, b] unless asc
      natcompare.strings(a || '', b || '')

    idSort: (a, b, { asc = true }) ->
      NumberCompare(Number(a.id), Number(b.id), descending: !asc)

    secondaryAndTertiarySort: (a, b, { asc = true }) =>
      result = @localeSort(a.sortable_name, b.sortable_name, { asc })
      result = @idSort(a, b, { asc }) if result == 0
      result

    gradeSort: (a, b, field, asc) =>
      scoreForSorting = (student) =>
        grade = @getStudentGradeForColumn(student, field)
        if field == "total_grade"
          if @options.show_total_grade_as_points
            grade.score
          else
            @getGradeAsPercent(grade)
        else if field.match /^assignment_group/
          @getGradeAsPercent(grade)
        else
          # TODO: support assignment grading types
          grade.score
      result = NumberCompare(scoreForSorting(a), scoreForSorting(b), descending: !asc)
      result = @secondaryAndTertiarySort(a, b, { asc }) if result == 0
      result

    # when fn is true, those rows get a -1 so they go to the top of the sort
    sortRowsWithFunction: (fn, { asc = true } = {}) ->
      @sortRowsBy((a, b) =>
        rowA = fn(a)
        rowB = fn(b)
        [rowA, rowB] = [rowB, rowA] unless asc
        return -1 if rowA > rowB
        return 1 if rowA < rowB
        @secondaryAndTertiarySort(a, b, { asc })
      )

    missingSort: (columnId) =>
      @sortRowsWithFunction((row) => !!row[columnId]?.missing)

    lateSort: (columnId) =>
      @sortRowsWithFunction((row) => row[columnId].late)

    sortByStudentColumn: (settingKey, direction) =>
      @sortRowsBy((a, b) =>
        asc = direction == 'ascending'
        result = @localeSort(a[settingKey], b[settingKey], { asc })
        result = @idSort(a, b, { asc }) if result == 0
        result
      )

    sortByCustomColumn: (columnId, direction) =>
      @sortRowsBy((a, b) =>
        asc = direction == 'ascending'
        result = @localeSort(a[columnId], b[columnId], { asc } )
        result = @secondaryAndTertiarySort(a, b, { asc }) if result == 0
        result
      )

    sortByAssignmentColumn: (columnId, settingKey, direction) =>
      switch settingKey
        when 'grade'
          @sortRowsBy((a, b) => @gradeSort(a, b, columnId, direction == 'ascending'))
        when 'late'
          @lateSort(columnId)
        when 'missing'
          @missingSort(columnId)
        # when 'unposted' # TODO: in a future milestone, unposted will be added

    sortByAssignmentGroupColumn: (columnId, settingKey, direction) =>
      if settingKey == 'grade'
        @sortRowsBy((a, b) => @gradeSort(a, b, columnId, direction == 'ascending'))

    sortByTotalGradeColumn: (direction) =>
      @sortRowsBy((a, b) => @gradeSort(a, b, 'total_grade', direction == 'ascending'))

    sortGridRows: =>
      { columnId, settingKey, direction } = @getSortRowsBySetting()
      columnType = @getColumnTypeForColumnId(columnId)

      switch columnType
        when 'custom_column' then @sortByCustomColumn(columnId, direction)
        when 'assignment' then @sortByAssignmentColumn(columnId, settingKey, direction)
        when 'assignment_group' then @sortByAssignmentGroupColumn(columnId, settingKey, direction)
        when 'total_grade' then @sortByTotalGradeColumn(direction)
        else @sortByStudentColumn(settingKey, direction)

      @updateColumnHeaders()

    # Filtered Content Information Methods

    updateFilteredContentInfo: =>
      unorderedAssignments = (assignment for assignmentId, assignment of @assignments)
      filteredAssignments = @filterAssignments(unorderedAssignments)

      @filteredContentInfo.mutedAssignments = filteredAssignments.filter((assignment) => assignment.muted)
      @filteredContentInfo.totalPointsPossible = _.reduce @assignmentGroups,
        (sum, assignmentGroup) -> sum + getAssignmentGroupPointsPossible(assignmentGroup),
        0

      if @weightedGroups()
        invalidAssignmentGroups = _.filter @assignmentGroups, (ag) ->
          getAssignmentGroupPointsPossible(ag) == 0
        @filteredContentInfo.invalidAssignmentGroups = invalidAssignmentGroups
      else
        @filteredContentInfo.invalidAssignmentGroups = []

    listInvalidAssignmentGroups: =>
      @filteredContentInfo.invalidAssignmentGroups

    listMutedAssignments: =>
      @filteredContentInfo.mutedAssignments

    getTotalPointsPossible: =>
      @filteredContentInfo.totalPointsPossible

    handleColumnHeaderMenuClose: =>
      @keyboardNav.handleMenuOrDialogClose()

    toggleNotesColumn: =>
      parentColumnIds = @gridData.columns.frozen.filter((columnId) -> !/^custom_col_/.test(columnId))
      customColumnIds = @listVisibleCustomColumns().map((column) => @getCustomColumnId(column.id))

      @gridData.columns.frozen = [parentColumnIds..., customColumnIds...]

      @updateGrid()

    showNotesColumn: =>
      if @teacherNotesNotYetLoaded
        @teacherNotesNotYetLoaded = false
        DataLoader.getDataForColumn(@getTeacherNotesColumn().id, @options.custom_column_data_url, {}, @gotCustomColumnDataChunk)

      @getTeacherNotesColumn()?.hidden = false
      @toggleNotesColumn()

    hideNotesColumn: =>
      @getTeacherNotesColumn()?.hidden = true
      @toggleNotesColumn()

    hideAggregateColumns: ->
      return false unless @gradingPeriodSet?
      return false if @gradingPeriodSet.displayTotalsForAllGradingPeriods
      not @isFilteringColumnsByGradingPeriod()

    fieldsToExcludeFromAssignments: ['description', 'needs_grading_count', 'in_closed_grading_period']
    fieldsToIncludeWithAssignments: ['grades_published', 'module_ids', 'assignment_group_id']

    studentsParams: ->
      enrollmentStates = ['invited', 'active']

      if @getEnrollmentFilters().concluded
        enrollmentStates.push('completed')
      if @getEnrollmentFilters().inactive
        enrollmentStates.push('inactive')

      { enrollment_state: enrollmentStates }

    ## Grid DOM Access/Reference Methods

    getCustomColumnId: (customColumnId) =>
      "custom_col_#{customColumnId}"

    getAssignmentColumnId: (assignmentId) =>
      "assignment_#{assignmentId}"

    getAssignmentGroupColumnId: (assignmentGroupId) =>
      "assignment_group_#{assignmentGroupId}"

    ## SlickGrid Data Access Methods

    listRows: =>
      @gridData.rows # currently the source of truth for filtered and sorted rows

    listRowIndicesForStudentIds: (studentIds) =>
      rowIndicesByStudentId = @listRows().reduce((map, row, index) =>
        map[row.id] = index
        map
      , {})
      studentIds.map (studentId) => rowIndicesByStudentId[studentId]

    ## SlickGrid Update Methods

    updateRowCellsForStudentIds: (studentIds) =>
      return unless @gradebookGrid.grid

      # Update each row without entirely replacing the DOM elements.
      # This is needed to preserve the editor for the active cell, when present.
      rowIndices = @listRowIndicesForStudentIds(studentIds)
      columns = @gradebookGrid.grid.getColumns()
      for rowIndex in rowIndices
        for column, columnIndex in columns
          @gradebookGrid.grid.updateCell(rowIndex, columnIndex)

      null # skip building an unused array return value

    invalidateRowsForStudentIds: (studentIds) =>
      rowIndices = @listRowIndicesForStudentIds(studentIds)
      for rowIndex in rowIndices
        @gradebookGrid.invalidateRow(rowIndex) if rowIndex?

      @gradebookGrid.render()

      null # skip building an unused array return value

    ## Gradebook Bulk UI Update Methods

    updateColumns: =>
      @setVisibleGridColumns()
      @gradebookGrid.updateColumns()
      @updateColumnHeaders()

    updateColumnsAndRenderViewOptionsMenu: =>
      @updateColumns()
      @renderViewOptionsMenu()

    ## React Header Component Ref Methods

    setHeaderComponentRef: (columnId, ref) =>
      @headerComponentRefs[columnId] = ref

    getHeaderComponentRef: (columnId) =>
      @headerComponentRefs[columnId]

    removeHeaderComponentRef: (columnId) =>
      delete @headerComponentRefs[columnId]

    ## React Grid Component Rendering Methods

    updateColumnHeaders: ->
      @gradebookGrid.gridSupport?.columns.updateColumnHeaders()

    # Column Header Helpers
    handleHeaderKeyDown: (e, columnId) =>
      @gradebookGrid.gridSupport.navigation.handleHeaderKeyDown e,
        region: 'header'
        cell: @gradebookGrid.grid.getColumnIndex(columnId)
        columnId: columnId

    # Total Grade Column Header

    freezeTotalGradeColumn: =>
      @totalColumnPositionChanged = true
      @gradebookColumnOrderSettings.freezeTotalGrade = true

      studentColumnPosition = @gridData.columns.frozen.indexOf('student')
      @gridData.columns.frozen.splice(studentColumnPosition + 1, 0, 'total_grade')
      @gridData.columns.scrollable = @gridData.columns.scrollable.filter((columnId) -> columnId != 'total_grade')

      @saveColumnOrder()
      @updateGrid()
      @updateColumnHeaders()
      @gradebookGrid.gridSupport.columns.scrollToStart()

    moveTotalGradeColumnToEnd: =>
      @totalColumnPositionChanged = true
      @gradebookColumnOrderSettings.freezeTotalGrade = false

      @gridData.columns.frozen = @gridData.columns.frozen.filter((columnId) -> columnId != 'total_grade')
      @gridData.columns.scrollable = @gridData.columns.scrollable.filter((columnId) -> columnId != 'total_grade')
      @gridData.columns.scrollable.push('total_grade')

      if @getColumnOrder().sortType == 'custom'
        @saveCustomColumnOrder()
      else
        @saveColumnOrder()

      @updateGrid()
      @updateColumnHeaders()
      @gradebookGrid.gridSupport.columns.scrollToEnd()

    totalColumnShouldFocus: ->
      if @totalColumnPositionChanged
        @totalColumnPositionChanged = false
        true
      else
        false

    # Submission Tray

    assignmentColumns: =>
      @gradebookGrid.gridSupport.grid.getColumns().filter (column) =>
        column.type == 'assignment'

    navigateAssignment: (direction) =>
      location = @gradebookGrid.gridSupport.state.getActiveLocation()
      columns = @gradebookGrid.grid.getColumns()
      range = if direction == 'next'
        [location.cell + 1 .. columns.length]
      else
        [location.cell - 1 ... 0]
      assignment

      for i in range
        curAssignment = columns[i]

        if curAssignment.id.match(/^assignment_(?!group)/)
          @gradebookGrid.gridSupport.state.setActiveLocation('body', { row: location.row, cell: i })
          assignment = curAssignment
          break

      assignment

    loadTrayStudent: (direction) =>
      location = @gradebookGrid.gridSupport.state.getActiveLocation()
      rowDelta = if direction == 'next' then 1 else -1
      newRowIdx = location.row + rowDelta
      student = @listRows()[newRowIdx]

      return unless student

      @gradebookGrid.gridSupport.state.setActiveLocation('body', { row: newRowIdx, cell: location.cell })
      @setSubmissionTrayState(true, student.id)
      @updateRowAndRenderSubmissionTray(student.id)

    loadTrayAssignment: (direction) =>
      studentId = @getSubmissionTrayState().studentId
      assignment = @navigateAssignment(direction)

      return unless assignment

      @setSubmissionTrayState(true, studentId, assignment.assignmentId)
      @updateRowAndRenderSubmissionTray(studentId)

    getSubmissionTrayProps: (student) =>
      { open, studentId, assignmentId, comments, editedCommentId } = @getSubmissionTrayState()
      student ||= @student(studentId)
      # get the student's submission, or use a fake submission object in case the
      # submission has not yet loaded
      fakeSubmission = { assignment_id: assignmentId, late: false, missing: false, excused: false, seconds_late: 0 }
      submission = @getSubmission(studentId, assignmentId) || fakeSubmission
      assignment = @getAssignment(assignmentId)
      activeLocation = @gradebookGrid.gridSupport.state.getActiveLocation()
      cell = activeLocation.cell

      columns = @gradebookGrid.gridSupport.grid.getColumns()
      currentColumn = columns[cell]

      assignmentColumns = @assignmentColumns()
      currentAssignmentIdx = assignmentColumns.indexOf(currentColumn)

      isFirstAssignment = currentAssignmentIdx == 0
      isLastAssignment = currentAssignmentIdx == assignmentColumns.length - 1

      isFirstStudent = activeLocation.row == 0
      isLastStudent = activeLocation.row == (@listRows().length - 1)

      submissionState = @submissionStateMap.getSubmissionState({ user_id: studentId, assignment_id: assignmentId })
      isGroupWeightZero = @assignmentGroups[assignment.assignment_group_id].group_weight == 0

      assignment: ConvertCase.camelize(assignment)
      colors: @getGridColors()
      comments: comments
      courseId: @options.context_id
      currentUserId: @options.currentUserId
      enterGradesAs: @getEnterGradesAsSetting(assignmentId)
      gradingDisabled: !!submissionState?.locked || student.isConcluded
      gradingScheme: @getAssignmentGradingScheme(assignmentId).data
      isFirstAssignment: isFirstAssignment
      isInOtherGradingPeriod: !!submissionState?.inOtherGradingPeriod
      isInClosedGradingPeriod: !!submissionState?.inClosedGradingPeriod
      isInNoGradingPeriod: !!submissionState?.inNoGradingPeriod
      isLastAssignment: isLastAssignment
      isFirstStudent: isFirstStudent
      isLastStudent: isLastStudent
      isNotCountedForScore: assignment.omit_from_final_grade or
                            (@options.group_weighting_scheme == 'percent' and isGroupWeightZero)
      isOpen: open
      key: "grade_details_tray"
      latePolicy: @courseContent.latePolicy
      locale: @options.locale
      onAnonymousSpeedGraderClick: @showAnonymousSpeedGraderAlertForURL
      onClose: => @gradebookGrid.gridSupport.helper.focus()
      onGradeSubmission: @gradeSubmission
      onRequestClose: @closeSubmissionTray
      pendingGradeInfo: @getPendingGradeInfo({ assignmentId, userId: studentId })
      selectNextAssignment: => @loadTrayAssignment('next')
      selectPreviousAssignment: => @loadTrayAssignment('previous')
      selectNextStudent: => @loadTrayStudent('next')
      selectPreviousStudent: => @loadTrayStudent('previous')
      speedGraderEnabled: @options.speed_grader_enabled
      student:
        id: student.id
        name: htmlDecode(student.name)
        avatarUrl: htmlDecode(student.avatar_url)
        gradesUrl: "#{student.enrollments[0].grades.html_url}#tab-assignments"
        isConcluded: student.isConcluded
      submission: ConvertCase.camelize(submission)
      submissionUpdating: @submissionIsUpdating({ assignmentId, userId: studentId })
      updateSubmission: @updateSubmissionAndRenderSubmissionTray
      processing: @getCommentsUpdating()
      setProcessing: @setCommentsUpdating
      createSubmissionComment: @apiCreateSubmissionComment
      updateSubmissionComment: @apiUpdateSubmissionComment
      deleteSubmissionComment: @apiDeleteSubmissionComment
      editSubmissionComment: @editSubmissionComment
      submissionComments: @getSubmissionComments()
      submissionCommentsLoaded: @getSubmissionCommentsLoaded()
      editedCommentId: editedCommentId

    renderSubmissionTray: (student) =>
      { open, studentId, assignmentId } = @getSubmissionTrayState()
      mountPoint = document.getElementById('StudentTray__Container')
      props = @getSubmissionTrayProps(student)
      @loadSubmissionComments(assignmentId, studentId) if !@getSubmissionCommentsLoaded() and open
      renderComponent(SubmissionTray, mountPoint, props)

    loadSubmissionComments: (assignmentId, studentId) =>
      SubmissionCommentApi.getSubmissionComments(@options.context_id, assignmentId, studentId)
        .then((comments) =>
          @setSubmissionCommentsLoaded(true)
          @updateSubmissionComments(comments)
        )
        .catch(FlashAlert.showFlashError I18n.t 'There was an error fetching Submission Comments')

    updateRowAndRenderSubmissionTray: (studentId) =>
      @unloadSubmissionComments()
      @updateRowCellsForStudentIds([studentId])
      @renderSubmissionTray(@student(studentId))

    toggleSubmissionTrayOpen: (studentId, assignmentId) =>
      @setSubmissionTrayState(!@getSubmissionTrayState().open, studentId, assignmentId)
      @updateRowAndRenderSubmissionTray(studentId)

    openSubmissionTray: (studentId, assignmentId) =>
      @setSubmissionTrayState(true, studentId, assignmentId)
      @updateRowAndRenderSubmissionTray(studentId)

    closeSubmissionTray: =>
      @setSubmissionTrayState(false)
      rowIndex = @gradebookGrid.grid.getActiveCell().row
      studentId = @gridData.rows[rowIndex].id
      @updateRowAndRenderSubmissionTray(studentId)
      @gradebookGrid.gridSupport.helper.beginEdit()

    getSubmissionTrayState: =>
      @gridDisplaySettings.submissionTray

    setSubmissionTrayState: (open, studentId, assignmentId) =>
      @gridDisplaySettings.submissionTray.open = open
      @gridDisplaySettings.submissionTray.studentId = studentId if studentId
      @gridDisplaySettings.submissionTray.assignmentId = assignmentId if assignmentId
      @gradebookGrid.gridSupport.helper.commitCurrentEdit() if open

    setCommentsUpdating: (status) =>
      @gridDisplaySettings.submissionTray.commentsUpdating = !!status

    getCommentsUpdating: =>
      @gridDisplaySettings.submissionTray.commentsUpdating

    setSubmissionComments: (comments) =>
      @gridDisplaySettings.submissionTray.comments = comments

    updateSubmissionComments: (comments) =>
      @setSubmissionComments(comments)
      @setEditedCommentId(null)
      @setCommentsUpdating(false)
      @renderSubmissionTray()

    unloadSubmissionComments: =>
      @setSubmissionComments([])
      @setSubmissionCommentsLoaded(false)

    apiCreateSubmissionComment: (comment) =>
      { assignmentId, studentId } = @getSubmissionTrayState()
      SubmissionCommentApi.createSubmissionComment(@options.context_id, assignmentId, studentId, comment)
        .then(@updateSubmissionComments)
        .then(FlashAlert.showFlashSuccess I18n.t 'Successfully posted the comment')
        .catch(=> @setCommentsUpdating(false))
        .catch(FlashAlert.showFlashError I18n.t 'There was a problem posting the comment')

    apiUpdateSubmissionComment: (updatedComment, commentId) =>
      SubmissionCommentApi.updateSubmissionComment(commentId, updatedComment)
        .then((response) =>
          { id, comment, editedAt } = response.data
          comments = @getSubmissionComments().map((submissionComment) =>
            if submissionComment.id == id
              Object.assign({}, submissionComment, { comment, editedAt })
            else
              submissionComment
          )
          @updateSubmissionComments(comments)
          FlashAlert.showFlashSuccess(I18n.t('Successfully updated the comment'))()
        ).catch(FlashAlert.showFlashError(I18n.t('There was a problem updating the comment')))

    apiDeleteSubmissionComment: (commentId) =>
      SubmissionCommentApi.deleteSubmissionComment(commentId)
        .then(@removeSubmissionComment commentId)
        .then(FlashAlert.showFlashSuccess I18n.t 'Successfully deleted the comment')
        .catch(FlashAlert.showFlashError I18n.t 'There was a problem deleting the comment')

    editSubmissionComment: (commentId) =>
      @setEditedCommentId(commentId)
      @renderSubmissionTray()

    setEditedCommentId: (id) =>
      @gridDisplaySettings.submissionTray.editedCommentId = id

    getSubmissionComments: =>
      @gridDisplaySettings.submissionTray.comments

    removeSubmissionComment: (commentId) =>
      comments = _.reject(@getSubmissionComments(), (c) => c.id == commentId)
      @updateSubmissionComments(comments)

    setSubmissionCommentsLoaded: (loaded) =>
      @gridDisplaySettings.submissionTray.commentsLoaded = loaded

    getSubmissionCommentsLoaded: =>
      @gridDisplaySettings.submissionTray.commentsLoaded

    ## Gradebook Application State

    defaultSortType: 'assignment_group'

    ## Gradebook Application State Methods

    initShowUnpublishedAssignments: (showUnpublishedAssignments = 'true') =>
      @gridDisplaySettings.showUnpublishedAssignments = showUnpublishedAssignments == 'true'

    toggleUnpublishedAssignments: =>
      @gridDisplaySettings.showUnpublishedAssignments = !@gridDisplaySettings.showUnpublishedAssignments
      @updateColumnsAndRenderViewOptionsMenu()

      @saveSettings(
        { showUnpublishedAssignments: @gridDisplaySettings.showUnpublishedAssignments },
        () =>, # on success, do nothing since the render happened earlier
        () => # on failure, undo
          @gridDisplaySettings.showUnpublishedAssignments = !@gridDisplaySettings.showUnpublishedAssignments
          @updateColumnsAndRenderViewOptionsMenu()
      )

    initShowOverrides: (showFinalGradeOverrides = 'false') =>
      @setShowFinalGradeOverrides(@options.final_grade_override_enabled && showFinalGradeOverrides == 'true')

    setShowFinalGradeOverrides: (show) =>
      @gridDisplaySettings.showFinalGradeOverrides = show

    toggleOverrides: =>
      @setShowFinalGradeOverrides(!@gridDisplaySettings.showFinalGradeOverrides)
      @updateColumnsAndRenderViewOptionsMenu()

      @saveSettings(
        { showFinalGradeOverrides: @gridDisplaySettings.showFinalGradeOverrides },
        () =>, # on success, do nothing since the render happened earlier
        () => # on failure, undo
          @gridDisplaySettings.showFinalGradeOverrides = !@gridDisplaySettings.showFinalGradeOverrides
          @updateColumnsAndRenderViewOptionsMenu()
      )

    setAssignmentsLoaded: (loaded) =>
      @contentLoadStates.assignmentsLoaded = loaded

    setAssignmentGroupsLoaded: (loaded) =>
      @contentLoadStates.assignmentGroupsLoaded = loaded

    setStudentsLoaded: (loaded) =>
      @contentLoadStates.studentsLoaded = loaded

    setSubmissionsLoaded: (loaded) =>
      @contentLoadStates.submissionsLoaded = loaded

    isGradeEditable: (studentId, assignmentId) =>
      student = @student(studentId)
      return false if !student || student.isConcluded
      submissionState = @submissionStateMap.getSubmissionState(assignment_id: assignmentId, user_id: studentId)
      submissionState? && !submissionState.locked

    isGradeVisible: (studentId, assignmentId) =>
      submissionState = @submissionStateMap.getSubmissionState(assignment_id: assignmentId, user_id: studentId)
      submissionState? && !submissionState.hideGrade

    addPendingGradeInfo: (submission, gradeInfo) =>
      { userId, assignmentId } = submission
      pendingGradeInfo = Object.assign({ assignmentId, userId }, gradeInfo)
      @removePendingGradeInfo(submission)
      @actionStates.pendingGradeInfo.push(pendingGradeInfo)

    removePendingGradeInfo: (submission) =>
      @actionStates.pendingGradeInfo = _.reject(@actionStates.pendingGradeInfo, (info) ->
        info.userId == submission.userId and info.assignmentId == submission.assignmentId
      )

    getPendingGradeInfo: (submission) =>
      @actionStates.pendingGradeInfo.find((info) ->
        info.userId == submission.userId and info.assignmentId == submission.assignmentId
      ) or null

    submissionIsUpdating: (submission) ->
      Boolean(@getPendingGradeInfo(submission)?.valid)

    setTeacherNotesColumnUpdating: (updating) =>
      @contentLoadStates.teacherNotesColumnUpdating = updating

    setOverridesColumnUpdating: (updating) =>
      @contentLoadStates.overridesColumnUpdating = updating

    ## Grid Display Settings Access Methods

    getFilterColumnsBySetting: (filterKey) =>
      @gridDisplaySettings.filterColumnsBy[filterKey]

    setFilterColumnsBySetting: (filterKey, value) =>
      @gridDisplaySettings.filterColumnsBy[filterKey] = value

    getFilterRowsBySetting: (filterKey) =>
      @gridDisplaySettings.filterRowsBy[filterKey]

    setFilterRowsBySetting: (filterKey, value) =>
      @gridDisplaySettings.filterRowsBy[filterKey] = value

    isFilteringColumnsByAssignmentGroup: =>
      @getAssignmentGroupToShow() != '0'

    getAssignmentGroupToShow: () =>
      groupId = @getFilterColumnsBySetting('assignmentGroupId') || '0'
      if groupId in _.pluck(@assignmentGroups, 'id') then groupId else '0'

    isFilteringColumnsByGradingPeriod: =>
      @getGradingPeriodToShow() != '0'

    isFilteringRowsBySearchTerm: =>
      @userFilterTerm? and @userFilterTerm != ''

    getGradingPeriodToShow: () =>
      return '0' unless @gradingPeriodSet?
      periodId = @getFilterColumnsBySetting('gradingPeriodId') || @options.current_grading_period_id
      if periodId in _.pluck(@gradingPeriodSet.gradingPeriods, 'id') then periodId else '0'

    getGradingPeriod: (gradingPeriodId) =>
      (@gradingPeriodSet?.gradingPeriods || []).find((gradingPeriod) => gradingPeriod.id == gradingPeriodId)

    setSelectedPrimaryInfo: (primaryInfo, skipRedraw) =>
      @gridDisplaySettings.selectedPrimaryInfo = primaryInfo
      @saveSettings()
      unless skipRedraw
        @buildRows()
        @gradebookGrid.gridSupport.columns.updateColumnHeaders(['student'])

    toggleDefaultSort: (columnId) =>
      sortSettings = @getSortRowsBySetting()
      columnType = @getColumnTypeForColumnId(columnId)
      settingKey = @getDefaultSettingKeyForColumnType(columnType)
      direction = 'ascending'

      if sortSettings.columnId == columnId && sortSettings.settingKey == settingKey && sortSettings.direction == 'ascending'
        direction = 'descending'

      @setSortRowsBySetting(columnId, settingKey, direction)

    getDefaultSettingKeyForColumnType: (columnType) =>
      if columnType == 'assignment' || columnType == 'assignment_group' || columnType == 'total_grade'
        return 'grade'
      else if columnType == 'student'
        return 'sortable_name'

    getSelectedPrimaryInfo: () =>
      @gridDisplaySettings.selectedPrimaryInfo

    setSelectedSecondaryInfo: (secondaryInfo, skipRedraw) =>
      @gridDisplaySettings.selectedSecondaryInfo = secondaryInfo
      @saveSettings()
      unless skipRedraw
        @buildRows()
        @gradebookGrid.gridSupport.columns.updateColumnHeaders(['student'])

    getSelectedSecondaryInfo: () =>
      @gridDisplaySettings.selectedSecondaryInfo

    setSortRowsBySetting: (columnId, settingKey, direction) =>
      @gridDisplaySettings.sortRowsBy.columnId = columnId
      @gridDisplaySettings.sortRowsBy.settingKey = settingKey
      @gridDisplaySettings.sortRowsBy.direction = direction
      @saveSettings()
      @sortGridRows()

    getSortRowsBySetting: =>
      @gridDisplaySettings.sortRowsBy

    updateGridColors: (colors, successFn, errorFn) =>
      setAndRenderColors = =>
        @setGridColors(colors)
        @renderGridColor()
        successFn()

      @saveSettings({ colors }, setAndRenderColors, errorFn)

    setGridColors: (colors) =>
      @gridDisplaySettings.colors = colors

    getGridColors: =>
      statusColors @gridDisplaySettings.colors

    listAvailableViewOptionsFilters: =>
      filters = []
      filters.push('assignmentGroups') if Object.keys(@assignmentGroups || {}).length > 1
      filters.push('gradingPeriods') if @gradingPeriodSet?
      filters.push('modules') if @listContextModules().length > 0
      filters.push('sections') if @sections_enabled
      filters

    setSelectedViewOptionsFilters: (filters) =>
      @gridDisplaySettings.selectedViewOptionsFilters = filters

    listSelectedViewOptionsFilters: =>
      @gridDisplaySettings.selectedViewOptionsFilters

    toggleEnrollmentFilter: (enrollmentFilter, skipApply) =>
      @getEnrollmentFilters()[enrollmentFilter] = !@getEnrollmentFilters()[enrollmentFilter]
      @applyEnrollmentFilter() unless skipApply

    updateStudentHeadersAndReloadData: =>
      @gradebookGrid.gridSupport.columns.updateColumnHeaders(['student'])
      optionOverrides =
        getGradingPeriodAssignments: @gradingPeriodSet?
      afterColumnsUpdated = => @getHeaderComponentRef('student')?.focusAtEnd()
      @reloadStudentData(optionOverrides, afterColumnsUpdated)

    applyEnrollmentFilter: =>
      showInactive = @getEnrollmentFilters().inactive
      showConcluded = @getEnrollmentFilters().concluded
      @saveSettings({ showInactive, showConcluded }, @updateStudentHeadersAndReloadData)

    getEnrollmentFilters: () =>
      @gridDisplaySettings.showEnrollments

    getSelectedEnrollmentFilters: () =>
      filters = @getEnrollmentFilters()
      selectedFilters = []
      for filter of filters
        selectedFilters.push filter if filters[filter]
      selectedFilters

    setEnterGradesAsSetting: (assignmentId, setting) =>
      @gridDisplaySettings.enterGradesAs[assignmentId] = setting

    getEnterGradesAsSetting: (assignmentId) =>
      gradingType = @getAssignment(assignmentId).grading_type
      options = EnterGradesAsSetting.optionsForGradingType(gradingType)
      return null unless options.length

      setting = @gridDisplaySettings.enterGradesAs[assignmentId]
      return setting if options.includes(setting)

      EnterGradesAsSetting.defaultOptionForGradingType(gradingType)

    updateEnterGradesAsSetting: (assignmentId, value) =>
      @setEnterGradesAsSetting(assignmentId, value)
      @saveSettings({}, =>
        @gradebookGrid.gridSupport.columns.updateColumnHeaders([@getAssignmentColumnId(assignmentId)])
        @gradebookGrid.invalidate()
      )

    ## Course Settings Access Methods

    getDefaultGradingScheme: ->
      @courseContent.defaultGradingScheme

    getGradingScheme: (gradingSchemeId) ->
      @courseContent.gradingSchemes.find((scheme) => scheme.id == gradingSchemeId)

    getAssignmentGradingScheme: (assignmentId) ->
      assignment = @getAssignment(assignmentId)
      @getGradingScheme(assignment.grading_standard_id) || @getDefaultGradingScheme()

    ## Gradebook Content Access Methods

    setSections: (sections) =>
      @sections = _.indexBy(sections, 'id')
      @sections_enabled = sections.length > 1

    setAssignments: (assignmentMap) =>
      @assignments = assignmentMap

    setAssignmentGroups: (assignmentGroupMap) =>
      @assignmentGroups = assignmentGroupMap

    getAssignment: (assignmentId) =>
      @assignments[assignmentId]

    getAssignmentGroup: (assignmentGroupId) =>
      @assignmentGroups[assignmentGroupId]

    getCustomColumn: (customColumnId) =>
      @gradebookContent.customColumns.find((column) -> column.id == customColumnId)

    getTeacherNotesColumn: =>
      @gradebookContent.customColumns.find((column) -> column.teacher_notes)

    listVisibleCustomColumns: ->
      @gradebookContent.customColumns.filter((column) -> !column.hidden)

    setContextModules: (contextModules) =>
      @courseContent.contextModules = contextModules
      @courseContent.modulesById = {}

      if contextModules?.length
        for contextModule in contextModules
          @courseContent.modulesById[contextModule.id] = contextModule

      contextModules

    onLatePolicyUpdate: (latePolicy) =>
      @setLatePolicy(latePolicy)
      @applyLatePolicy()

    setLatePolicy: (latePolicy) =>
      @courseContent.latePolicy = latePolicy

    applyLatePolicy: =>
      latePolicy = @courseContent?.latePolicy
      gradingStandard = @options.grading_standard || @options.default_grading_standard
      studentsToInvalidate = {}

      forEachSubmission(@students, (submission) =>
        assignment = @assignments[submission.assignment_id]
        student = @student(submission.user_id)
        return if student?.isConcluded
        return if @getGradingPeriod(submission.grading_period_id)?.isClosed
        if LatePolicyApplicator.processSubmission(submission, assignment, gradingStandard, latePolicy)
          studentsToInvalidate[submission.user_id] = true
      )
      studentIds = _.uniq(Object.keys(studentsToInvalidate))
      studentIds.forEach (studentId) =>
        @calculateStudentGrade(@students[studentId])
      @invalidateRowsForStudentIds(studentIds)

    getContextModule: (contextModuleId) =>
      @courseContent.modulesById?[contextModuleId] if contextModuleId?

    listContextModules: =>
      @courseContent.contextModules

    ## Assignment UI Action Methods

    getDownloadSubmissionsAction: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      manager = new DownloadSubmissionsDialogManager(
        assignment,
        @options.download_assignment_submissions_url,
        @handleSubmissionsDownloading
      )

      {
        hidden: !manager.isDialogEnabled()
        onSelect: manager.showDialog
      }

    getReuploadSubmissionsAction: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      manager = new ReuploadSubmissionsDialogManager(
        assignment,
        @options.re_upload_submissions_url
      )

      {
        hidden: !manager.isDialogEnabled()
        onSelect: manager.showDialog
      }

    getSetDefaultGradeAction: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      manager = new SetDefaultGradeDialogManager(
        assignment,
        @studentsThatCanSeeAssignment(assignmentId),
        @options.context_id,
        @getFilterRowsBySetting('sectionId'),
        isAdmin(),
        @contentLoadStates.submissionsLoaded
      )

      {
        disabled: !manager.isDialogEnabled()
        onSelect: manager.showDialog
      }

    getCurveGradesAction: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      CurveGradesDialogManager.createCurveGradesAction(
        assignment,
        @studentsThatCanSeeAssignment(assignmentId),
        {
          isAdmin: isAdmin()
          contextUrl: @options.context_url
          submissionsLoaded: @contentLoadStates.submissionsLoaded
        }
      )

    getMuteAssignmentAction: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      manager = new AssignmentMuterDialogManager(
        assignment,
        "#{@options.context_url}/assignments/#{assignmentId}/mute",
        @contentLoadStates.submissionsLoaded
      )

      {
        disabled: !manager.isDialogEnabled()
        onSelect: manager.showDialog
      }

    ## Gradebook Content Api Methods

    createTeacherNotes: =>
      @setTeacherNotesColumnUpdating(true)
      @renderViewOptionsMenu()
      GradebookApi.createTeacherNotesColumn(@options.context_id)
        .then (response) =>
          @gradebookContent.customColumns.push(response.data)
          teacherNotesColumn = @buildCustomColumn(response.data)
          @gridData.columns.definitions[teacherNotesColumn.id] = teacherNotesColumn
          @showNotesColumn()
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()
        .catch (error) =>
          $.flashError I18n.t('There was a problem creating the teacher notes column.')
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()

    setTeacherNotesHidden: (hidden) =>
      @setTeacherNotesColumnUpdating(true)
      @renderViewOptionsMenu()
      teacherNotes = @getTeacherNotesColumn()
      GradebookApi.updateTeacherNotesColumn(@options.context_id, teacherNotes.id, { hidden })
        .then =>
          if hidden
            @hideNotesColumn()
          else
            @showNotesColumn()
            @reorderCustomColumns(@gradebookContent.customColumns.map (c) -> c.id)
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()
        .catch (error) =>
          if hidden
            $.flashError I18n.t('There was a problem hiding the teacher notes column.')
          else
            $.flashError I18n.t('There was a problem showing the teacher notes column.')
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()

    apiUpdateSubmission: (submission, gradeInfo) =>
      { userId, assignmentId } = submission
      student = @student(userId)
      @addPendingGradeInfo(submission, gradeInfo)
      @renderSubmissionTray(student) if @getSubmissionTrayState().open
      GradebookApi.updateSubmission(@options.context_id, assignmentId, userId, submission)
        .then((response) =>
          @removePendingGradeInfo(submission)
          @updateSubmissionsFromExternal(response.data.all_submissions)
          @renderSubmissionTray(student) if @getSubmissionTrayState().open
          response
        ).catch((response) =>
          @removePendingGradeInfo(submission)
          @updateRowCellsForStudentIds([userId])
          $.flashError I18n.t('There was a problem updating the submission.')
          @renderSubmissionTray(student) if @getSubmissionTrayState().open
          Promise.reject(response)
        )

    gradeSubmission: (submission, gradeInfo) =>
      if gradeInfo.valid
        gradeChangeOptions =
          enterGradesAs: @getEnterGradesAsSetting(submission.assignmentId)
          gradingScheme: @getAssignmentGradingScheme(submission.assignmentId).data
          pointsPossible: @getAssignment(submission.assignmentId).points_possible

        if GradeInputHelper.hasGradeChanged(submission, gradeInfo, gradeChangeOptions)
          submissionData =
            assignmentId: submission.assignmentId
            userId: submission.userId

          if gradeInfo.excused
            submissionData.excuse = true
          else if gradeInfo.enteredAs == null
            submissionData.posted_grade = ''
          else if ['passFail', 'gradingScheme'].includes(gradeInfo.enteredAs)
            submissionData.posted_grade = gradeInfo.grade
          else
            submissionData.posted_grade = gradeInfo.score

          @apiUpdateSubmission(submissionData, gradeInfo)
            .then((response) =>
              assignment = @getAssignment(submission.assignmentId)
              outlierScoreHelper = new OutlierScoreHelper(response.data.score, assignment.points_possible)
              $.flashWarning(outlierScoreHelper.warningMessage()) if outlierScoreHelper.hasWarning()
            )
        else
          @removePendingGradeInfo(submission)
          @updateRowCellsForStudentIds([submission.userId])
          @renderSubmissionTray() if @getSubmissionTrayState().open
      else
        FlashAlert.showFlashAlert({
          message: I18n.t('You have entered an invalid grade for this student. Check the value and the grading type and try again.'),
          type: 'error'
        })
        @addPendingGradeInfo(submission, gradeInfo)
        @updateRowCellsForStudentIds([submission.userId])
        @renderSubmissionTray() if @getSubmissionTrayState().open

    updateSubmissionAndRenderSubmissionTray: (data) =>
      { studentId, assignmentId } = @getSubmissionTrayState()
      submissionData = Object.assign({
        assignmentId: assignmentId
        userId: studentId
      }, data)

      submission = @getSubmission(studentId, assignmentId)

      gradeInfo =
        excused: submission.excused
        grade: submission.entered_grade
        score: submission.entered_score
        valid: true

      @apiUpdateSubmission(submissionData, gradeInfo)

    renderAnonymousSpeedGraderAlert: (props) =>
      renderComponent(AnonymousSpeedGraderAlert, anonymousSpeedGraderAlertMountPoint(), props)

    showAnonymousSpeedGraderAlertForURL: (speedGraderUrl) =>
      props = { speedGraderUrl, onClose: @hideAnonymousSpeedGraderAlert }
      @anonymousSpeedGraderAlert = @renderAnonymousSpeedGraderAlert(props)
      @anonymousSpeedGraderAlert.open()

    hideAnonymousSpeedGraderAlert: =>
      # React throws an error if we try to unmount while the event is being handled
      @delayedCall 0, => ReactDOM.unmountComponentAtNode(anonymousSpeedGraderAlertMountPoint())

    destroy: =>
      $(window).unbind('resize.fillWindowWithMe')
      $(document).unbind('gridready')
      @gradebookGrid.destroy()

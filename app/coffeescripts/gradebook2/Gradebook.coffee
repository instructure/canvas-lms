# This class both creates the slickgrid instance, and acts as the data source for that instance.
define [
  'jsx/gradebook2/DataLoader'
  'react'
  'slickgrid.long_text_editor'
  'compiled/views/KeyboardNavDialog'
  'jst/KeyboardNavDialog'
  'vendor/slickgrid'
  'compiled/gradebook2/TotalColumnHeaderView'
  'compiled/util/round'
  'compiled/views/InputFilterView'
  'i18n!gradebook2'
  'compiled/gradebook2/GRADEBOOK_TRANSLATIONS'
  'jquery'
  'underscore'
  'Backbone'
  'timezone'
  'compiled/grade_calculator'
  'compiled/userSettings'
  'vendor/spin'
  'compiled/SubmissionDetailsDialog'
  'compiled/gradebook2/AssignmentGroupWeightsDialog'
  'compiled/gradebook2/GradeDisplayWarningDialog'
  'compiled/gradebook2/PostGradesFrameDialog'
  'compiled/gradebook2/SubmissionCell'
  'compiled/gradebook2/GradebookHeaderMenu'
  'compiled/util/NumberCompare'
  'str/htmlEscape'
  'jsx/gradebook/SISGradePassback/PostGradesStore'
  'jsx/gradebook/SISGradePassback/PostGradesApp'
  'jst/gradebook2/column_header'
  'jst/gradebook2/group_total_cell'
  'jst/gradebook2/row_student_name'
  'compiled/views/gradebook/SectionMenuView'
  'compiled/views/gradebook/GradingPeriodMenuView'
  'compiled/gradebook2/GradebookKeyboardNav'
  'jsx/gradebook/grid/helpers/columnArranger'
  'jst/_avatar' #needed by row_student_name
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jqueryui/dialog'
  'jqueryui/tooltip'
  'compiled/behaviors/tooltip'
  'compiled/behaviors/activate'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'jqueryui/mouse'
  'jqueryui/position'
  'jqueryui/sortable'
  'compiled/jquery.kylemenu'
  'compiled/jquery/fixDialogButtons'
], (loadGradebookData, React, LongTextEditor, KeyboardNavDialog, keyboardNavTemplate, Slick, TotalColumnHeaderView, round, InputFilterView, I18n, GRADEBOOK_TRANSLATIONS,
  $, _, Backbone, tz, GradeCalculator, userSettings, Spinner, SubmissionDetailsDialog, AssignmentGroupWeightsDialog, GradeDisplayWarningDialog, PostGradesFrameDialog,
  SubmissionCell, GradebookHeaderMenu, numberCompare, htmlEscape, PostGradesStore, PostGradesApp, columnHeaderTemplate,
  groupTotalCellTemplate, rowStudentNameTemplate, SectionMenuView, GradingPeriodMenuView, GradebookKeyboardNav, ColumnArranger) ->

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
        max: 110

    hasSections: $.Deferred()
    gridReady: $.Deferred()

    constructor: (@options) ->
      @students = {}
      @studentViewStudents = {}
      @rows = []
      @assignmentsToHide = userSettings.contextGet('hidden_columns') || []
      @sectionToShow = userSettings.contextGet 'grading_show_only_section'
      @sectionToShow = @sectionToShow && String(@sectionToShow)
      @show_attendance = !!userSettings.contextGet 'show_attendance'
      @include_ungraded_assignments = userSettings.contextGet 'include_ungraded_assignments'
      @userFilterRemovedRows = []
      # preferenecs serialization causes these to always come
      # from the database as strings
      @showConcludedEnrollments = @options.course_is_concluded ||
        @options.settings['show_concluded_enrollments'] == "true"
      @showInactiveEnrollments =
        @options.settings['show_inactive_enrollments'] == "true"
      @totalColumnInFront = userSettings.contextGet 'total_column_in_front'
      @numberOfFrozenCols = if @totalColumnInFront then 3 else 2
      @mgpEnabled = @options.multiple_grading_periods_enabled
      @gradingPeriods = @options.active_grading_periods
      @indexedGradingPeriods = _.indexBy @gradingPeriods, 'id'
      @gradingPeriodToShow = @getGradingPeriodToShow()
      @gradebookColumnSizeSettings = @options.gradebook_column_size_settings
      @gradebookColumnOrderSettings = @options.gradebook_column_order_settings

      $.subscribe 'assignment_group_weights_changed', @handleAssignmentGroupWeightChange
      $.subscribe 'assignment_muting_toggled',        @handleAssignmentMutingChange
      $.subscribe 'submissions_updated',              @updateSubmissionsFromExternal
      $.subscribe 'currentSection/change',            @updateCurrentSection
      $.subscribe 'currentGradingPeriod/change',      @updateCurrentGradingPeriod

      assignmentGroupsParams = { exclude_response_fields: @fieldsToExcludeFromAssignments }
      if @mgpEnabled && @gradingPeriodToShow && @gradingPeriodToShow != '0' && @gradingPeriodToShow != ''
        $.extend(assignmentGroupsParams, {grading_period_id: @gradingPeriodToShow})

      $('li.external-tools-dialog > a[data-url], button.external-tools-dialog').on 'click keyclick', (event) ->
        postGradesDialog = new PostGradesFrameDialog({
          returnFocusTo: $('#post_grades'),
          baseUrl: $(event.target).attr('data-url')
        })
        postGradesDialog.open()

      submissionParams =
        response_fields: ['id', 'user_id', 'url', 'score', 'grade', 'submission_type', 'submitted_at', 'assignment_id', 'grade_matches_current_submission', 'attachments', 'late', 'workflow_state', 'excused']
        exclude_response_fields: ['preview_url']
      submissionParams['grading_period_id'] = @gradingPeriodToShow if @mgpEnabled && @gradingPeriodToShow && @gradingPeriodToShow != '0' && @gradingPeriodToShow != ''
      dataLoader = loadGradebookData(
        assignmentGroupsURL: @options.assignment_groups_url
        assignmentGroupsParams: assignmentGroupsParams

        customColumnsURL: @options.custom_columns_url

        sectionsURL: @options.sections_url

        studentsURL: @options[@studentsUrl()]
        studentsPageCb: @gotChunkOfStudents

        submissionsURL: @options.submissions_url
        submissionsParams: submissionParams
        submissionsChunkCb: @gotSubmissionsChunk
        submissionsChunkSize: @options.chunk_size
        customColumnDataURL: @options.custom_column_data_url
        customColumnDataPageCb: @gotCustomColumnDataChunk
      )

      dataLoader.gotAssignmentGroups.then @gotAllAssignmentGroups
      dataLoader.gotCustomColumns.then @gotCustomColumns
      dataLoader.gotStudents.then @gotAllStudents

      $.when(dataLoader.gotCustomColumns,
             dataLoader.gotAssignmentGroups).then(@doSlickgridStuff)

      @assignmentGroupsLoaded = dataLoader.gotAssignmentGroups
      @studentsLoaded = dataLoader.gotStudents
      @allSubmissionsLoaded = dataLoader.gotSubmissions

      @showCustomColumnDropdownOption()
      @initPostGradesStore()
      @showPostGradesButton()
      @checkForUploadComplete()

      @gotSections(@options.sections)

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
        @grid.invalidateRow(student.row)

      @grid.render()

    hiddenStudentIdsForAssignment: (studentIds, assignment) ->
      # TODO: _.difference is ridic expensive.  may need to do something else
      # for large courses with DA (does that happen?)
      _.difference studentIds, assignment.assignment_visibility

    updateAssignmentVisibilities: (hiddenSub) ->
      assignment = @assignments[hiddenSub.assignment_id]
      filteredVisibility = assignment.assignment_visibility.filter (id) -> id != hiddenSub.user_id
      assignment.assignment_visibility = filteredVisibility

    # dependencies - assignmentGroupsLoaded
    disableAssignmentsInClosedGradingPeriods: () ->
      closedAdminGradingPeriods = @getClosedAdminGradingPeriods()

      if closedAdminGradingPeriods.length > 0
        assignments = @getAssignmentsInClosedGradingPeriods()
        @disabledAssignments = assignments.map (a) -> a.id

    getClosedAdminGradingPeriods: () ->
      _.select @gradingPeriods, (gradingPeriod) =>
        @gradingPeriodIsAdmin(gradingPeriod) && @gradingPeriodIsClosed(gradingPeriod)

    gradingPeriodIsAdmin: (gradingPeriod) ->
      !gradingPeriod.permissions.update

    gradingPeriodIsClosed: (gradingPeriod) ->
      new Date(gradingPeriod.end_date) < new Date()

    gradingPeriodIsActive: (gradingPeriodId) ->
      activePeriodIds = _.pluck(@gradingPeriods, 'id')
      _.contains(activePeriodIds, gradingPeriodId)

    getGradingPeriodToShow: () =>
      currentPeriodId = userSettings.contextGet('gradebook_current_grading_period')
      if currentPeriodId && (@isAllGradingPeriods(currentPeriodId) || @gradingPeriodIsActive(currentPeriodId))
        currentPeriodId
      else
        @options.current_grading_period_id

    getAssignmentsInClosedGradingPeriods: () ->
      latestEndDate = new Date(@options.latest_end_date_of_admin_created_grading_periods_in_the_past)
      #return assignments whose end date is within the latest closed's end date
      _.select @assignments, (a) =>
        @assignmentIsDueBeforeEndDate(a, latestEndDate)

    assignmentIsDueBeforeEndDate: (assignment, gradingPeriodEndDate) ->
      if assignment.due_at
        new Date(assignment.due_at) <= gradingPeriodEndDate
      else
        false

    onShow: ->
      $(".post-grades-button-placeholder").show()
      return if @startedInitializing
      @startedInitializing = true

      @spinner = new Spinner() unless @spinner
      $(@spinner.spin().el).css(
        opacity: 0.5
        top: '55px'
        left: '50%'
      ).addClass('use-css-transitions-for-show-hide').appendTo('#main')
      $('#gradebook-grid-wrapper').hide()

    gotCustomColumns: (columns) =>
      @numberOfFrozenCols += columns.length
      @customColumns = columns

    gotCustomColumnDataChunk: (column, columnData) =>
      for datum in columnData
        student = @student(datum.user_id)
        if student? #ignore filtered students
          student["custom_col_#{column.id}"] = datum.content
          @grid?.invalidateRow(student.row)
      @grid?.render()

    doSlickgridStuff: =>
      @initGrid()
      @initHeader()
      @gridReady.resolve()

    gotAllAssignmentGroups: (assignmentGroups) =>
      @assignmentGroups = {}
      @assignments      = {}

      # purposely passing the @options and assignmentGroups by reference so it can update
      # an assigmentGroup's .group_weight and @options.group_weighting_scheme
      new AssignmentGroupWeightsDialog context: @options, assignmentGroups: assignmentGroups
      for group in assignmentGroups
        @assignmentGroups[group.id] = group
        group.assignments = _.select group.assignments, (a) -> a.published
        for assignment in group.assignments
          assignment.assignment_group = group
          assignment.due_at = tz.parse(assignment.due_at)
          @assignments[assignment.id] = assignment
      @postGradesStore.setGradeBookAssignments @assignments

      @disableAssignmentsInClosedGradingPeriods() if @mgpEnabled

    initializeSubmissionsForStudent: (student) =>
      for assignment_id, assignment of @assignments
        student["assignment_#{assignment_id}"] ?= { assignment_id: assignment_id, user_id: student.id }
        submission = student["assignment_#{assignment_id}"]

        if @submissionOutsideOfGradingPeriod(submission, student)
          submission.hidden = true
          submission.outsideOfGradingPeriod = true

      student.initialized = true
      @calculateStudentGrade(student)
      @grid?.invalidateRow(student.row)

    gotSections: (sections) =>
      @sections = {}
      for section in sections
        htmlEscape(section)
        @sections[section.id] = section

      @sections_enabled = sections.length > 1
      @hasSections.resolve()

      @postGradesStore.setSections @sections

    gotChunkOfStudents: (students) =>
      for student in students
        student.enrollments = _.filter student.enrollments, @isStudentEnrollment
        isStudentView = student.enrollments[0].type == "StudentViewEnrollment"
        student.sections = student.enrollments.map (e) -> e.course_section_id

        if isStudentView
          @studentViewStudents[student.id] ||= htmlEscape(student)
        else
          @students[student.id] ||= htmlEscape(student)
          @addRow(student)  # not adding student view students until all students have loaded

      @gridReady.then =>
        @setupGrading(students)

      @grid?.render()

    isStudentEnrollment: (e) =>
      e.type == "StudentEnrollment" || e.type == "StudentViewEnrollment"

    setupGrading: (students) =>
      # fill in dummy submissions, so there's something there even if the
      # student didn't submit anything for that assignment
      for student in students
        @initializeSubmissionsForStudent(student)

      @setAssignmentVisibility(_.pluck(students, 'id'))

      @grid.render()

    rowIndex: 0
    addRow: (student) =>
      student.computed_current_score ||= 0
      student.computed_final_score ||= 0
      student.secondary_identifier = student.sis_login_id || student.login_id

      student.isConcluded = _.all student.enrollments, (e) ->
        e.enrollment_state == 'completed'
      student.isInactive = _.all student.enrollments, (e) ->
        e.enrollment_state == 'inactive'

      if @sections_enabled
        mySections = (@sections[sectionId].name for sectionId in student.sections when @sections[sectionId])
        sectionNames = $.toSentence(mySections.sort())

      displayName = if @options.list_students_by_sortable_name_enabled
        student.sortable_name
      else
        student.name

      enrollmentStatus = if student.isConcluded
        I18n.t 'concluded'
      else if student.isInactive
        I18n.t 'inactive'

      student.display_name = rowStudentNameTemplate
        avatar_url: student.avatar_url
        display_name: displayName
        enrollment_status: enrollmentStatus
        url: student.enrollments[0].grades.html_url+'#tab-assignments'
        sectionNames: sectionNames
        alreadyEscaped: true

      if @rowFilter(student)
        student.row = @rowIndex
        @rowIndex++
        @rows.push(student)

      @grid?.updateRowCount(@rows.length)

    gotAllStudents: =>
      # add test students
      _.each _.values(@studentViewStudents), (testStudent) =>
        @addRow(testStudent)

    defaultSortType: 'assignment_group'

    studentsThatCanSeeAssignment: (potential_students, assignment) ->
      if assignment.only_visible_to_overrides
        _.pick potential_students, assignment.assignment_visibility...
      else
        potential_students

    isInvalidCustomSort: =>
      sortSettings = @gradebookColumnOrderSettings
      sortSettings && sortSettings.sortType == 'custom' && !sortSettings.customOrder

    columnOrderHasNotBeenSaved: =>
      !@gradebookColumnOrderSettings

    getStoredSortOrder: =>
      if @isInvalidCustomSort() || @columnOrderHasNotBeenSaved()
        {sortType: @defaultSortType}
      else
        @gradebookColumnOrderSettings

    setStoredSortOrder: (newSortOrder) ->
      @gradebookColumnOrderSettings = newSortOrder
      unless @isInvalidCustomSort()
        url = @options.gradebook_column_order_settings_url
        $.ajaxJSON(url, 'POST', {column_order: newSortOrder})

    onColumnsReordered: =>
      # determine if assignment columns or custom columns were reordered
      # (this works because frozen columns and non-frozen columns are can't be
      # swapped)
      columns = @grid.getColumns()
      currentIds = _(@customColumns).map (c) -> c.id
      reorderedIds = (m[1] for c in columns when m = c.id.match /^custom_col_(\d+)/)

      if !_.isEqual(reorderedIds, currentIds)
        @reorderCustomColumns(reorderedIds)
        .then =>
          colsById = _(@customColumns).indexBy (c) -> c.id
          @customColumns = _(reorderedIds).map (id) -> colsById[id]
      else
        @storeCustomColumnOrder()

      @fixColumnReordering()

    reorderCustomColumns: (ids) ->
      $.ajaxJSON(@options.reorder_custom_columns_url, "POST", order: ids)

    storeCustomColumnOrder: =>
      newSortOrder =
        sortType: 'custom'
        customOrder: []
      columns = @grid.getColumns()
      assignment_columns = _.filter(columns, (c) -> c.type is 'assignment')
      newSortOrder.customOrder = _.map(assignment_columns, (a) -> a.object.id)
      @setStoredSortOrder(newSortOrder)

    setArrangementTogglersVisibility: (newSortOrder) =>
      @$columnArrangementTogglers.each ->
        $(this).closest('li').showIf $(this).data('arrangeColumnsBy') isnt newSortOrder.sortType

    arrangeColumnsBy: (newSortOrder, isFirstArrangement) =>
      @setArrangementTogglersVisibility(newSortOrder)
      @setStoredSortOrder(newSortOrder) unless isFirstArrangement

      columns = @grid.getColumns()
      frozen = columns.splice(0, @numberOfFrozenCols)
      columns.sort @makeColumnSortFn(newSortOrder)
      columns.splice(0, 0, frozen...)
      @grid.setColumns(columns)

      @fixColumnReordering()

    makeColumnSortFn: (sortOrder) =>
      fn = switch sortOrder.sortType
        when 'assignment_group', 'alpha' then @compareAssignmentPositions
        when 'due_date' then @compareAssignmentDueDates
        when 'custom' then @makeCompareAssignmentCustomOrderFn(sortOrder)
        else throw "unhandled column sort condition"
      @wrapColumnSortFn(fn)

    compareAssignmentPositions: (a, b) ->
      diffOfAssignmentGroupPosition = a.object.assignment_group.position - b.object.assignment_group.position
      diffOfAssignmentPosition = a.object.position - b.object.position

      # order first by assignment_group position and then by assignment position
      # will work when there are less than 1000000 assignments in an assignment_group
      return (diffOfAssignmentGroupPosition * 1000000) + diffOfAssignmentPosition

    compareAssignmentDueDates: (a, b) ->
      firstAssignment = a.object
      secondAssignment = b.object
      ColumnArranger.compareByDueDate(firstAssignment, secondAssignment)

    makeCompareAssignmentCustomOrderFn: (sortOrder) =>
      sortMap = {}
      indexCounter = 0
      for assignmentId in sortOrder.customOrder
        sortMap[String(assignmentId)] = indexCounter
        indexCounter += 1
      return (a, b) =>
        aIndex = sortMap[String(a.object.id)]
        bIndex = sortMap[String(b.object.id)]
        if aIndex? and bIndex?
          return aIndex - bIndex
        # if there's a new assignment and its order has not been stored, it should come at the end
        else if aIndex? and not bIndex?
          return -1
        else if bIndex?
          return 1
        else
          return @compareAssignmentPositions(a, b)

    wrapColumnSortFn: (wrappedFn) ->
      (a, b) ->
        return -1 if b.type is 'total_grade'
        return  1 if a.type is 'total_grade'
        return -1 if b.type is 'assignment_group' and a.type isnt 'assignment_group'
        return  1 if a.type is 'assignment_group' and b.type isnt 'assignment_group'
        if a.type is 'assignment_group' and b.type is 'assignment_group'
          return a.object.position - b.object.position
        return wrappedFn(a, b)

    rowFilter: (student) =>
      matchingSection = !@sectionToShow || (@sectionToShow in student.sections)
      matchingFilter = if @userFilterTerm == ""
        true
      else
        propertiesToMatch = ['name', 'login_id', 'short_name', 'sortable_name']
        pattern = new RegExp @userFilterTerm, 'i'
        matched = _.any propertiesToMatch, (prop) ->
          student[prop]?.match pattern

      matchingSection and matchingFilter

    handleAssignmentMutingChange: (assignment) =>
      idx = @grid.getColumnIndex("assignment_#{assignment.id}")
      colDef = @grid.getColumns()[idx]
      colDef.name = @assignmentHeaderHtml(assignment)
      @grid.setColumns(@grid.getColumns())
      @fixColumnReordering()
      @buildRows()

    handleAssignmentGroupWeightChange: (assignment_group_options) =>
      columns = @grid.getColumns()
      for assignment_group in assignment_group_options.assignmentGroups
        column = _.findWhere columns, id: "assignment_group_#{assignment_group.id}"
        column.name = @assignmentGroupHtml(column.object.name, column.object.group_weight)
      @setAssignmentWarnings()
      @grid.setColumns(columns)
      @renderTotalHeader()
      # TODO: don't buildRows?
      @buildRows()

    renderTotalHeader: () =>
      @totalHeader = new TotalColumnHeaderView
        showingPoints: @displayPointTotals()
        toggleShowingPoints: @togglePointsOrPercentTotals.bind(this)
        weightedGroups: @weightedGroups
        totalColumnInFront: @totalColumnInFront
        moveTotalColumn: @moveTotalColumn.bind(this)
      @totalHeader.render()

    moveTotalColumn: =>
      @totalColumnInFront = not @totalColumnInFront
      userSettings.contextSet 'total_column_in_front', @totalColumnInFront
      window.location.reload()

    assignmentGroupHtml: (group_name, group_weight) =>
      if @weightedGroups()
        percentage = I18n.toPercentage(group_weight, precision: 2)
        """
          #{htmlEscape(group_name)}<div class='assignment-points-possible'>
            #{htmlEscape I18n.t 'percent_of_grade', "%{percentage} of grade", percentage: percentage}
          </div>
        """
      else
        htmlEscape(group_name)

    # filter, sort, and build the dataset for slickgrid to read from, then
    # force a full redraw
    buildRows: =>
      @rows.length = 0

      for id, column of @grid.getColumns() when ''+column.object?.submission_types is "attendance"
        column.unselectable = !@show_attendance
        column.cssClass = if @show_attendance then '' else 'completely-hidden'
        @$grid.find("##{@uid}#{column.id}").showIf(@show_attendance)

      @withAllStudents (students) =>
        @rowIndex = 0
        for id, student of @students
          student.row = -1
          if @rowFilter(student)
            student.row = @rowIndex
            @rowIndex += 1
            @rows.push(student)
            @calculateStudentGrade(student) # TODO: this may not be necessary

      @grid.updateRowCount(@rows.length)

      @sortRowsBy (a, b) => @localeSort(a.sortable_name, b.sortable_name)

    gotSubmissionsChunk: (student_submissions) =>
      for data in student_submissions
        student = @student(data.user_id)
        for submission in data.submissions
          @updateSubmission(submission)

        student.loaded = true

        if @grid
          @calculateStudentGrade(student)
          @grid.invalidateRow(student.row)

      # TODO: if gb2 survives long enough, we should consider debouncing all
      # the invalidation/rendering for smoother performance while loading
      @grid?.render()

    student: (id) =>
      @students[id] || @studentViewStudents[id]

    # @students contains all *real* students (e.g., not the student view student)
    # when you do need to operate on *all* students (like for rendering the grid), use
    # function
    withAllStudents: (f) =>
      for id, s of @studentViewStudents
        @students[id] = s

      f(@students)

      for id, s of @studentViewStudents
        delete @students[id]

    updateSubmission: (submission) =>
      student = @student(submission.user_id)
      submission.submitted_at = tz.parse(submission.submitted_at)
      cell = student["assignment_#{submission.assignment_id}"] ||= {}
      _.extend(cell, submission)

    # this is used after the CurveGradesDialog submit xhr comes back.  it does not use the api
    # because there is no *bulk* submissions#update endpoint in the api.
    # It is different from gotSubmissionsChunk in that gotSubmissionsChunk expects an array of students
    # where each student has an array of submissions.  This one just expects an array of submissions,
    # they are not grouped by student.
    updateSubmissionsFromExternal: (submissions, submissionCell) =>
      activeCell = @grid.getActiveCell()
      editing = $(@grid.getActiveCellNode()).hasClass('editable')
      columns = @grid.getColumns()
      for submission in submissions
        student = @student(submission.user_id)
        idToMatch = "assignment_#{submission.assignment_id}"
        cell = index for column, index in columns when column.id is idToMatch
        thisCellIsActive = activeCell? and
          editing and
          activeCell.row is student.row and
          activeCell.cell is cell
        #check for DA visible
        if submission.assignment_visible?
          submission.hidden = !submission.assignment_visible

        if @submissionOutsideOfGradingPeriod(submission, student)
          submission.hidden = true
          submission.outsideOfGradingPeriod = true

        if submission.hidden
          @updateAssignmentVisibilities(submission)

        @updateSubmission(submission)
        @calculateStudentGrade(student)
        @grid.updateCell student.row, cell unless thisCellIsActive
        @updateRowTotals student.row

    updateRowTotals: (rowIndex) ->
      columns = @grid.getColumns()
      for column, columnIndex in columns
        @grid.updateCell rowIndex, columnIndex if column.type isnt 'assignment'

    cellFormatter: (row, col, submission) =>
      if !@rows[row].loaded or !@rows[row].initialized
        @staticCellFormatter(row, col, '')
      else
        if submission.outsideOfGradingPeriod
          @uneditableCellOutsideOfGradingPeriodFormatter(row, col)
        else if submission.hidden
          @uneditableCellFormatter(row, col)
        else if !submission?
          @staticCellFormatter(row, col, '-')
        else
          assignment = @assignments[submission.assignment_id]
          student = @students[submission.user_id]

          if !assignment?
            @staticCellFormatter(row, col, '')
          else if submission.workflow_state == 'pending_review'
           (SubmissionCell[assignment.grading_type] || SubmissionCell).formatter(row, col, submission, assignment, student)
          else if assignment.grading_type == 'points' && assignment.points_possible
            SubmissionCell.out_of.formatter(row, col, submission, assignment, student)
          else
            (SubmissionCell[assignment.grading_type] || SubmissionCell).formatter(row, col, submission, assignment, student)

    indexedOverrides: =>
      @_indexedOverrides ||= (=>
        indexed = {
          studentOverrides: {},
          groupOverrides: {},
          sectionOverrides: {}
        }

        _.each @assignments, (assignment) ->
          if assignment.has_overrides && assignment.overrides
            _.each assignment.overrides, (override) ->
              if override.student_ids
                indexed.studentOverrides[assignment.id] ?= {}
                _.each override.student_ids, (studentId) ->
                  indexed.studentOverrides[assignment.id][studentId] = override
              else if sectionId = override.course_section_id
                indexed.sectionOverrides[assignment.id] ?= {}
                indexed.sectionOverrides[assignment.id][sectionId] = override
              else if groupId = override.group_id
                indexed.groupOverrides[assignment.id] ?= {}
                indexed.groupOverrides[assignment.id][groupId] = override

        indexed
      )()

    # depedencies: assignmentGroupsLoaded
    submissionOutsideOfGradingPeriod: (submission, student) ->
      return false unless @mgpEnabled
      selectedPeriodId = @gradingPeriodToShow
      return false if @isAllGradingPeriods(selectedPeriodId)

      assignment = @assignments[submission.assignment_id]
      gradingPeriod = @indexedGradingPeriods[selectedPeriodId]
      effectiveDueAt = assignment.due_at

      if assignment.has_overrides && assignment.overrides
        IDsByOverrideType = {
          "sectionOverrides": student.sections
          "groupOverrides": student.group_ids
          "studentOverrides": [student.id]
        }

        getOverridesForType = ((typeIds, overrideType) =>
          _.map typeIds, (typeId) =>
            @indexedOverrides()[overrideType]?[assignment.id]?[typeId]).bind(this)

        allOverridesForSubmission = _.chain(IDsByOverrideType)
          .map(getOverridesForType)
          .flatten()
          .compact()
          .value()

        overrideDates = _.chain(allOverridesForSubmission)
          .pluck('due_at')
          .map((dateString) -> tz.parse(dateString))
          .value()

        if overrideDates.length > 0
          nullDueAtsExist = _.any(overrideDates, (date) -> _.isNull(date))
          effectiveDueAt = if nullDueAtsExist then null else _.max(overrideDates)
        else
          return true if assignment.only_visible_to_overrides

      showSubmission = @lastGradingPeriodAndDueAtNull(gradingPeriod, effectiveDueAt) || @dateIsInGradingPeriod(gradingPeriod, effectiveDueAt)
      !showSubmission

    lastGradingPeriodAndDueAtNull: (gradingPeriod, dueAt) ->
      gradingPeriod.is_last && _.isNull(dueAt)

    dateIsInGradingPeriod: (gradingPeriod, date) ->
      return false if _.isNull(date)
      startDate = tz.parse(gradingPeriod.start_date)
      endDate = tz.parse(gradingPeriod.end_date)
      startDate < date && date <= endDate

    staticCellFormatter: (row, col, val) ->
      "<div class='cell-content gradebook-cell'>#{htmlEscape(val)}</div>"

    uneditableCellOutsideOfGradingPeriodFormatter: (row, col) ->
      """
        <div class='gradebook-tooltip'>
          #{htmlEscape(I18n.t("Submission in another grading period"))}
        </div>
        <div class='cell-content gradebook-cell grayed-out cannot_edit'></div>
      """

    uneditableCellFormatter: (row, col) ->
      "<div class='cell-content gradebook-cell grayed-out cannot_edit'></div>"

    groupTotalFormatter: (row, col, val, columnDef, student) =>
      return '' unless val?

      percentage = @calculateAndRoundGroupTotalScore val.score, val.possible
      percentage = 0 if isNaN(percentage)

      if val.possible and @options.grading_standard and columnDef.type is 'total_grade'
        letterGrade = GradeCalculator.letter_grade(@options.grading_standard, percentage)

      templateOpts =
        score: round(val.score, round.DEFAULT)
        possible: round(val.possible, round.DEFAULT)
        letterGrade: letterGrade
        percentage: percentage
      if columnDef.type == 'total_grade'
        templateOpts.warning = @totalGradeWarning
        templateOpts.lastColumn = true
        templateOpts.showPointsNotPercent = @displayPointTotals()
        templateOpts.hideTooltip = @weightedGroups() and not @totalGradeWarning
      groupTotalCellTemplate templateOpts

    htmlContentFormatter: (row, col, val, columnDef, student) ->
      return '' unless val?
      val

    calculateAndRoundGroupTotalScore: (score, possible_points) ->
      grade = (score / possible_points) * 100
      round(grade, round.DEFAULT)

    calculateStudentGrade: (student) =>
      if student.loaded and student.initialized
        finalOrCurrent = if @include_ungraded_assignments then 'final' else 'current'
        submissionsAsArray = (value for key, value of student when key.match /^assignment_(?!group)/)
        result = GradeCalculator.calculate(submissionsAsArray, @assignmentGroups, @options.group_weighting_scheme)
        for group in result.group_sums
          student["assignment_group_#{group.group.id}"] = group[finalOrCurrent]
          for submissionData in group[finalOrCurrent].submissions
            submissionData.submission.drop = submissionData.drop
        student["total_grade"] = result[finalOrCurrent]

        @addDroppedClass(student)

    addDroppedClass: (student) ->
      droppedAssignments = (name for name, assignment of student when name.match(/assignment_\d+/) and (assignment.drop? or assignment.excused))
      drops = {}
      drops[student.row] = {}
      for a in droppedAssignments
        drops[student.row][a] = 'dropped'

      styleKey = "dropsForRow#{student.row}"
      @grid.removeCellCssStyles(styleKey)
      @grid.addCellCssStyles(styleKey, drops)

    highlightColumn: (event) =>
      $headers = @$grid.find('.slick-header-column')
      return if $headers.filter('.slick-sortable-placeholder').length
      cell = @grid.getCellFromEvent(event)
      col = @grid.getColumns()[cell.cell]
      $headers.filter("##{@uid}#{col.id}").addClass('hovered-column')

    unhighlightColumns: () =>
      @$grid.find('.hovered-column').removeClass('hovered-column')

    # this is a workaroud to make it so only assignments are sortable but at the same time
    # so that the total and final grade columns don't dissapear after reordering columns
    fixColumnReordering: =>
      @renderTotalHeader()
      $headers = $('#gradebook_grid .container_1').find('.slick-header-columns')
      originalItemsSelector = $headers.sortable 'option', 'items'
      onlyAssignmentColsSelector = '> *:not([id*="assignment_group"]):not([id*="total_grade"])'
      (makeOnlyAssignmentsSortable = ->
        $headers.sortable 'option', 'items', onlyAssignmentColsSelector
        $notAssignments = $(originalItemsSelector, $headers).not($(onlyAssignmentColsSelector, $headers))
        $notAssignments.data('sortable-item', null)
      )()
      @initHeaderDropMenus()
      originalStopFn = $headers.sortable 'option', 'stop'
      (fixupStopCallback = ->
        $headers.sortable 'option', 'stop', (event, ui) ->
          # we need to set the items selector back to the default because slickgrid's 'stop'
          # function relies on it to re-render correctly.  if not it will render without the
          # assignment group and final grade columns
          $headers.sortable 'option', 'items', originalItemsSelector
          returnVal = originalStopFn.apply(this, arguments)
          makeOnlyAssignmentsSortable() # set it back
          @initHeaderDropMenus()
          fixupStopCallback() # originalStopFn re-creates sortable widget so we need to re-fix
          returnVal
      )()

    initHeaderDropMenus: =>
      $headers = $('#gradebook_grid .container_1').find('.slick-header-columns')
      $headers.find('.assignment_header_drop').click (event) =>
        $link = $(event.target)
        unless $link.data('gradebookHeaderMenu')
          $link.data('gradebookHeaderMenu', new GradebookHeaderMenu(@assignments[$link.data('assignmentId')], $link, this))
        return false

    minimizeColumn: ($columnHeader) =>
      columnDef = $columnHeader.data('column')
      colIndex = @grid.getColumnIndex(columnDef.id)
      columnDef.cssClass = (columnDef.cssClass || '').replace(' minimized', '') + ' minimized'
      columnDef.unselectable = true
      columnDef.unminimizedName = columnDef.name
      columnDef.name = ''
      columnDef.minimized = true
      @$grid.find(".l#{colIndex}").add($columnHeader).addClass('minimized')
      @assignmentsToHide.push(columnDef.id)
      userSettings.contextSet('hidden_columns', _.uniq(@assignmentsToHide))

    unminimizeColumn: ($columnHeader) =>
      columnDef = $columnHeader.data('column')
      colIndex = @grid.getColumnIndex(columnDef.id)
      columnDef.cssClass = (columnDef.cssClass || '').replace(' minimized', '')
      columnDef.unselectable = false
      columnDef.name = columnDef.unminimizedName
      columnDef.minimized = false
      @$grid.find(".l#{colIndex}").add($columnHeader).removeClass('minimized')
      $columnHeader.find('.slick-column-name').html($.raw(columnDef.name))
      @assignmentsToHide = $.grep @assignmentsToHide, (el) -> el != columnDef.id
      userSettings.contextSet('hidden_columns', _.uniq(@assignmentsToHide))

    hoverMinimizedCell: (event) =>
      $hoveredCell = $(event.currentTarget)
                     # get rid of hover class so that no other tooltips show up
                     .removeClass('hover')
      cell = @grid.getCellFromEvent(event)
      # cell will be null when hovering a header cell
      return unless cell
      columnDef = @grid.getColumns()[cell.cell]
      assignment = columnDef.object
      offset = $hoveredCell.offset()
      htmlLines = [assignment.name]
      if $hoveredCell.hasClass('slick-cell')
        submission = @rows[cell.row][columnDef.id]
        if assignment.points_possible?
          htmlLines.push "#{submission.score ? '--'} / #{assignment.points_possible}"
        else if submission.score?
          htmlLines.push submission.score
        # add lines for dropped, late, resubmitted
        Array::push.apply htmlLines, $.map(SubmissionCell.classesBasedOnSubmission(submission, assignment), (c)-> GRADEBOOK_TRANSLATIONS["#submission_tooltip_#{c}"])
      else if assignment.points_possible?
        htmlLines.push htmlEscape(I18n.t('points_out_of', "out of %{points_possible}", points_possible: assignment.points_possible))

      $hoveredCell.data('tooltip', $("<span />",
        class: 'gradebook-tooltip'
        css:
          left: offset.left - 15
          top: offset.top
          zIndex: 10000
          display: 'block'
        html: $.raw(htmlLines.join('<br />'))
      ).appendTo('body')
      .css('top', (i, top) -> parseInt(top) - $(this).outerHeight()))

    unhoverMinimizedCell: (event) ->
      if $tooltip = $(this).data('tooltip')
        if event.toElement == $tooltip[0]
          $tooltip.mouseleave -> $tooltip.remove()
        else
          $tooltip.remove()

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
      if e.target.className.match(/cell|slick/) or !@grid.getActiveCell
        return

      if e.target.className is 'grade' and @grid.getCellEditor() instanceof SubmissionCell.out_of
        # We can assume that a user clicked the up or down arrows on the
        # number input, we want to allow them to keep doing that.
        return

      if $(e.target).is(".dontblur,.dontblur *")
        return

      @grid.getEditorLock().commitCurrentEdit()

    onGridInit: () ->
      tooltipTexts = {}
      # TODO: this "if @spinner" crap is necessary because the outcome
      # gradebook kicks off the gradebook (unnecessarily).  back when the
      # gradebook was slow, this code worked, but now the spinner may never
      # initialize.  fix the way outcome gradebook loads
      $(@spinner.el).remove() if @spinner
      $('#gradebook-grid-wrapper').show()
      @uid = @grid.getUID()
      $('#content').focus ->
        $('#accessibility_warning').removeClass('screenreader-only')
      $('#accessibility_warning').focus ->
        $('#accessibility_warning').blur ->
          $('#accessibility_warning').remove()
      @$grid = grid = $('#gradebook_grid')
        .fillWindowWithMe({
          onResize: => @grid.resizeCanvas()
        })
        .delegate '.slick-cell',
          'mouseenter.gradebook focusin.gradebook' : @highlightColumn
          'mouseleave.gradebook focusout.gradebook' : @unhighlightColumns
          'mouseenter focusin' : (event) ->
            grid.find('.hover, .focus').removeClass('hover focus')
            if $(this).parent().css('top') == '0px'
              $(this).find('div.gradebook-tooltip').addClass('first-row')
            $(this).addClass (if event.type == 'mouseenter' then 'hover' else 'focus')
          'mouseleave focusout' : (event) ->
            $(this).removeClass('hover focus')
            $(this).find('div.gradebook-tooltip').removeClass('first-row')
        .delegate '.gradebook-cell-comment', 'click.gradebook', (event) =>
          event.preventDefault()
          return false if $(@grid.getActiveCellNode()).hasClass("cannot_edit")
          data = $(event.currentTarget).data()
          $(@grid.getActiveCellNode()).removeClass('editable')
          SubmissionDetailsDialog.open @assignments[data.assignmentId], @student(data.userId.toString()), @options
        .delegate '.minimized',
          'mouseenter' : @hoverMinimizedCell,
          'mouseleave' : @unhoverMinimizedCell

      @$grid.addClass('editable') if @options.gradebook_is_editable

      @fixMaxHeaderWidth()
      @grid.onColumnsResized.subscribe (e, data) =>
        @$grid.find('.slick-header-column').each (i, elem) =>
          $columnHeader = $(elem)
          columnDef = $columnHeader.data('column')
          return unless columnDef.type is "assignment"
          if $columnHeader.outerWidth() <= columnWidths.assignment.min
            @minimizeColumn($columnHeader) unless columnDef.minimized
          else if columnDef.minimized
            @unminimizeColumn($columnHeader)

      @keyboardNav = new GradebookKeyboardNav(@grid, @$grid)
      @keyboardNav.init()
      keyBindings = @keyboardNav.keyBindings
      @kbDialog = new KeyboardNavDialog().render(keyboardNavTemplate({keyBindings}))
      # when we close a dialog we want to return focus to the grid
      $(document).on('dialogclose', (e) =>
        setTimeout(( =>
          @grid.editActiveCell()
        ), 0)
      )
      $(document).trigger('gridready')

    sectionList: ->
      _.map @sections, (section, id) =>
        { name: section.name, id: id, checked: @sectionToShow == id }

    drawSectionSelectButton: () ->
      @sectionMenu = new SectionMenuView(
        el: $('.section-button-placeholder'),
        sections: @sectionList(),
        showSections: @showSections(),
        currentSection: @sectionToShow,
        disabled: true)
      @sectionMenu.render()

      @studentsLoaded.then =>
        @sectionMenu.disabled = false
        @sectionMenu.render()

    updateCurrentSection: (section, author) =>
      @sectionToShow = section
      @postGradesStore.setSelectedSection @sectionToShow
      userSettings[if @sectionToShow then 'contextSet' else 'contextRemove']('grading_show_only_section', @sectionToShow)
      @buildRows() if @grid

    showSections: ->
      @sections_enabled

    gradingPeriodList: ->
      _.map @gradingPeriods, (period) =>
        { title: period.title, id: period.id, checked: @gradingPeriodToShow == period.id }

    drawGradingPeriodSelectButton: () ->
      @gradingPeriodMenu = new GradingPeriodMenuView(
        el: $('.multiple-grading-periods-selector-placeholder'),
        periods: @gradingPeriodList(),
        currentGradingPeriod: @gradingPeriodToShow)
      @gradingPeriodMenu.render()

    updateCurrentGradingPeriod: (period) ->
      userSettings.contextSet 'gradebook_current_grading_period', period
      window.location.reload()

    initPostGradesStore: ->
      @postGradesStore = PostGradesStore
        course:
          id:     @options.context_id
          sis_id: @options.context_sis_id
      @postGradesStore.addChangeListener(@updatePowerschoolPostGradesButton)

      @postGradesStore.setSelectedSection @sectionToShow

    showPostGradesButton: ->
      $placeholder = $('.post-grades-placeholder')
      if $placeholder.length > 0
        app = React.createElement(PostGradesApp, {
          store: @postGradesStore
          renderAsButton: !$placeholder.hasClass('in-menu')
          labelText: if $placeholder.hasClass('in-menu') then I18n.t 'PowerSchool' else I18n.t 'Post Grades',
          returnFocusTo: $('#post_grades')
        })
        React.render(app, $placeholder[0])

    updatePowerschoolPostGradesButton: =>
      showButton = @postGradesStore.hasAssignments() && !!@postGradesStore.getState().selected.sis_id
      $('.post-grades-placeholder').toggle(showButton)

    initHeader: =>
      @drawSectionSelectButton() if @sections_enabled
      @drawGradingPeriodSelectButton() if @mgpEnabled

      $settingsMenu = $('.gradebook_dropdown')
      showConcludedEnrollmentsEl = $settingsMenu.find("#show_concluded_enrollments")
      showConcludedEnrollmentsEl.prop('checked', @showConcludedEnrollments).change (event) =>
        if @options.course_is_concluded and @showConcludedEnrollments
          showConcludedEnrollmentsEl.prop('checked', true)
          $settingsMenu.menu("refresh")
          return alert(I18n.t 'concluded_course_error_message', 'This is a concluded course, so only concluded enrollments are available.')
        @showConcludedEnrollments  = showConcludedEnrollmentsEl.is(':checked')
        @saveSettings(@showInactiveEnrollments, @showConcludedEnrollments, -> window.location.reload())

      showInactiveEnrollmentsEl = $settingsMenu.find("#show_inactive_enrollments")
      showInactiveEnrollmentsEl.prop('checked', @showInactiveEnrollments).change (event) =>
        @showInactiveEnrollments = showInactiveEnrollmentsEl.is(':checked')
        @saveSettings(@showInactiveEnrollments, @showConcludedEnrollments, -> window.location.reload())

      includeUngradedAssignmentsEl = $settingsMenu.find("#include_ungraded_assignments")
      includeUngradedAssignmentsEl.prop('checked', @include_ungraded_assignments).change (event) =>
        @include_ungraded_assignments = includeUngradedAssignmentsEl.is(':checked')
        userSettings.contextSet 'include_ungraded_assignments', @include_ungraded_assignments
        @buildRows()

      showAttendanceEl = $settingsMenu.find("#show_attendance")
      showAttendanceEl.prop('checked', @show_attendance).change (event) =>
        @show_attendance = showAttendanceEl.is(':checked')
        userSettings.contextSet 'show_attendance', @show_attendance
        @grid.setColumns @getVisibleGradeGridColumns()
        @buildRows()

      # don't show the "show attendance" link in the dropdown if there's no attendance assignments
      unless (_.detect @assignments, (a) -> (''+a.submission_types) == "attendance")
        $settingsMenu.find('#show_attendance').closest('li').hide()

      if @hideAggregateColumns()
        $settingsMenu.find('#include-ungraded-list-item').hide()

      @$columnArrangementTogglers = $('#gradebook-toolbar [data-arrange-columns-by]').bind 'click', (event) =>
        event.preventDefault()
        newSortOrder = { sortType: $(event.currentTarget).data('arrangeColumnsBy') }
        @arrangeColumnsBy(newSortOrder, false)
      @arrangeColumnsBy(@getStoredSortOrder(), true)

      $('#gradebook_settings').kyleMenu(returnFocusTo: $('#gradebook_settings'))
      $('#download_csv').kyleMenu(returnFocusTo: $('#download_csv'))
      $('#post_grades').kyleMenu()

      $settingsMenu.find('.student_names_toggle').click(@studentNamesToggle)
      $('#keyboard-shortcuts').click ->
        questionMarkKeyDown = $.Event('keydown', keyCode: 191)
        $(document).trigger(questionMarkKeyDown)

      # turn on stuff that starts out hidden/disabled
      @studentsLoaded.then =>
        $(".gradebook_filter").show()

        cols = @grid.getColumns()
        col.sortable = true for col in cols
        @grid.setColumns(cols)
        @renderTotalHeader()
        @initHeaderDropMenus()

      @userFilter = new InputFilterView el: '.gradebook_filter input'
      @userFilter.on 'input', @onUserFilterInput

      @initGradebookExporter()

    initGradebookExporter: () =>
      self = this

      @initPreviousGradebookExportLink()

      current_progress = @options.gradebook_csv_progress
      attachment = @options.attachment

      if current_progress && current_progress.progress.workflow_state != 'completed'
        $('#download_csv').prop('disabled', true)
        loading_interval = self.exportingGradebookStatus()

        attachment_progress =
          progress_id: current_progress.progress.id
          attachment_id: attachment.attachment.id

        @pollProgressForCSVExport(loading_interval, attachment_progress)

      $('.generate_new_csv').click =>
        $('#download_csv').prop('disabled', true)
        $('.icon-import').parent().focus()
        loading_interval = self.exportingGradebookStatus()
        include_priors = $('#show_concluded_enrollments').prop('checked')

        params =
          include_priors: include_priors
          grading_period_id: @getGradingPeriodToShow()

        $.ajaxJSON(
            @options.export_gradebook_csv_url,
            'GET',
            params
        ).then((attachment_progress) ->
          self.pollProgressForCSVExport(loading_interval, attachment_progress)
        )

    pollProgressForCSVExport: (loading_interval, attachment_progress) =>
      self = this
      polling = setInterval(() ->
        $.ajaxJSON("/api/v1/progress/#{attachment_progress.progress_id}", 'GET').promise()
          .then((response) ->
            if response.workflow_state == 'failed'
              clearInterval polling
              clearInterval loading_interval
              $.flashError(I18n.t('There was a problem exporting.'))

            if response.workflow_state == 'completed'
              $.ajaxJSON("/api/v1/users/#{ENV.current_user_id}/files/#{attachment_progress.attachment_id}", 'get')
                .then((response) ->
                  document.getElementById('csv_download').src = response.url

                  updated_date = $.datetimeString(response.created_at)
                  updated_previous_report = "#{I18n.t('Previous (%{timestamp})', timestamp: updated_date)}"
                  $previous_link = $('#csv_export_options .open_in_a_new_tab')
                  $previous_link.text(updated_previous_report)
                  $previous_link.attr('href', response.url)
                  $('#csv_export_options').children('li').last().css('display', 'block')
                  self.initPreviousGradebookExportLink()

                  $('#download_csv').prop('disabled', false)
                  self.setExportButtonTitle(I18n.t('Export'))

                  clearInterval polling
                  clearInterval loading_interval
               )
          )
      , 2000)

    initPreviousGradebookExportLink: () ->
      link = $('#csv_export_options').children('li').last().children()
      link.on 'click', (event) ->
        event.preventDefault()
        document.getElementById('csv_download').src = link[0].href

    exportingGradebookStatus: () =>
      self = this
      loading_indicator = ''
      count = 0
      loading = setInterval(() ->
        count++

        loading_indicator = new Array(count % 5).join('.')
        nonBreakingSpacesCount = 3 - loading_indicator.length
        nonBreakingSpaces = ""
        for scale in [0..nonBreakingSpacesCount]
          nonBreakingSpaces += "&nbsp;"

        self.setExportButtonTitle("#{I18n.t("Exporting")}#{loading_indicator}#{nonBreakingSpaces}")
      , 200)
      loading

    setExportButtonTitle: (updated_title) ->
      $($('#download_csv').children('span').contents()[2]).replaceWith(updated_title)

    checkForUploadComplete: () ->
      if userSettings.contextGet('gradebookUploadComplete')
        $.flashMessage I18n.t('Upload successful')
        userSettings.contextRemove('gradebookUploadComplete')

    studentNamesToggle: (e) =>
      e.preventDefault()
      $wrapper = @$grid.find('.grid-canvas')
      $wrapper.toggleClass('hide-students')

      if $wrapper.hasClass('hide-students')
        $(e.currentTarget).text I18n.t('show_student_names', 'Show Student Names')
      else
        $(e.currentTarget).text I18n.t('hide_student_names', 'Hide Student Names')

    weightedGroups: =>
      @options.group_weighting_scheme == "percent"

    displayPointTotals: =>
      if @weightedGroups()
        false
      else
        @options.show_total_grade_as_points

    switchTotalDisplay: =>
      @options.show_total_grade_as_points = not @options.show_total_grade_as_points
      $.ajaxJSON @options.setting_update_url, "PUT", show_total_grade_as_points: @displayPointTotals()
      @grid.invalidate()
      @totalHeader.switchTotalDisplay(@options.show_total_grade_as_points)

    switchTotalDisplayAndMarkUserAsWarned: =>
      userSettings.contextSet('warned_about_totals_display', true)
      @switchTotalDisplay()

    togglePointsOrPercentTotals: =>
      if userSettings.contextGet('warned_about_totals_display')
        @switchTotalDisplay()
      else
        dialog_options =
          showing_points: @options.show_total_grade_as_points
          unchecked_save: @switchTotalDisplay
          checked_save: @switchTotalDisplayAndMarkUserAsWarned
        new GradeDisplayWarningDialog(dialog_options)

    onUserFilterInput: (term) =>
      @userFilterTerm = term
      @buildRows()

    getVisibleGradeGridColumns: ->
      columns = []

      for column in @allAssignmentColumns
        if @disabledAssignments && @disabledAssignments.indexOf(column.object.id) != -1
          column.cssClass = "cannot_edit"
        submissionType = ''+ column.object.submission_types
        columns.push(column) unless submissionType is "not_graded" or
                                submissionType is "attendance" and not @show_attendance

      if @gradebookColumnOrderSettings?.sortType
        columns.sort @makeColumnSortFn(@getStoredSortOrder())

      columns = columns.concat(@aggregateColumns)
      headers = @parentColumns.concat(@customColumnDefinitions())
      headers.concat(columns)

    assignmentHeaderHtml: (assignment) ->
      columnHeaderTemplate
        assignment: assignment
        href: assignment.html_url
        showPointsPossible: assignment.points_possible?

    customColumnDefinitions: ->
      @customColumns.map (c) ->
        id: "custom_col_#{c.id}"
        name: htmlEscape c.title
        field: "custom_col_#{c.id}"
        width: 100
        cssClass: "meta-cell custom_column"
        resizable: true
        editor: LongTextEditor
        autoEdit: false
        maxLength: 255

    initGrid: =>
      #this is used to figure out how wide to make each column
      $widthTester = $('<span style="padding:10px" />').appendTo('#content')
      testWidth = (text, minWidth, maxWidth) ->
        width = Math.max($widthTester.text(text).outerWidth(), minWidth)
        Math.min width, maxWidth

      @setAssignmentWarnings()

      studentColumnWidth = 150
      identifierColumnWidth = 100
      if @gradebookColumnSizeSettings
        if @gradebookColumnSizeSettings['student']
          studentColumnWidth = parseInt(@gradebookColumnSizeSettings['student'])

        if @gradebookColumnSizeSettings['secondary_identifier']
          identifierColumnWidth = parseInt(@gradebookColumnSizeSettings['secondary_identifier'])

      @parentColumns = [
        id: 'student'
        name: htmlEscape I18n.t 'student_name', 'Student Name'
        field: 'display_name'
        width: studentColumnWidth
        cssClass: "meta-cell"
        resizable: true
        formatter: @htmlContentFormatter
      ,
        id: 'secondary_identifier'
        name: htmlEscape I18n.t 'secondary_id', 'Secondary ID'
        field: 'secondary_identifier'
        width: identifierColumnWidth
        cssClass: "meta-cell secondary_identifier_cell"
        resizable: true
        formatter: @htmlContentFormatter
      ]

      @allAssignmentColumns = for id, assignment of @assignments
        outOfFormatter = assignment &&
                         assignment.grading_type == 'points' &&
                         assignment.points_possible? &&
                         SubmissionCell.out_of
        minWidth = if outOfFormatter then 70 else 90
        fieldName = "assignment_#{id}"

        assignmentWidth = testWidth(assignment.name, minWidth, columnWidths.assignment.default_max)
        if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings[fieldName]
          assignmentWidth = parseInt(@gradebookColumnSizeSettings[fieldName])

        columnDef =
          id: fieldName
          field: fieldName
          name: @assignmentHeaderHtml(assignment)
          object: assignment
          formatter: this.cellFormatter
          editor: outOfFormatter ||
                  SubmissionCell[assignment.grading_type] ||
                  SubmissionCell
          minWidth: columnWidths.assignment.min,
          maxWidth: columnWidths.assignment.max,
          width: assignmentWidth
          toolTip: assignment.name
          type: 'assignment'

        if fieldName in @assignmentsToHide
          columnDef.width = 10
          do (fieldName) =>
            $(document)
              .bind('gridready', =>
                @minimizeColumn(@$grid.find("##{@uid}#{fieldName}"))
              )
              .unbind('gridready.render')
              .bind('gridready.render', => @grid.invalidate() )
        columnDef
      if @hideAggregateColumns()
        @aggregateColumns = []
      else
        @aggregateColumns = for id, group of @assignmentGroups
          fieldName = "assignment_group_#{id}"

          aggregateWidth = testWidth(group.name, columnWidths.assignmentGroup.min, columnWidths.assignmentGroup.default_max)
          if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings[fieldName]
            aggregateWidth = parseInt(@gradebookColumnSizeSettings[fieldName])

          {
            id: fieldName
            field: fieldName
            formatter: @groupTotalFormatter
            name: @assignmentGroupHtml(group.name, group.group_weight)
            toolTip: group.name
            object: group
            minWidth: columnWidths.assignmentGroup.min,
            maxWidth: columnWidths.assignmentGroup.max,
            width: aggregateWidth
            cssClass: "meta-cell assignment-group-cell",
            type: 'assignment_group'
          }

        total = I18n.t "total", "Total"

        totalWidth = testWidth("Total", columnWidths.total.min, columnWidths.total.max)
        if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings['total_grade']
          totalWidth = parseInt(@gradebookColumnSizeSettings['total_grade'])

        total_column =
          id: "total_grade"
          field: "total_grade"
          formatter: @groupTotalFormatter
          name: """
            #{htmlEscape total}
            <div id=total_column_header></div>
          """
          toolTip: total
          minWidth: columnWidths.total.min
          maxWidth: columnWidths.total.max
          width: totalWidth
          cssClass: if @totalColumnInFront then 'meta-cell' else 'total-cell'
          type: 'total_grade'

        (if @totalColumnInFront then @parentColumns else
          @aggregateColumns).push total_column

      $widthTester.remove()

      options = $.extend({
        enableCellNavigation: true
        enableColumnReorder: true
        enableAsyncPostRender: true
        asyncPostRenderDelay: 1
        autoEdit: true # whether to go into edit-mode as soon as you tab to a cell
        editable: @options.gradebook_is_editable
        syncColumnCellResize: true
        rowHeight: 35
        headerHeight: 38
        numberOfColumnsToFreeze: @numberOfFrozenCols
      }, @options)

      @grid = new Slick.Grid('#gradebook_grid', @rows, @getVisibleGradeGridColumns(), options)
      @grid.setSortColumn("student")
      # this is the magic that actually updates group and final grades when you edit a cell

      @grid.onCellChange.subscribe @onCellChange

      # this is a faux blur event for SlickGrid.
      $('body').on('click', @onGridBlur)

      @grid.onSort.subscribe (event, data) =>
        if data.sortCol.field == "display_name" ||
           data.sortCol.field == "secondary_identifier" ||
           data.sortCol.field.match /^custom_col/
          sortProp = if data.sortCol.field == "display_name"
            "sortable_name"
          else
            data.sortCol.field

          @sortRowsBy (a, b) =>
            [b, a] = [a, b] unless data.sortAsc
            @localeSort(a[sortProp], b[sortProp])
        else
          @sortRowsBy (a, b) =>
            @gradeSort(a, b, data.sortCol.field, data.sortAsc)

      @grid.onKeyDown.subscribe ->
        # TODO: start editing automatically when a number or letter is typed
        false

      @grid.onColumnsReordered.subscribe @onColumnsReordered
      @grid.onBeforeEditCell.subscribe @onBeforeEditCell
      @grid.onColumnsResized.subscribe @onColumnsResized

      @onGridInit()

    onColumnsResized: (event, obj) =>
      grid = obj.grid
      columns = grid.getColumns()

      _.each columns, (column) =>
        if column.previousWidth && column.width != column.previousWidth
          @saveColumnWidthPreference(column.id, column.width)

    saveColumnWidthPreference: (id, newWidth) ->
      url = @options.gradebook_column_size_settings_url
      $.ajaxJSON(url, 'POST', {column_id: id, column_size: newWidth})

    saveSettings: (showInactive, showConcluded, callback) =>
      url = @options.settings_update_url
      $.ajaxJSON(url, 'PUT', gradebook_settings: {
        show_inactive_enrollments: showInactive
        show_concluded_enrollments: showConcluded
      }).done =>
        callback()

    onBeforeEditCell: (event, {row, cell}) =>
      $cell = @grid.getCellNode(row, cell)
      return false if $($cell).hasClass("cannot_edit") || $($cell).find(".gradebook-cell").hasClass("cannot_edit")

    onCellChange: (event, {item, column}) =>
      if col_id = column.field.match /^custom_col_(\d+)/
        url = @options.custom_column_datum_url
          .replace(/:id/, col_id[1])
          .replace(/:user_id/, item.id)

        $.ajaxJSON url, "PUT", "column_data[content]": item[column.field]
      else
        @calculateStudentGrade(item)
        @grid.invalidate()

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

      @rows.sort respectorOfPersonsSort()
      for student, i in @rows
        student.row = i
        @addDroppedClass(student)
      @grid.invalidate()

    localeSort: (a, b) ->
      (a || "").localeCompare b || "",
        window.I18n.locale,
        sensitivity: 'accent', numeric: true

    gradeSort: (a, b, field, asc) =>
      scoreForSorting = (obj) =>
        percent = (obj) ->
          if obj[field].possible > 0
            obj[field].score / obj[field].possible
          else
            null

        switch
          when field == "total_grade"
            if @options.show_total_grade_as_points
              obj[field].score
            else
              percent(obj)
          when field.match /^assignment_group/
            percent(obj)
          else
            # TODO: support assignment grading types
            obj[field].score

      numberCompare(scoreForSorting(a), scoreForSorting(b), descending: !asc)

    # show warnings for bad grading setups
    setAssignmentWarnings: =>
      @totalGradeWarning = null

      gradebookVisibleAssignments = _.reject @assignments, (assignment) ->
        _.contains(assignment.submission_types, 'not_graded')

      if _.any(gradebookVisibleAssignments, (a) -> a.muted)
        @totalGradeWarning =
          warningText: I18n.t "This grade differs from the student's view of the grade because some assignments are muted"
          icon: "icon-muted"
      else
        if @weightedGroups()
          # assignment group has 0 points possible
          invalidAssignmentGroups = _.filter @assignmentGroups, (ag) ->
            pointsPossible = _.inject ag.assignments
            , ((sum, a) -> sum + (a.points_possible || 0))
            , 0
            pointsPossible == 0

          for ag in invalidAssignmentGroups
            for a in ag.assignments
              a.invalid = true

          if invalidAssignmentGroups.length > 0
            groupNames = (ag.name for ag in invalidAssignmentGroups)
            text = I18n.t 'invalid_assignment_groups_warning',
              one: "Score does not include %{groups} because it has
                    no points possible"
              other: "Score does not include %{groups} because they have
                      no points possible"
            ,
              groups: $.toSentence(groupNames)
              count: groupNames.length
            @totalGradeWarning =
              warningText: text
              icon: "icon-warning final-warning"

        else
          # no assignments have points possible
          pointsPossible = _.inject @assignments
          , ((sum, a) -> sum + (a.points_possible || 0))
          , 0

          if pointsPossible == 0
            text = I18n.t 'no_assignments_have_points_warning'
            , "Can't compute score until an assignment has points possible"
            @totalGradeWarning =
              warningText: text
              icon: "icon-warning final-warning"
    ###
    xsslint jqueryObject.identifier createLink
    xsslint jqueryObject.function showLink hideLink
    ###
    showCustomColumnDropdownOption: ->
      linkContainer = $("<li>").appendTo(".gradebook_dropdown")

      showLabel = I18n.t("show_notes", "Show Notes Column")
      hideLabel = I18n.t("hide_notes", "Hide Notes Column")
      teacherNotesUrl = =>
        @options.custom_column_url.replace(/:id/, @options.teacher_notes.id)
      createLink = $ "<a>",
        href: @options.custom_columns_url, "class": "create", text: showLabel
      showLink = -> $ "<a>",
        href: teacherNotesUrl(), "class": "show", text: showLabel
      hideLink = -> $ "<a>",
        href: teacherNotesUrl(), "class": "hide", text: hideLabel

      handleClick = (e, method, params) ->
        $.ajaxJSON(e.target.href, method, params)

      toggleNotesColumn = (f) =>
        columnsToReplace = @numberOfFrozenCols
        f()
        cols = @grid.getColumns()
        cols.splice 0, columnsToReplace,
          @parentColumns..., @customColumnDefinitions()...
        @grid.setColumns(cols)
        @grid.invalidate()

      teacherNotesDataLoaded = false
      showNotesColumn = =>
        toggleNotesColumn =>
          @customColumns.splice 0, 0, @options.teacher_notes
          @grid.setNumberOfColumnsToFreeze ++@numberOfFrozenCols
        linkContainer.html(hideLink())

      hideNotesColumn = =>
        toggleNotesColumn =>
          for c, i in @customColumns
            if c.teacher_notes
              @customColumns.splice i, 1
              @numberOfFrozenCols -= 1
              break
          @grid.setNumberOfColumnsToFreeze @numberOfFrozenCols
        linkContainer.html(showLink())

      linkContainer.click (e) =>
        e.preventDefault()
        $target = $(e.target)
        if $target.hasClass("show")
          handleClick(e, "PUT", "column[hidden]": false)
          .then =>
            showNotesColumn()
            @reorderCustomColumns(@customColumns.map (c) -> c.id)
        if $target.hasClass("hide")
          handleClick(e, "PUT", "column[hidden]": true)
          .then hideNotesColumn()
        if $target.hasClass("create")
          handleClick(e, "POST",
            "column[title]": I18n.t("notes", "Notes")
            "column[position]": 1
            "column[teacher_notes]": true)
          .then (data) =>
            @options.teacher_notes = data
            showNotesColumn()

      notes = @options.teacher_notes
      if !notes
        linkContainer.html(createLink)
      else if notes.hidden
        linkContainer.html(showLink())
      else
        linkContainer.html(hideLink())

    isAllGradingPeriods: (currentPeriodId) ->
      currentPeriodId == "0"

    hideAggregateColumns: ->
      return false unless @mgpEnabled
      return false if @options.all_grading_periods_totals
      selectedPeriodId = @getGradingPeriodToShow()
      @isAllGradingPeriods(selectedPeriodId)

    fieldsToExcludeFromAssignments: ['description', 'needs_grading_count']

    studentsUrl: ->
      switch
        when @showConcludedEnrollments && @showInactiveEnrollments
          'students_with_concluded_and_inactive_enrollments_url'
        when @showConcludedEnrollments
          'students_with_concluded_enrollments_url'
        when @showInactiveEnrollments
          'students_with_inactive_enrollments_url'
        else 'students_url'

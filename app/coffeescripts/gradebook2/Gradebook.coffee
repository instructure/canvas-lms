# This class both creates the slickgrid instance, and acts as the data source for that instance.
define [
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
  'compiled/grade_calculator'
  'compiled/userSettings'
  'vendor/spin'
  'compiled/SubmissionDetailsDialog'
  'compiled/gradebook2/AssignmentGroupWeightsDialog'
  'compiled/gradebook2/SubmissionCell'
  'compiled/gradebook2/GradebookHeaderMenu'
  'str/htmlEscape'
  'jst/gradebook_uploads_form'
  'jst/gradebook2/section_to_show_menu'
  'jst/gradebook2/column_header'
  'jst/gradebook2/group_total_cell'
  'jst/gradebook2/row_student_name'
  'jst/_avatar' #needed by row_student_name
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jqueryui/dialog'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'jqueryui/mouse'
  'jqueryui/position'
  'jqueryui/sortable'
  'compiled/jquery.kylemenu'
  'compiled/jquery/fixDialogButtons'
], (KeyboardNavDialog, keyboardNavTemplate, Slick, TotalColumnHeaderView, round, InputFilterView, I18n, GRADEBOOK_TRANSLATIONS, $, _, GradeCalculator, userSettings, Spinner, SubmissionDetailsDialog, AssignmentGroupWeightsDialog, SubmissionCell, GradebookHeaderMenu, htmlEscape, gradebook_uploads_form, sectionToShowMenuTemplate, columnHeaderTemplate, groupTotalCellTemplate, rowStudentNameTemplate) ->

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
        min: 85
        max: 100

    DISPLAY_PRECISION = 2

    numberOfFrozenCols: 2

    constructor: (@options) ->
      @chunk_start = 0
      @students = {}
      @studentViewStudents = {}
      @rows = []
      @assignmentsToHide = userSettings.contextGet('hidden_columns') || []
      @sectionToShow = userSettings.contextGet 'grading_show_only_section'
      @sectionToShow = @sectionToShow && String(@sectionToShow)
      @show_attendance = userSettings.contextGet 'show_attendance'
      @include_ungraded_assignments = userSettings.contextGet 'include_ungraded_assignments'
      @userFilterRemovedRows = []
      @show_concluded_enrollments = userSettings.contextGet 'show_concluded_enrollments'
      @show_concluded_enrollments = true if @options.course_is_concluded

      $.subscribe 'assignment_group_weights_changed', @buildRows
      $.subscribe 'assignment_muting_toggled', @handleAssignmentMutingChange
      $.subscribe 'submissions_updated', @updateSubmissionsFromExternal

      enrollmentsUrl = if @show_concluded_enrollments
        'students_url_with_concluded_enrollments'
      else
        'students_url'

      # getting all the enrollments for a course via the api in the polite way
      # is too slow, so we're going to cheat.
      $.when($.ajaxJSON(@options[enrollmentsUrl], "GET")
      , $.ajaxJSON(@options.assignment_groups_url, "GET", {}, @gotAssignmentGroups)
      , $.ajaxJSON( @options.sections_url, "GET", {}, @gotSections))
      .then ([students, status, xhr]) =>
        @gotChunkOfStudents students

        paginationLinks = xhr.getResponseHeader('Link')
        lastLink = paginationLinks.match(/<[^>]+>; *rel="last"/)
        unless lastLink?
          @gotAllStudents()
          return
        lastPage = lastLink[0].match(/page=(\d+)/)[1]
        lastPage = parseInt lastPage, 10
        if lastPage == 1
          @gotAllStudents()
          return

        fetchEnrollments = (page) =>
          $.ajaxJSON @options[enrollmentsUrl], "GET", {page}
        dfds = (fetchEnrollments(page) for page in [2..lastPage])
        $.when(dfds...).then (responses...) =>
          if dfds.length == 1
            @gotChunkOfStudents responses[0]
          else
            @gotChunkOfStudents(students) for [students, x, y] in responses
          @gotAllStudents()

      @spinner = new Spinner()
      $(@spinner.spin().el).css(
        opacity: 0.5
        top: '55px'
        left: '50%'
      ).addClass('use-css-transitions-for-show-hide').appendTo('#main')

    gotAssignmentGroups: (assignmentGroups) =>
      @assignmentGroups = {}
      @assignments      = {}

      # purposely passing the @options and assignmentGroups by reference so it can update
      # an assigmentGroup's .group_weight and @options.group_weighting_scheme
      new AssignmentGroupWeightsDialog context: @options, assignmentGroups: assignmentGroups
      for group in assignmentGroups
        htmlEscape(group)
        @assignmentGroups[group.id] = group
        if ENV.GRADEBOOK_OPTIONS.draft_state_enabled
          group.assignments = _.select group.assignments, (a) -> a.published
        for assignment in group.assignments
          htmlEscape(assignment)
          assignment.assignment_group = group
          assignment.due_at = $.parseFromISO(assignment.due_at) if assignment.due_at
          @assignments[assignment.id] = assignment

    gotSections: (sections) =>
      @sections = {}
      for section in sections
        htmlEscape(section)
        @sections[section.id] = section
      @sections_enabled = sections.length > 1

    gotChunkOfStudents: (studentEnrollments) =>
      for studentEnrollment in studentEnrollments
        student = studentEnrollment.user
        student.enrollment = studentEnrollment

        if student.enrollment.role == "StudentViewEnrollment"
          @studentViewStudents[student.id] ||= htmlEscape(student)
        else
          @students[student.id] ||= htmlEscape(student)
        @student(student.id).sections ||= []
        @student(student.id).sections.push(studentEnrollment.course_section_id)

    gotAllStudents: ->
      @withAllStudents (students) =>
        for id, student of students
          student.computed_current_score ||= 0
          student.computed_final_score ||= 0
          student.secondary_identifier = student.sis_login_id || student.login_id

          if @sections_enabled
            mySections = (@sections[sectionId].name for sectionId in student.sections when @sections[sectionId])
            sectionNames = $.toSentence(mySections.sort())
          student.display_name = rowStudentNameTemplate
            avatar_image_url: student.avatar_url
            display_name: student.name
            url: student.enrollment.grades.html_url
            sectionNames: sectionNames

          # fill in dummy submissions, so there's something there even if the
          # student didn't submit anything for that assignment
          for id, assignment of @assignments
            student["assignment_#{id}"] ||= { assignment_id: id, user_id: student.id }

          @rows.push(student)
        @initGrid()
        @buildRows()
        @getSubmissionsChunks()
        @initHeader()

    defaultSortType: 'assignment_group'

    getStoredSortOrder: =>
      userSettings.contextGet('sort_grade_columns_by') || { sortType: @defaultSortType }

    setStoredSortOrder: (newSortOrder) =>
      if newSortOrder.sortType == @defaultSortType
        userSettings.contextRemove('sort_grade_columns_by')
      else
        userSettings.contextSet('sort_grade_columns_by', newSortOrder)

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

    arrangeColumnsBy: (newSortOrder) =>
      @setArrangementTogglersVisibility(newSortOrder)
      @setStoredSortOrder(newSortOrder)

      columns = @grid.getColumns()
      frozen = columns.splice(0, @numberOfFrozenCols)
      columns.sort @makeColumnSortFn(newSortOrder)
      columns.splice(0, 0, frozen...)
      @grid.setColumns(columns)

      @fixColumnReordering()
      @buildRows()

    makeColumnSortFn: (sortOrder) =>
      fn = switch sortOrder.sortType
        when 'assignment_group' then @compareAssignmentPositions
        when 'due_date' then @compareAssignmentDueDates
        when 'custom' then @makeCompareAssignmentCustomOrderFn(sortOrder)
        else throw "unhandled column sort condition"
      @wrapColumnSortFn(fn)

    compareAssignmentPositions: (a, b) =>
      diffOfAssignmentGroupPosition = a.object.assignment_group.position - b.object.assignment_group.position
      diffOfAssignmentPosition = a.object.position - b.object.position

      # order first by assignment_group position and then by assignment position
      # will work when there are less than 1000000 assignments in an assignment_group
      return (diffOfAssignmentGroupPosition * 1000000) + diffOfAssignmentPosition

    compareAssignmentDueDates: (a, b) =>
      aDate = a.object.due_at?.timestamp or Number.MAX_VALUE
      bDate = b.object.due_at?.timestamp or Number.MAX_VALUE
      if aDate is bDate
        return 0 if a.object.name is b.object.name
        return (if a.object.name > b.object.name then 1 else -1)
      return aDate - bDate

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

    wrapColumnSortFn: (wrappedFn) =>
      (a, b) =>
        return -1 if b.type is 'total_grade'
        return  1 if a.type is 'total_grade'
        return -1 if b.type is 'assignment_group' and a.type isnt 'assignment_group'
        return  1 if a.type is 'assignment_group' and b.type isnt 'assignment_group'
        if a.type is 'assignment_group' and b.type is 'assignment_group'
          return a.object.position - b.object.position
        return wrappedFn(a, b)

    rowFilter: (student) =>
      !@sectionToShow || (@sectionToShow in student.sections)

    handleAssignmentMutingChange: (assignment) =>
      idx = @grid.getColumnIndex("assignment_#{assignment.id}")
      colDef = @grid.getColumns()[idx]
      colDef.name = @assignmentHeaderHtml(assignment)
      @grid.setColumns(@grid.getColumns())
      @fixColumnReordering()
      @buildRows()

    # filter, sort, and build the dataset for slickgrid to read from, then force
    # a full redraw
    buildRows: =>
      @rows.length = 0

      for id, column of @grid.getColumns() when ''+column.object?.submission_types is "attendance"
        column.unselectable = !@show_attendance
        column.cssClass = if @show_attendance then '' else 'completely-hidden'
        @$grid.find("##{@uid}#{column.id}").showIf(@show_attendance)

      @withAllStudents (students) =>
        for id, student of @students
          student.row = -1
          if @rowFilter(student)
            @rows.push(student)
            @calculateStudentGrade(student)

      @sortRowsBy (a, b) => @localeSort(a.sortable_name, b.sortable_name)

    getSubmissionsChunks: =>
      @withAllStudents (allStudentsObj) =>
        allStudents = (s for k, s of allStudentsObj)
        loop
          students = allStudents[@chunk_start...(@chunk_start+@options.chunk_size)]
          unless students.length
            @allSubmissionsLoaded = true
            break
          params =
            student_ids: (student.id for student in students)
            response_fields: ['id', 'user_id', 'url', 'score', 'grade', 'submission_type', 'submitted_at', 'assignment_id', 'grade_matches_current_submission', 'attachments', 'late']
          $.ajaxJSON(@options.submissions_url, "GET", params, @gotSubmissionsChunk)
          @chunk_start += @options.chunk_size

    gotSubmissionsChunk: (student_submissions) =>
      for data in student_submissions
        student = @student(data.user_id)
        @updateSubmission(submission) for submission in data.submissions
        student.loaded = true
        @grid.invalidateRow(student.row)
        @calculateStudentGrade(student)
      @grid.render()

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
      submission.submitted_at = $.parseFromISO(submission.submitted_at) if submission.submitted_at
      student["assignment_#{submission.assignment_id}"] = submission

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
        @updateSubmission(submission)
        @calculateStudentGrade(student)
        @grid.updateCell student.row, cell unless thisCellIsActive
        @updateRowTotals student.row

    updateRowTotals: (rowIndex) ->
      columns = @grid.getColumns()
      for column, columnIndex in columns
        @grid.updateCell rowIndex, columnIndex if column.type isnt 'assignment'

    cellFormatter: (row, col, submission) =>
      if !@rows[row].loaded
        @staticCellFormatter(row, col, '')
      else if !submission?
        @staticCellFormatter(row, col, '-')
      else
        assignment = @assignments[submission.assignment_id]
        if !assignment?
          @staticCellFormatter(row, col, '')
        else
          if assignment.grading_type == 'points' && assignment.points_possible
            SubmissionCell.out_of.formatter(row, col, submission, assignment)
          else
            (SubmissionCell[assignment.grading_type] || SubmissionCell).formatter(row, col, submission, assignment)

    staticCellFormatter: (row, col, val) =>
      "<div class='cell-content gradebook-cell'>#{val}</div>"

    groupTotalFormatter: (row, col, val, columnDef, student) =>
      return '' unless val?

      # rounds percentage to one decimal place
      percentage = Math.round((val.score / val.possible) * 1000) / 10
      percentage = 0 if isNaN(percentage)

      if val.possible and @options.grading_standard and columnDef.type is 'total_grade'
        letterGrade = GradeCalculator.letter_grade(@options.grading_standard, percentage)

      templateOpts =
        score: round(val.score, DISPLAY_PRECISION)
        possible: round(val.possible, DISPLAY_PRECISION)
        letterGrade: letterGrade
        percentage: percentage
      if columnDef.type == 'total_grade'
        templateOpts.warning = @totalGradeWarning
        templateOpts.lastColumn = true
        templateOpts.showPointsNotPercent = @showPointTotals

      groupTotalCellTemplate templateOpts

    htmlContentFormatter: (row, col, val, columnDef, student) =>
      return '' unless val?
      val

    calculateStudentGrade: (student) =>
      if student.loaded
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
      droppedAssignments = (name for name, assignment of student when name.match(/assignment_\d+/) and assignment.drop?)
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
      $headers = $('#gradebook_grid .container_1').find('.slick-header-columns')
      originalItemsSelector = $headers.sortable 'option', 'items'
      onlyAssignmentColsSelector = '> *:not([id*="assignment_group"]):not([id*="total_grade"])'
      (makeOnlyAssignmentsSortable = ->
        $headers.sortable 'option', 'items', onlyAssignmentColsSelector
        $notAssignments = $(originalItemsSelector, $headers).not($(onlyAssignmentColsSelector, $headers))
        $notAssignments.data('sortable-item', null)
      )()
      (initHeaderDropMenus = =>
        $headers.find('.assignment_header_drop').click (event) =>
          $link = $(event.target)
          unless $link.data('gradebookHeaderMenu')
            $link.data('gradebookHeaderMenu', new GradebookHeaderMenu(@assignments[$link.data('assignmentId')], $link, this))
          return false
      )()
      originalStopFn = $headers.sortable 'option', 'stop'
      (fixupStopCallback = ->
        $headers.sortable 'option', 'stop', (event, ui) ->
          # we need to set the items selector back to the default because slickgrid's 'stop'
          # function relies on it to re-render correctly.  if not it will render without the
          # assignment group and final grade columns
          $headers.sortable 'option', 'items', originalItemsSelector
          returnVal = originalStopFn.apply(this, arguments)
          makeOnlyAssignmentsSortable() # set it back
          initHeaderDropMenus()
          fixupStopCallback() # originalStopFn re-creates sortable widget so we need to re-fix
          returnVal
      )()

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
      $columnHeader.find('.slick-column-name').html(columnDef.name)
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
        Array::push.apply htmlLines, $.map(SubmissionCell.classesBasedOnSubmission(submission, assignment), (c)=> GRADEBOOK_TRANSLATIONS["#submission_tooltip_#{c}"])
      else if assignment.points_possible?
        htmlLines.push I18n.t('points_out_of', "out of %{points_possible}", points_possible: assignment.points_possible)

      $hoveredCell.data('tooltip', $("<span />",
        class: 'gradebook-tooltip'
        css:
          left: offset.left - 15
          top: offset.top
          zIndex: 10000
          display: 'block'
        html: htmlLines.join('<br />')
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

      @grid.getEditorLock().commitCurrentEdit()

    onGridInit: () ->
      tooltipTexts = {}
      $(@spinner.el).remove()
      $('#gradebook_wrapper').show()
      @uid = @grid.getUID()
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
          data = $(event.currentTarget).data()
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

      @$grid.on('keydown', @handleKeys)

      @kbDialog = new KeyboardNavDialog().render(keyboardNavTemplate({@keyBindings}))
      # when we close a dialog we want to return focus to the grid
      $(document).on('dialogclose', (e) =>
        setTimeout(( =>
          @grid.editActiveCell()
        ), 0)
      )
      $(document).trigger('gridready')

    keyBindings:
      #   keyCode:
      #   handler: function
      #   key: the string representation of the key pressed - for use in the help dialog
      #   desc: string describing what the shortcut does - for use in the help dialog
      [
        {
        keyCode: 83
        handler: 'sortOnHeader'
        key: I18n.t 'keycodes.sort', 's'
        desc: I18n.t 'keyboard_sort_desc', 'Sort the grid on the current active column'
        }
        {
        keyCode: 77
        handler: 'showAssignmentMenu'
        key: I18n.t 'keycodes.menu', 'm'
        desc: I18n.t 'keyboard_menu_desc', 'Open the menu for active column\'s assignment'
        }
         # this one is just for display in the dialog, the menu will take care of itself
        {
        keyCode: null
        key: I18n.t 'keycodes.close_menu', 'esc'
        desc: I18n.t 'keyboard_close_menu', 'Close the currently active assignment menu'
        }

        {
        keyCode: 71
        handler: 'gotoAssignment'
        key: I18n.t 'keycodes.goto_assignment', 'g'
        desc: I18n.t 'keyboard_assignment_desc', 'Go to the current assignment\'s detail page'
        }
        {
        keyCode: 67
        handler: 'showCommentDialog'
        key: I18n.t 'keycodes.comment', 'c'
        desc: I18n.t 'keyboard_comment_desc', 'Comment on the active submission'
        }
      ]

    getHeaderFromActiveCell: =>
      coords = @grid.getActiveCell()
      @$grid.find('.slick-header-column').eq(coords.cell)

    showAssignmentMenu: =>
      @getHeaderFromActiveCell().find('.gradebook-header-drop').click()
      $('.gradebook-header-menu:visible').focus()

    sortOnHeader: =>
      @getHeaderFromActiveCell().click()

    gotoAssignment: =>
      url = @getHeaderFromActiveCell().find('.assignment-name').attr('href')
      window.location = url

    showCommentDialog: =>
      $(@grid.getActiveCellNode()).find('.gradebook-cell-comment').click()

    handleKeys: (e) =>
      # makes sure the focus sink elements are currently active
      return unless $(document.activeElement).is('[hidefocus]')
      modifiers = ['shiftKey', 'altKey', 'ctrlKey']
      return if _.any(e[mod] for mod in modifiers)
      b = _.find(@keyBindings, (binding) ->
        binding.keyCode == e.keyCode
      )
      b?.handler and @[b.handler]?(e)

    initHeader: =>
      if @sections_enabled
        allSectionsText = I18n.t('all_sections', 'All Sections')
        sections = [{ name: allSectionsText, checked: !@sectionToShow}]
        for id, s of @sections
          sections.push
            name: s.name
            id: id
            checked: @sectionToShow is id

        $sectionToShowMenu = $(sectionToShowMenuTemplate(sections: sections))
        (updateSectionBeingShownText = =>
          $('#section_being_shown').html(if @sectionToShow then @sections[@sectionToShow].name else allSectionsText)
        )()
        $('#section_to_show').after($sectionToShowMenu).show().kyleMenu()
        $sectionToShowMenu.bind 'menuselect', (event, ui) =>
          @sectionToShow = $sectionToShowMenu.find('[aria-checked="true"] input[name="section_to_show_radio"]').val()
          userSettings[ if @sectionToShow then 'contextSet' else 'contextRemove']('grading_show_only_section', @sectionToShow)
          updateSectionBeingShownText()
          @buildRows()

      $settingsMenu = $('#gradebook_settings').next()
      $.each ['show_attendance', 'include_ungraded_assignments', 'show_concluded_enrollments'], (i, setting) =>
        $settingsMenu.find("##{setting}").prop('checked', !!@[setting]).change (event) =>
          if setting is 'show_concluded_enrollments' and @options.course_is_concluded and @show_concluded_enrollments
            $("##{setting}").prop('checked', true)
            $settingsMenu.menu("refresh")
            return alert(I18n.t 'concluded_course_error_message', 'This is a concluded course, so only concluded enrollments are available.')
          @[setting] = $(event.target).is(':checked')
          userSettings.contextSet setting, @[setting]
          window.location.reload() if setting is 'show_concluded_enrollments'
          @grid.setColumns @getVisibleGradeGridColumns() if setting is 'show_attendance'
          @buildRows()

      # don't show the "show attendance" link in the dropdown if there's no attendance assignments
      unless (_.detect @assignments, (a) -> (''+a.submission_types) == "attendance")
        $settingsMenu.find('#show_attendance').closest('li').hide()

      @$columnArrangementTogglers = $('#gradebook-toolbar [data-arrange-columns-by]').bind 'click', (event) =>
        event.preventDefault()
        newSortOrder = { sortType: $(event.currentTarget).data('arrangeColumnsBy') }
        @arrangeColumnsBy(newSortOrder)
      @arrangeColumnsBy(@getStoredSortOrder())

      $('#gradebook_settings').show().kyleMenu()

      $upload_modal = null
      $settingsMenu.find('.gradebook_upload_link').click (event) =>
        event.preventDefault()
        unless $upload_modal
          locals =
            download_gradebook_csv_url: "#{@options.context_url}/gradebook.csv"
            action: "#{@options.context_url}/gradebook_uploads"
            authenticityToken: ENV.AUTHENTICITY_TOKEN
          $upload_modal = $(gradebook_uploads_form(locals))
            .dialog
              bgiframe: true
              autoOpen: false
              modal: true
              width: 720
              resizable: false
            .fixDialogButtons()
        $upload_modal.dialog('open')

      $settingsMenu.find('.student_names_toggle').click (e) ->
        $wrapper = $('.grid-canvas')
        $wrapper.toggleClass('hide-students')

        if $wrapper.hasClass('hide-students')
          $(this).text I18n.t('show_student_names', 'Show Student Names')
        else
          $(this).text I18n.t('hide_student_names', 'Hide Student Names')

      @userFilter = new InputFilterView el: '.gradebook_filter input'
      @userFilter.on 'input', @onUserFilterInput

      @showPointTotals = @setPointTotals userSettings.contextGet('show_point_totals')
      totalHeader = new TotalColumnHeaderView
        showingPoints: => @showPointTotals
        toggleShowingPoints: @togglePointsOrPercentTotals.bind(this)
        weightedGroups: @weightedGroups.bind(this)
      totalHeader.render()

    weightedGroups: ->
      @options.group_weighting_scheme == "percent"

    setPointTotals: (showPoints) ->
      @showPointTotals = if @weightedGroups()
        false
      else
        showPoints

    togglePointsOrPercentTotals: ->
      @setPointTotals(not @showPointTotals)
      userSettings.contextSet('show_point_totals', @showPointTotals)
      @grid.invalidate()

    onUserFilterInput: (term) =>
      # put rows back on the students for dropped assignments

      data = @grid.getData()
      _.each data, (student) ->
        if student.beforeFilteredRow?
          student.row = student.beforeFilteredRow
          delete student.beforeFilteredRow

      # put the removed items back in their proper order
      _.each @userFilterRemovedRows.reverse(), (removedStudentItem) =>
        data.splice removedStudentItem.index, 0, removedStudentItem.data
      @userFilterRemovedRows = []

      if term != ''
        propertiesToMatch = ['name', 'login_id', 'short_name', 'sortable_name']
        index = data.length
        while index--
          student = data[index]
          matched = _.any propertiesToMatch, (prop) =>
            student[prop]?.match new RegExp term, 'i'
          if not matched
            # remove the student, save the item and its index so we can put it
            # back in order
            item =
              index: index
              data: data.splice(index, 1)[0]
            @userFilterRemovedRows.push item

      for student, index in data
        student.beforeFilteredRow = student.row
        student.row = index

      @grid.setData(data)
      @grid.invalidate()

    getVisibleGradeGridColumns: ->
      res = [].concat @parentColumns
      for column in @allAssignmentColumns
        submissionType = ''+ column.object.submission_types
        res.push(column) unless submissionType is "not_graded" or
                                submissionType is "attendance" and !@show_attendance
      res.concat(@aggregateColumns)

    assignmentHeaderHtml: (assignment) ->
      columnHeaderTemplate
        assignment: assignment
        href: assignment.html_url
        showPointsPossible: assignment.points_possible?

    initGrid: =>
      #this is used to figure out how wide to make each column
      $widthTester = $('<span style="padding:10px" />').appendTo('#content')
      testWidth = (text, minWidth, maxWidth) ->
        width = Math.max($widthTester.text(text).outerWidth(), minWidth)
        Math.min width, maxWidth

      @setAssignmentWarnings()

      # I would like to make this width a little larger, but there's a dependency somewhere else that
      # I can't find and if I change it, the layout gets messed up.
      @parentColumns = [{
        id: 'student'
        name: I18n.t 'student_name', 'Student Name'
        field: 'display_name'
        width: 150
        cssClass: "meta-cell"
        resizable: true
        sortable: true
        formatter: @htmlContentFormatter
      },
      {
        id: 'secondary_identifier'
        name: I18n.t 'secondary_id', 'Secondary ID'
        field: 'secondary_identifier'
        width: 100
        cssClass: "meta-cell secondary_identifier_cell"
        resizable: true
        sortable: true
        formatter: @htmlContentFormatter
      }]

      @allAssignmentColumns = for id, assignment of @assignments
        outOfFormatter = assignment &&
                         assignment.grading_type == 'points' &&
                         assignment.points_possible? &&
                         SubmissionCell.out_of
        minWidth = if outOfFormatter then 70 else 90
        fieldName = "assignment_#{id}"
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
          width: testWidth(assignment.name, minWidth, columnWidths.assignment.default_max),
          sortable: true
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

      @aggregateColumns = for id, group of @assignmentGroups
        html = "#{group.name}"
        if group.group_weight?
          percentage =  I18n.toPercentage(group.group_weight, precision: 2)
          html += """
            <div class='assignment-points-possible'>
              #{I18n.t 'percent_of_grade', "%{percentage} of grade", percentage: percentage}
            </div>
          """
        {
          id: "assignment_group_#{id}"
          field: "assignment_group_#{id}"
          formatter: @groupTotalFormatter
          name: html
          toolTip: group.name
          object: group
          minWidth: columnWidths.assignmentGroup.min,
          maxWidth: columnWidths.assignmentGroup.max,
          width: testWidth(group.name, columnWidths.assignmentGroup.min, columnWidths.assignmentGroup.default_max)
          cssClass: "meta-cell assignment-group-cell",
          sortable: true
          type: 'assignment_group'
        }

      total = I18n.t "total", "Total"
      @aggregateColumns.push
        id: "total_grade"
        field: "total_grade"
        formatter: @groupTotalFormatter
        name: """
          #{total}
          <div id=total_column_header></div>
        """
        toolTip: total
        minWidth: columnWidths.total.min
        maxWidth: columnWidths.total.max
        width: testWidth("Total", columnWidths.total.min, columnWidths.total.max)
        cssClass: "total-cell"
        sortable: true
        type: 'total_grade'

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

      @grid.onCellChange.subscribe (event, data) =>
        @calculateStudentGrade(data.item)
        @grid.invalidate()
      # this is a faux blur event for SlickGrid.
      $('body').on('click', @onGridBlur)

      @grid.onSort.subscribe (event, data) =>
        if data.sortCol.field == "display_name" || data.sortCol.field == "secondary_identifier"
          sortProp = if data.sortCol.field == "display_name"
            "sortable_name"
          else
            "secondary_identifier"
          @sortRowsBy (a, b) =>
            [b, a] = [a, b] if not data.sortAsc
            @localeSort(a[sortProp], b[sortProp])
        else
          @sortRowsBy (a, b) ->
            aScore = a[data.sortCol.field]?.score
            bScore = b[data.sortCol.field]?.score
            aScore = -99999999999 if not aScore and aScore != 0
            bScore = -99999999999 if not bScore and bScore != 0
            if data.sortAsc then aScore - bScore else bScore - aScore

      @grid.onKeyDown.subscribe ->
        # TODO: start editing automatically when a number or letter is typed
        false

      @grid.onColumnsReordered.subscribe @storeCustomColumnOrder

      @onGridInit()


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

    localeSort: (a, b) =>
      a.localeCompare b,
        window.I18n.locale,
        sensitivity: 'accent', numeric: true

    # show warnings for bad grading setups
    setAssignmentWarnings: =>
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
          @totalGradeWarning = I18n.t 'invalid_assignment_groups_warning',
            one: "Score does not include %{groups} because it has
                  no points possible"
            other: "Score does not include %{groups} because they have
                    no points possible"
          ,
            groups: $.toSentence(groupNames)
            count: groupNames.length

      else
        # no assignments have points possible
        pointsPossible = _.inject @assignments
        , ((sum, a) -> sum + (a.points_possible || 0))
        , 0

        if pointsPossible == 0
          @totalGradeWarning = I18n.t 'no_assignments_have_points_warning'
          , "Can't compute score until an assignment has points possible"

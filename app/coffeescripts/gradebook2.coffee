# This class both creates the slickgrid instance, and acts as the data source
# for that instance.
I18n.scoped 'gradebook2', (I18n) ->
  this.Gradebook = class Gradebook
    constructor: (@options) ->
      @chunk_start = 0
      @students    = {}
      @rows        = []
      @filterFn    = (student) -> true
      @sortFn      = (student) -> student.display_name
      @init()
      @includeUngradedAssignments = false

    init: () ->
      if @options.assignment_groups
        return @gotAssignmentGroups(@options.assignment_groups)
      $.ajaxJSON( @options.assignment_groups_url, "GET", {}, @gotAssignmentGroups )

    gotAssignmentGroups: (assignment_groups) =>
      @assignment_groups = {}
      @assignments       = {}
      for group in assignment_groups
        $.htmlEscapeValues(group)
        @assignment_groups[group.id] = group
        for assignment in group.assignments
          $.htmlEscapeValues(assignment)
          assignment.due_at = $.parseFromISO(assignment.due_at) if assignment.due_at
          @assignments[assignment.id] = assignment
      if @options.sections
        return @gotStudents(@options.sections)
      $.ajaxJSON( @options.sections_and_students_url, "GET", {}, @gotStudents )

    gotStudents: (sections) =>
      @sections = {}
      @rows = []
      for section in sections
        $.htmlEscapeValues(section)
        @sections[section.id] = section
        for student in section.students
          $.htmlEscapeValues(student)
          student.computed_current_score ||= 0
          student.computed_final_score ||= 0
          student.secondary_identifier = student.sis_login_id || student.login_id
          @students[student.id] = student
          student.section = section
          # fill in dummy submissions, so there's something there even if the
          # student didn't submit anything for that assignment
          for id, assignment of @assignments
            student["assignment_#{id}"] ||= { assignment_id: id, user_id: student.id }
          @rows.push(student)

      @sections_enabled = sections.length > 1

      for id, student of @students
        student.display_name = "<div class='student-name'>#{student.name}</div>"
        student.display_name += "<div class='student-section'>#{student.section.name}</div>" if @sections_enabled

      @initGrid()
      @buildRows()
      @getSubmissionsChunk()

    # filter, sort, and build the dataset for slickgrid to read from, then force
    # a full redraw
    buildRows: () ->
      @rows.length = 0
      sortables = {}

      for id, student of @students
        student.row = -1
        if @filterFn(student)
          @rows.push(student)
          sortables[student.id] = @sortFn(student)

      @rows.sort (a, b) ->
        if sortables[a.id] < sortables[b.id] then -1
        else if sortables[a.id] > sortables[b.id] then 1
        else 0

      student.row = i for student, i in @rows
      @multiGrid.removeAllRows()
      @multiGrid.updateRowCount()
      @multiGrid.render()

    sortBy: (sort) ->
      @sortFn = switch sort
        when "display_name" then (student) -> student.display_name
        when "section" then (student) -> student.section.name
        when "grade_desc" then (student) -> -student.computed_current_score
        when "grade_asc" then (student) -> student.computed_current_score
      this.buildRows()

    getSubmissionsChunk: (student_id) ->
      if @options.submissions
        return this.gotSubmissionsChunk(@options.submissions)
      students = @rows[@chunk_start...(@chunk_start+@options.chunk_size)]
      params = {
        student_ids: (student.id for student in students)
        assignment_ids: (id for id, assignment of @assignments)
        response_fields: ['user_id', 'url', 'score', 'grade', 'submission_type', 'submitted_at', 'assignment_id', 'grade_matches_current_submission']
      }
      if students.length > 0
        $.ajaxJSON(@options.submissions_url, "GET", params, @gotSubmissionsChunk)

    gotSubmissionsChunk: (student_submissions) =>
      for data in student_submissions
        student = @students[data.user_id]
        student.submissionsAsArray = []
        for submission in data.submissions
          submission.submitted_at = $.parseFromISO(submission.submitted_at) if submission.submitted_at
          student["assignment_#{submission.assignment_id}"] = submission
          student.submissionsAsArray.push(submission)
        student.loaded = true
        @multiGrid.removeRow(student.row)
        @calculateStudentGrade(student)
      @multiGrid.render()
      @chunk_start += @options.chunk_size
      @getSubmissionsChunk()

    cellFormatter: (row, col, submission) =>
      if !@rows[row].loaded
        @staticCellFormatter(row, col, '')
      else if !submission?.grade
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
      gradeToShow = val[if @includeUngradedAssignments then 'final' else 'current']
      percentage = (gradeToShow.score/gradeToShow.possible)*100
      percentage = Math.round(percentage * 10) / 10
      percentage = 0 if isNaN(percentage)
      if !gradeToShow.possible then percentage = '-' else percentage+= "%"
      res = """
      <div class="gradebook-cell">
        #{if columnDef.field == 'total_grade' then '' else '<div class="gradebook-tooltip">'+ gradeToShow.score + ' / ' + gradeToShow.possible + '</div>'}
        #{percentage}
      </div>
      """
      res

    calculateStudentGrade: (student) =>
      if student.loaded
        result = INST.GradeCalculator.calculate(student.submissionsAsArray, @assignment_groups, 'percent')
        for group in result.group_sums
          student["assignment_group_#{group.group.id}"] = {current: group.current, 'final': group['final']}
        student["total_grade"] = {current: result.current, 'final': result['final']}

    highlightColumn: (columnIndexOrEvent) =>
      if isNaN(columnIndexOrEvent)
        # then assume that columnIndexOrEvent is an event, so figure out which column
        # it is based on its class name
        match = columnIndexOrEvent.currentTarget.className.match(/c\d+/)
        if match
          columnIndexOrEvent = match.toString().replace('c', '')
      @$grid.find('.slick-header-column:eq(' + columnIndexOrEvent + ')').addClass('hovered-column')

    unhighlightColumns: () =>
      @$grid.find('.hovered-column').removeClass('hovered-column')

    showCommentDialog: =>
      $('<div>TODO: show comments and stuff</div>').dialog()
      return false

    onGridInit: () ->
      tooltipTexts = {}
      @$grid = $('#gradebook_grid')
        .fillWindowWithMe({
          alsoResize: '#gradebook_students_grid',
          onResize: () =>
            @multiGrid.resizeCanvas()
        })
        .delegate('.slick-cell', 'mouseenter.gradebook focusin.gradebook', @highlightColumn)
        .delegate('.slick-cell', 'mouseleave.gradebook focusout.gradebook', @unhighlightColumns)
        .delegate('.gradebook-cell', 'hover.gradebook', -> $(this).toggleClass('hover'))
        .delegate('.gradebook-cell-comment', 'click.gradebook', @showCommentDialog )

      # # debugging stuff, remove
      # events =
      #   onSort: null,
      #   onHeaderContextMenu: null,
      #   onHeaderClick: null,
      #   onClick: null,
      #   onDblClick: null,
      #   onContextMenu: null,
      #   onKeyDown: null,
      #   onAddNewRow: null,
      #   onValidationError: null,
      #   onViewportChanged: null,
      #   onSelectedRowsChanged: null,
      #   onColumnsReordered: null,
      #   onColumnsResized: null,
      #   onBeforeMoveRows: null,
      #   onMoveRows: null,
      #   # onCellChange: "Raised when cell has been edited.   Args: row,cell,dataContext.",
      #   onBeforeEditCell : "Raised before a cell goes into edit mode.  Return false to cancel.  Args: row,cell,dataContext."
      #   onBeforeCellEditorDestroy: "Raised before a cell editor is destroyed.  Args: current cell editor."
      #   onBeforeDestroy: "Raised just before the grid control is destroyed (part of the destroy() method)."
      #   onCurrentCellChanged: "Raised when the selected (active) cell changed.  Args: {row:currentRow, cell:currentCell}."
      #   onCellRangeSelected: "Raised when a user selects a range of cells.  Args: {from:{row,cell}, to:{row,cell}}."
      # $.each events, (event, documentation) =>
      #   old = @multiGrid.grids[1][event]
      #   @multiGrid.grids[1][event] = () ->
      #     $.isFunction(old) && old.apply(this, arguments)
      #     console.log(event, documentation, arguments)
      $('#grid-options').click (event) ->
        event.preventDefault()
        $('#sort_rows_dialog').dialog('close').dialog(width: 400, height: 300)
      # set up row sorting options
      $('#sort_rows_dialog .by_section').hide() unless @sections_enabled
      $('#sort_rows_dialog button.sort_rows').click ->
        gradebook.sortBy($(this).data('sort_by'))
        $('#sort_rows_dialog').dialog('close')

    initGrid: () ->
      #this is used to figure out how wide to make each column
      $widthTester = $('<span style="padding:10px" />').appendTo('#content')
      testWidth = (text, minWidth) ->
        Math.max($widthTester.text(text).outerWidth(), minWidth)

      @columns = [{
        id: 'student',
        name: "<a href='javascript:void(0)' id='grid-options'>Options</a>",
        field: 'display_name',
        width: 150,
        cssClass: "meta-cell"
      },
      {
        id: 'secondary_identifier',
        name: 'secondary ID',
        field: 'secondary_identifier'
        width: 100,
        cssClass: "meta-cell secondary_identifier_cell"
      }]

      for id, assignment of @assignments when assignment.submission_types isnt "not_graded"
        html = "<div class='assignment-name'>#{assignment.name}</div>"
        html += "<div class='assignment-points-possible'>#{I18n.t 'points_out_of', "out of %{points_possible}", points_possible: assignment.points_possible}</div>" if assignment.points_possible?
        outOfFormatter = assignment &&
                         assignment.grading_type == 'points' &&
                         assignment.points_possible? &&
                         SubmissionCell.out_of
        minWidth = if outOfFormatter then 70 else 50

        @columns.push
          id: "assignment_#{id}"
          field: "assignment_#{id}"
          name: html
          object: assignment
          formatter: this.cellFormatter
          editor: outOfFormatter ||
                  SubmissionCell[assignment.grading_type] ||
                  SubmissionCell
          minWidth: minWidth,
          maxWidth:200,
          width: testWidth(assignment.name, minWidth)

      for id, group of @assignment_groups
        html = "#{group.name}"
        html += "<div class='assignment-points-possible'>#{I18n.t 'percent_of_grade', "%{percentage} of grade", percentage: I18n.toPercentage(group.group_weight, precision: 0)}</div>" if group.group_weight?

        @columns.push
          id: "assignment_group_#{id}"
          field: "assignment_group_#{id}"
          formatter: @groupTotalFormatter
          name: html
          object: group
          minWidth: 35,
          maxWidth:200,
          width: testWidth(group.name, 35)
          cssClass: "meta-cell assignment-group-cell"

      @columns.push
        id: "total_grade"
        field: "total_grade"
        formatter: @groupTotalFormatter
        name: "Total"
        minWidth: 50,
        maxWidth: 100,
        width: testWidth("Total", 50)
        cssClass: "total-cell"

      $widthTester.remove()

      options = $.extend({
        enableCellNavigation: false
        enableColumnReorder: false
        enableAsyncPostRender: true
        asyncPostRenderDelay: 1
        autoEdit: true # whether to go into edit-mode as soon as you tab to a cell
        rowHeight: 35
      }, @options)

      grids = [{
        selector: '#gradebook_students_grid'
        columns:  @columns[0..1]
      }, {
        selector: '#gradebook_grid'
        columns:  @columns[2...@columns.length]
        options:
          enableCellNavigation: true
          editable: true
          syncColumnCellResize: true
      }]

      @multiGrid = new MultiGrid(@rows, options, grids, 1)
      # this is the magic that actually updates group and final grades when you edit a cell
      @multiGrid.grids[1].onCellChange = (row, col, student) =>
        @calculateStudentGrade(student)
      @multiGrid.parent_grid.onKeyDown = () =>
        # TODO: start editing automatically when a number or letter is typed
        false
      @onGridInit?()

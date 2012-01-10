# This class both creates the slickgrid instance, and acts as the data source for that instance.
define 'compiled/Gradebook', [
  'i18n'
  'jst/gradebook2/section_to_show_menu'
], (I18n, sectionToShowMenuTemplate) ->
  I18n = I18n.scoped 'gradebook2'

  class Gradebook
    minimumAssignmentColumWidth = 10

    constructor: (@options) ->
      @chunk_start = 0
      @students    = {}
      @rows        = []
      @sortFn      = (student) -> student.display_name
      @assignmentsToHide = ($.store.userGet("hidden_columns_#{@options.context_code}") || '').split(',')
      @sectionToShow = Number($.store.userGet("grading_show_only_section#{@options.context_id}")) || undefined
      @show_attendance = $.store.userGet("show_attendance_#{@options.context_code}") == 'true'
      @include_ungraded_assignments = $.store.userGet("include_ungraded_assignments_#{@options.context_code}") == 'true'
      $.subscribe 'assignment_group_weights_changed', @buildRows
      $.subscribe 'assignment_muting_toggled', @buildRows
      $.subscribe 'submissions_updated', @updateSubmissionsFromExternal
      promise = $.when(
        $.ajaxJSON( @options.assignment_groups_url, "GET", {}, @gotAssignmentGroups),
        $.ajaxJSON( @options.sections_and_students_url, "GET", @sectionToShow && {sections: [@sectionToShow]})
      ).then (assignmentGroupsArgs, studentsArgs) =>
        @gotStudents.apply(this, studentsArgs)
      @spinner = new Spinner()
      $(@spinner.spin().el).css(
        opacity: 0.5
        top: '50%'
        left: '50%'
      ).addClass('use-css-transitions-for-show-hide').appendTo('#main')

    gotAssignmentGroups: (assignmentGroups) =>
      @assignmentGroups = {}
      @assignments      = {}

      # purposely passing the @options and assignmentGroups by reference so it can update
      # an assigmentGroup's .group_weight and @options.group_weighting_scheme
      new AssignmentGroupWeightsDialog context: @options, assignmentGroups: assignmentGroups
      for group in assignmentGroups
        $.htmlEscapeValues(group)
        @assignmentGroups[group.id] = group
        for assignment in group.assignments
          $.htmlEscapeValues(assignment)
          assignment.assignment_group = group
          assignment.due_at = $.parseFromISO(assignment.due_at) if assignment.due_at
          @assignments[assignment.id] = assignment

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
      @getSubmissionsChunks()
      @initHeader()

    arrangeColumnsBy: (newThingToArrangeBy) =>
      if newThingToArrangeBy and newThingToArrangeBy != @_sortColumnsBy
        @$columnArrangementTogglers.each ->
          $(this).closest('li').showIf $(this).data('arrangeColumnsBy') isnt newThingToArrangeBy
        @_sortColumnsBy = newThingToArrangeBy
        $.store[ if newThingToArrangeBy is 'due_date' then 'userSet' else 'userRemove']("sort_grade_colums_by_#{@options.context_id}", newThingToArrangeBy)
        columns = @gradeGrid.getColumns()
        columns.sort @columnSortFn
        @gradeGrid.setColumns(columns)
        @fixColumnReordering()
        @buildRows()
      @_sortColumnsBy ||= $.store.userGet("sort_grade_colums_by_#{@options.context_id}") || 'assignment_group'

    columnSortFn: (a,b) =>
      return -1 if b.type is 'total_grade'
      return  1 if a.type is 'total_grade'
      return -1 if b.type is 'assignment_group' and a.type isnt 'assignment_group'
      return  1 if a.type is 'assignment_group' and b.type isnt 'assignment_group'
      if a.type is 'assignment_group' and b.type is 'assignment_group'
        return a.object.position - b.object.position
      else if a.type is 'assignment' and b.type is 'assignment'
        if @arrangeColumnsBy() is 'assignment_group'
          diffOfAssignmentGroupPosition = a.object.assignment_group.position - b.object.assignment_group.position
          diffOfAssignmentPosition = a.object.position - b.object.position

          # order first by assignment_group position and then by assignment position
          # will work when there are less than 1000000 assignments in an assignment_group
          return (diffOfAssignmentGroupPosition * 1000000) + diffOfAssignmentPosition
        else
          aDate = a.object.due_at?.timestamp or Number.MAX_VALUE
          bDate = b.object.due_at?.timestamp or Number.MAX_VALUE
          if aDate is bDate
            return 0 if a.object.name is b.object.name
            return (if a.object.name > b.object.name then 1 else -1)
          return aDate - bDate
      throw "unhandled column sort condition"

    rowFilter: (student) =>
      !@sectionToShow || (student.section.id == @sectionToShow)

    # filter, sort, and build the dataset for slickgrid to read from, then force
    # a full redraw
    buildRows: =>
      @rows.length = 0
      sortables = {}

      for id, column of @gradeGrid.getColumns() when ''+column.object?.submission_types is "attendance"
        column.unselectable = !@show_attendance
        column.cssClass = if @show_attendance then '' else 'completely-hidden'
        @$grid.find("[id*='#{column.id}']").showIf(@show_attendance)

      for id, student of @students
        student.row = -1
        if @rowFilter(student)
          @rows.push(student)
          @calculateStudentGrade(student)
          sortables[student.id] = @sortFn(student)

      @rows.sort (a, b) ->
        if sortables[a.id] < sortables[b.id] then -1
        else if sortables[a.id] > sortables[b.id] then 1
        else 0

      student.row = i for student, i in @rows
      @multiGrid.removeAllRows()
      @multiGrid.updateRowCount()
      @multiGrid.render()

    getSubmissionsChunks: =>
      loop
        students = @rows[@chunk_start...(@chunk_start+@options.chunk_size)]
        unless students.length
          @allSubmissionsLoaded = true
          break
        params =
          student_ids: (student.id for student in students)
          assignment_ids: (id for id, assignment of @assignments)
          response_fields: ['user_id', 'url', 'score', 'grade', 'submission_type', 'submitted_at', 'assignment_id', 'grade_matches_current_submission']
        $.ajaxJSON(@options.submissions_url, "GET", params, @gotSubmissionsChunk)
        @chunk_start += @options.chunk_size

    gotSubmissionsChunk: (student_submissions) =>
      for data in student_submissions
        student = @students[data.user_id]
        @updateSubmission(submission) for submission in data.submissions
        student.loaded = true
        @multiGrid.removeRow(student.row)
        @calculateStudentGrade(student)
      @multiGrid.render()

    updateSubmission: (submission) =>
      student = @students[submission.user_id]
      submission.submitted_at = $.parseFromISO(submission.submitted_at) if submission.submitted_at
      student["assignment_#{submission.assignment_id}"] = submission

    # this is used after the CurveGradesDialog submit xhr comes back.  it does not use the api
    # because there is no *bulk* submissions#update endpoint in the api.
    # It is different from gotSubmissionsChunk in that gotSubmissionsChunk expects an array of students
    # where each student has an array of submissions.  This one just expects an array of submissions,
    # they are not grouped by student.
    updateSubmissionsFromExternal: (submissions) =>
      for submission in submissions
        student = @students[submission.user_id]
        @updateSubmission(submission)
        @multiGrid.removeRow(student.row)
        @calculateStudentGrade(student)
      @multiGrid.render()

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
      gradeToShow = val
      percentage = Math.round((gradeToShow.score / gradeToShow.possible) * 100)
      percentage = 0 if isNaN(percentage)
      if !gradeToShow.possible then percentage = '-' else percentage += "%"
      """
      <div class="gradebook-cell">
        <div class="gradebook-tooltip">#{gradeToShow.score} / #{gradeToShow.possible}</div>
        #{percentage}
      </div>
      """

    calculateStudentGrade: (student) =>
      if student.loaded
        submissionsAsArray = (value for key, value of student when key.match /^assignment_(?!group)/)
        result = INST.GradeCalculator.calculate(submissionsAsArray, @assignmentGroups, @options.group_weighting_scheme)
        for group in result.group_sums
          student["assignment_group_#{group.group.id}"] = group[if @include_ungraded_assignments then 'final' else 'current']
        student["total_grade"] = result[if @include_ungraded_assignments then 'final' else 'current']

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

    # this is a workaroud to make it so only assignments are sortable but at the same time
    # so that the total and final grade columns don't dissapear after reordering columns
    fixColumnReordering: =>
      $headers = $('#gradebook_grid').find('.slick-header-columns')
      originalItemsSelector = $headers.sortable 'option', 'items'
      onlyAssignmentColsSelector = '> *:not([id*="assignment_group"]):not([id*="total_grade"])'
      (makeOnlyAssignmentsSortable = ->
        $headers.sortable 'option', 'items', onlyAssignmentColsSelector
        $notAssignments = $(originalItemsSelector, $headers).not($(onlyAssignmentColsSelector, $headers))
        $notAssignments.data('sortable-item', null)
      )()
      (initHeaderDropMenus = =>
        $headers.find('.gradebook-header-drop').click (event) =>
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
      colIndex = $columnHeader.index()
      columnDef = @gradeGrid.getColumns()[colIndex]
      columnDef.cssClass = (columnDef.cssClass || '').replace(' minimized', '') + ' minimized'
      columnDef.unselectable = true
      columnDef.unminimizedName = columnDef.name
      columnDef.name = ''
      @$grid.find(".c#{colIndex}").add($columnHeader).addClass('minimized')
      $columnHeader.data('minimized', true)
      @assignmentsToHide.push(columnDef.id)
      $.store.userSet("hidden_columns_#{@options.context_code}", $.uniq(@assignmentsToHide).join(','))

    unminimizeColumn: ($columnHeader) =>
      colIndex = $columnHeader.index()
      columnDef = @gradeGrid.getColumns()[colIndex]
      columnDef.cssClass = (columnDef.cssClass || '').replace(' minimized', '')
      columnDef.unselectable = false
      columnDef.name = columnDef.unminimizedName
      @$grid.find(".c#{colIndex}").add($columnHeader).removeClass('minimized')
      $columnHeader.removeData('minimized')
      @assignmentsToHide = $.grep @assignmentsToHide, (el) -> el != columnDef.id
      $.store.userSet("hidden_columns_#{@options.context_code}", $.uniq(@assignmentsToHide).join(','))

    hoverMinimizedCell: (event) =>
      $hoveredCell = $(event.currentTarget)
                     # get rid of hover class so that no other tooltips show up
                     .removeClass('hover')
      columnDef = @gradeGrid.getColumns()[$hoveredCell.index()]
      assignment = columnDef.object
      offset = $hoveredCell.offset()
      htmlLines = [assignment.name]
      if $hoveredCell.hasClass('slick-cell')
        submission = @rows[@gradeGrid.getCellFromEvent(event).row][columnDef.id]
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

    onGridInit: () ->
      @fixColumnReordering()
      tooltipTexts = {}
      $(@spinner.el).remove()
      $('#gradebook_wrapper').show()
      @$grid = grid = $('#gradebook_grid')
        .fillWindowWithMe({
          alsoResize: '#gradebook_students_grid',
          onResize: () =>
            @multiGrid.resizeCanvas()
        })
        .delegate '.slick-cell',
          'mouseenter.gradebook focusin.gradebook' : @highlightColumn
          'mouseleave.gradebook focusout.gradebook' : @unhighlightColumns
          'mouseenter focusin' : (event) ->
            grid.find('.hover, .focus').removeClass('hover focus')
            $(this).addClass (if event.type == 'mouseenter' then 'hover' else 'focus')
          'mouseleave focusout' : -> $(this).removeClass('hover focus')
        .delegate '.gradebook-cell-comment', 'click.gradebook', (event) =>
          event.preventDefault()
          data = $(event.currentTarget).data()
          SubmissionDetailsDialog.open @assignments[data.assignmentId], @students[data.userId], @options
        .delegate '.minimized',
          'mouseenter' : @hoverMinimizedCell,
          'mouseleave' : @unhoverMinimizedCell

      $('#gradebook_grid .slick-resizable-handle').live 'drag', (e,dd) =>
        @$grid.find('.slick-header-column').each (i, elem) =>
          $columnHeader = $(elem)
          isMinimized = $columnHeader.data('minimized')
          if $columnHeader.outerWidth() <= minimumAssignmentColumWidth
            @minimizeColumn($columnHeader) unless isMinimized
          else if isMinimized
            @unminimizeColumn($columnHeader)
      $(document).trigger('gridready')

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
      # set up row sorting options

    initHeader: =>
      if @sections_enabled
        $section_being_shown = $('#section_being_shown')
        allSectionsText = I18n.t('all_sections', 'All Sections')
        sections = [{ name: allSectionsText, checked: !@sectionToShow}]
        for id, s of @sections
          sections.push
            name: s.name
            id: id
            checked: @sectionToShow is id

        $sectionToShowMenu = $(sectionToShowMenuTemplate(sections: sections, scrolling: sections.length > 15))
        (updateSectionBeingShownText = =>
          $section_being_shown.text(if @sectionToShow then @sections[@sectionToShow].name else allSectionsText)
        )()
        $('#section_to_show').after($sectionToShowMenu).show().kyleMenu
          buttonOpts: {icons: {primary: "ui-icon-sections", secondary: "ui-icon-droparrow"}}
        $sectionToShowMenu.bind 'menuselect', (event, ui) =>
          @sectionToShow = Number($sectionToShowMenu.find('[aria-checked="true"] input[name="section_to_show_radio"]').val()) || undefined
          $.store[ if @sectionToShow then 'userSet' else 'userRemove']("grading_show_only_section#{@options.context_id}", @sectionToShow)
          updateSectionBeingShownText()
          @buildRows()

      $settingsMenu = $('#gradebook_settings').next()
      $.each ['show_attendance', 'include_ungraded_assignments'], (i, setting) =>
        $settingsMenu.find("##{setting}").prop('checked', @[setting]).change (event) =>
          @[setting] = $(event.target).is(':checked')
          $.store.userSet "#{setting}_#{@options.context_code}", (''+@[setting])
          @buildRows()

      # don't show the "show attendance" link in the dropdown if there's no attendance assignments
      unless ($.detect @gradeGrid.getColumns(), -> this.object?.submission_types == "attendance")
        $settingsMenu.find('#show_attendance').hide()

      @$columnArrangementTogglers = $('#gradebook-toolbar [data-arrange-columns-by]').bind 'click', (event) =>
        event.preventDefault()
        thingToArrangeBy = $(event.currentTarget).data('arrangeColumnsBy')
        @arrangeColumnsBy(thingToArrangeBy)
      @arrangeColumnsBy('assignment_group')

      $('#gradebook_settings').show().kyleMenu
        buttonOpts: {icons: {primary: "ui-icon-cog", secondary: "ui-icon-droparrow"}}

      $upload_modal = null
      $settingsMenu.find('.gradebook_upload_link').click (event) =>
        event.preventDefault()
        unless $upload_modal
          locals =
            download_gradebook_csv_url: "#{@options.context_url}/gradebook.csv"
            action: "#{@options.context_url}/gradebook_uploads"
            authenticityToken: $("#ajax_authenticity_token").text()
          $upload_modal = $(Template('gradebook_uploads_form', locals))
            .dialog
              bgiframe: true
              autoOpen: false
              modal: true
              width: 720
              resizable: false
            .fixDialogButtons()
            .delegate '#gradebook-upload-help-trigger', 'click', ->
              $(this).hide()
              $('#gradebook-upload-help').show()
        $upload_modal.dialog('open')

    initGrid: =>
      #this is used to figure out how wide to make each column
      $widthTester = $('<span style="padding:10px" />').appendTo('#content')
      testWidth = (text, minWidth) -> Math.max($widthTester.text(text).outerWidth(), minWidth)

      @columns = [{
        id: 'student'
        name: I18n.t 'student_name', 'Student Name'
        field: 'display_name'
        width: 150
        cssClass: "meta-cell"
        resizable: false
        sortable: true
      },
      {
        id: 'secondary_identifier'
        name: I18n.t 'secondary_id', 'Secondary ID'
        field: 'secondary_identifier'
        width: 100
        cssClass: "meta-cell secondary_identifier_cell"
        resizable: false
        sortable: true
      }]

      for id, assignment of @assignments
        href = "#{@options.context_url}/assignments/#{assignment.id}"
        html = "<a class='assignment-name' href='#{href}'>#{assignment.name}</a>
                <a class='gradebook-header-drop' data-assignment-id='#{assignment.id}' href='#' role='button'>#{I18n.t 'assignment_options', 'Assignment Options'}</a>"
        html += "<div class='assignment-points-possible'>#{I18n.t 'points_out_of', "out of %{points_possible}", points_possible: assignment.points_possible}</div>" if assignment.points_possible?
        outOfFormatter = assignment &&
                         assignment.grading_type == 'points' &&
                         assignment.points_possible? &&
                         SubmissionCell.out_of
        minWidth = if outOfFormatter then 70 else 90
        fieldName = "assignment_#{id}"
        columnDef =
          id: fieldName
          field: fieldName
          name: html
          object: assignment
          formatter: this.cellFormatter
          editor: outOfFormatter ||
                  SubmissionCell[assignment.grading_type] ||
                  SubmissionCell
          minWidth: minimumAssignmentColumWidth,
          maxWidth:200,
          width: testWidth(assignment.name, minWidth),
          sortable: true
          toolTip: true
          type: 'assignment'

        if ''+assignment.submission_types is "not_graded"
          columnDef.cssClass = (columnDef.cssClass || '') + ' ungraded'
          columnDef.unselectable = true
        if fieldName in @assignmentsToHide
          columnDef.width = 10
          do (fieldName) =>
            $(document)
              .bind('gridready', => @minimizeColumn(@$grid.find("[id*='#{fieldName}']")))
              .unbind('gridready.render')
              .bind('gridready.render', => @gradeGrid.invalidate())
        @columns.push columnDef

      for id, group of @assignmentGroups
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
          cssClass: "meta-cell assignment-group-cell",
          sortable: true
          type: 'assignment_group'

      @columns.push
        id: "total_grade"
        field: "total_grade"
        formatter: @groupTotalFormatter
        name: "Total"
        minWidth: 50,
        maxWidth: 100,
        width: testWidth("Total", 50)
        cssClass: "total-cell",
        sortable: true
        type: 'total_grade'

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
          enableColumnReorder: true
      }]

      @multiGrid = new MultiGrid(@rows, options, grids, 1)
      # this is the magic that actually updates group and final grades when you edit a cell
      @gradeGrid = @multiGrid.grids[1]
      @gradeGrid.onCellChange = (row, col, student) => @calculateStudentGrade(student)
      sortRowsBy = (sortFn) =>
        @rows.sort(sortFn)
        student.row = i for student, i in @rows
        @multiGrid.invalidate()
      @gradeGrid.onSort = (sortCol, sortAsc) =>
        sortRowsBy (a, b) ->
          aScore = a[sortCol.field]?.score
          bScore = b[sortCol.field]?.score
          aScore = -99999999999 if not aScore and aScore != 0
          bScore = -99999999999 if not bScore and bScore != 0
          if sortAsc then bScore - aScore else aScore - bScore
      @multiGrid.grids[0].onSort = (sortCol, sortAsc) =>
        propertyToSortBy = {display_name: 'sortable_name', secondary_identifier: 'secondary_identifier'}[sortCol.field]
        sortRowsBy (a, b) ->
          res = if a[propertyToSortBy] < b[propertyToSortBy] then -1
          else if a[propertyToSortBy] > b[propertyToSortBy] then 1
          else 0
          if sortAsc then res else 0 - res

      @multiGrid.parent_grid.onKeyDown = () =>
        # TODO: start editing automatically when a number or letter is typed
        false
      @onGridInit()

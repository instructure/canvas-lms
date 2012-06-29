# This class both creates the slickgrid instance, and acts as the data source for that instance.
define [
  'i18n!gradebook2'
  'compiled/gradebook2/GRADEBOOK_TRANSLATIONS'
  'jquery'
  'underscore'
  'compiled/grade_calculator'
  'compiled/userSettings'
  'vendor/spin'
  'compiled/multi_grid'
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
], (I18n, GRADEBOOK_TRANSLATIONS, $, _, GradeCalculator, userSettings, Spinner, MultiGrid, SubmissionDetailsDialog, AssignmentGroupWeightsDialog, SubmissionCell, GradebookHeaderMenu, htmlEscape, gradebook_uploads_form, sectionToShowMenuTemplate, columnHeaderTemplate, groupTotalCellTemplate, rowStudentNameTemplate) ->

  class Gradebook
    columnWidths =
      assignment:
        min: 10
        max: 200
      assignmentGroup:
        min: 35
        max: 200
      total:
        min: 85
        max: 100

    constructor: (@options) ->
      @chunk_start = 0
      @students = {}
      @rows = []
      @studentsPage = 1
      @sortFn = (student) -> student.sortable_name
      @assignmentsToHide = userSettings.contextGet('hidden_columns') || []
      @sectionToShow = userSettings.contextGet 'grading_show_only_section'
      @show_attendance = userSettings.contextGet 'show_attendance'
      @include_ungraded_assignments = userSettings.contextGet 'include_ungraded_assignments'
      $.subscribe 'assignment_group_weights_changed', @buildRows
      $.subscribe 'assignment_muting_toggled', @handleAssignmentMutingChange
      $.subscribe 'submissions_updated', @updateSubmissionsFromExternal

      promise = $.when(
        $.ajaxJSON( @options.students_url, "GET"),
        $.ajaxJSON( @options.assignment_groups_url, "GET", {}, @gotAssignmentGroups),
        $.ajaxJSON( @options.sections_url, "GET", {}, @gotSections)
      ).then ([students, status, xhr]) =>
        @gotChunkOfStudents(students, xhr)

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
        htmlEscape(group)
        @assignmentGroups[group.id] = group
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

    gotChunkOfStudents: (studentEnrollments, xhr) =>
      for studentEnrollment in studentEnrollments
        student = studentEnrollment.user
        student.enrollment = studentEnrollment
        @students[student.id] ||= htmlEscape(student)
        @students[student.id].sections ||= []
        @students[student.id].sections.push(studentEnrollment.course_section_id)

      link = xhr.getResponseHeader('Link')
      if link && link.match /rel="next"/
        @studentsPage += 1
        $.ajaxJSON( @options.students_url, "GET", { "page": @studentsPage}, @gotChunkOfStudents)
      else
        @gotAllStudents()

    gotAllStudents: ->
      for id, student of @students
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

    arrangeColumnsBy: (newThingToArrangeBy) =>
      if newThingToArrangeBy and newThingToArrangeBy != @_sortColumnsBy
        @$columnArrangementTogglers.each ->
          $(this).closest('li').showIf $(this).data('arrangeColumnsBy') isnt newThingToArrangeBy
        @_sortColumnsBy = newThingToArrangeBy
        userSettings[ if newThingToArrangeBy is 'due_date' then 'contextSet' else 'contextRemove']('sort_grade_colums_by', newThingToArrangeBy)
        columns = @gradeGrid.getColumns()
        columns.sort @columnSortFn
        @gradeGrid.setColumns(columns)
        @fixColumnReordering()
        @buildRows()
      @_sortColumnsBy ||= userSettings.contextGet('sort_grade_colums_by') || 'assignment_group'

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
      !@sectionToShow || (@sectionToShow in student.sections)

    handleAssignmentMutingChange: (assignment) =>
      idx = @gradeGrid.getColumnIndex("assignment_#{assignment.id}")
      colDef = @gradeGrid.getColumns()[idx]
      colDef.name = @assignmentHeaderHtml(assignment)
      @gradeGrid.setColumns(@gradeGrid.getColumns())
      @fixColumnReordering()
      @buildRows()

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
      @multiGrid.invalidate()

    getSubmissionsChunks: =>
      loop
        students = @rows[@chunk_start...(@chunk_start+@options.chunk_size)]
        unless students.length
          @allSubmissionsLoaded = true
          break
        params =
          student_ids: (student.id for student in students)
          response_fields: ['user_id', 'url', 'score', 'grade', 'submission_type', 'submitted_at', 'assignment_id', 'grade_matches_current_submission']
        $.ajaxJSON(@options.submissions_url, "GET", params, @gotSubmissionsChunk)
        @chunk_start += @options.chunk_size

    gotSubmissionsChunk: (student_submissions) =>
      for data in student_submissions
        student = @students[data.user_id]
        @updateSubmission(submission) for submission in data.submissions
        student.loaded = true
        @multiGrid.invalidateRow(student.row)
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
        @multiGrid.invalidateRow(student.row)
        @calculateStudentGrade(student)
      @multiGrid.render()

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

      groupTotalCellTemplate({
        score: val.score
        possible: val.possible
        letterGrade
        percentage
      })

    calculateStudentGrade: (student) =>
      if student.loaded
        finalOrCurrent = if @include_ungraded_assignments then 'final' else 'current'
        submissionsAsArray = (value for key, value of student when key.match /^assignment_(?!group)/)
        result = INST.GradeCalculator.calculate(submissionsAsArray, @assignmentGroups, @options.group_weighting_scheme)
        for group in result.group_sums
          student["assignment_group_#{group.group.id}"] = group[finalOrCurrent]
        student["total_grade"] = result[finalOrCurrent]


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
      columnDef.minimized = true
      @$grid.find(".l#{colIndex}").add($columnHeader).addClass('minimized')
      @assignmentsToHide.push(columnDef.id)
      userSettings.contextSet('hidden_columns', _.uniq(@assignmentsToHide))

    unminimizeColumn: ($columnHeader) =>
      colIndex = $columnHeader.index()
      columnDef = @gradeGrid.getColumns()[colIndex]
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

    # this is because of a limitation with SlickGrid,
    # when it makes the header row it does this:
    # $("<div class='slick-header-columns' style='width:10000px; left:-1000px' />")
    # if a course has a ton of assignments then it will not be wide enough to
    # contain them all
    fixMaxHeaderWidth: ->
      @$grid.find('.slick-header-columns').width(1000000)

    onGridInit: () ->
      @fixColumnReordering()
      tooltipTexts = {}
      $(@spinner.el).remove()
      $('#gradebook_wrapper').show()
      @$grid = grid = $('#gradebook_grid')
        .fillWindowWithMe({
          alsoResize: '#gradebook_students_grid',
          onResize: => @multiGrid.resizeCanvas()
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

      @fixMaxHeaderWidth()
      $('#gradebook_grid .slick-resizable-handle').live 'drag', (e,dd) =>
        @$grid.find('.slick-header-column').each (colIndex, elem) =>
          $columnHeader = $(elem)
          columnDef = @gradeGrid.getColumns()[colIndex]
          if $columnHeader.outerWidth() <= minimumAssignmentColumWidth
            @minimizeColumn($columnHeader) unless columnDef.minimized
          else if columnDef.minimized
            @unminimizeColumn($columnHeader)
      $(document).trigger('gridready')

    initHeader: =>
      if @sections_enabled
        allSectionsText = I18n.t('all_sections', 'All Sections')
        sections = [{ name: allSectionsText, checked: !@sectionToShow}]
        for id, s of @sections
          sections.push
            name: s.name
            id: id
            checked: @sectionToShow is id

        $sectionToShowMenu = $(sectionToShowMenuTemplate(sections: sections, scrolling: sections.length > 15))
        (updateSectionBeingShownText = =>
          $('#section_being_shown').html(if @sectionToShow then @sections[@sectionToShow].name else allSectionsText)
        )()
        $('#section_to_show').after($sectionToShowMenu).show().kyleMenu
          buttonOpts: {icons: {primary: "ui-icon-sections", secondary: "ui-icon-droparrow"}}
        $sectionToShowMenu.bind 'menuselect', (event, ui) =>
          @sectionToShow = Number($sectionToShowMenu.find('[aria-checked="true"] input[name="section_to_show_radio"]').val()) || undefined
          userSettings[ if @sectionToShow then 'contextSet' else 'contextRemove']('grading_show_only_section', @sectionToShow)
          updateSectionBeingShownText()
          @buildRows()

      $settingsMenu = $('#gradebook_settings').next()
      $.each ['show_attendance', 'include_ungraded_assignments'], (i, setting) =>
        $settingsMenu.find("##{setting}").prop('checked', @[setting]).change (event) =>
          @[setting] = $(event.target).is(':checked')
          userSettings.contextSet setting, @[setting]
          @gradeGrid.setColumns @getVisibleGradeGridColumns() if setting is 'show_attendance'
          @buildRows()

      # don't show the "show attendance" link in the dropdown if there's no attendance assignments
      unless (_.detect @gradeGrid.getColumns(), (col) -> col.object?.submission_types == "attendance")
        $settingsMenu.find('#show_attendance').hide()

      @$columnArrangementTogglers = $('#gradebook-toolbar [data-arrange-columns-by]').bind 'click', (event) =>
        event.preventDefault()
        thingToArrangeBy = $(event.currentTarget).data('arrangeColumnsBy')
        @arrangeColumnsBy(thingToArrangeBy)
      @arrangeColumnsBy('assignment_group')

      $('#gradebook_settings').show().kyleMenu
        buttonOpts:
          icons:
            primary: "ui-icon-cog", secondary: "ui-icon-droparrow"
          text: false

      $upload_modal = null
      $settingsMenu.find('.gradebook_upload_link').click (event) =>
        event.preventDefault()
        unless $upload_modal
          locals =
            download_gradebook_csv_url: "#{@options.context_url}/gradebook.csv"
            action: "#{@options.context_url}/gradebook_uploads"
            authenticityToken: $("#ajax_authenticity_token").text()
          $upload_modal = $(gradebook_uploads_form(locals))
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

    getVisibleGradeGridColumns: ->
      res = []
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

      # I would like to make this width a little larger, but there's a dependency somewhere else that
      # I can't find and if I change it, the layout gets messed up.
      @parentColumns = [{
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
          width: testWidth(assignment.name, minWidth, columnWidths.assignment.max),
          sortable: true
          toolTip: assignment.name
          type: 'assignment'

        if fieldName in @assignmentsToHide
          columnDef.width = 10
          do (fieldName) =>
            $(document)
              .bind('gridready', => @minimizeColumn(@$grid.find("[id*='#{fieldName}']")))
              .unbind('gridready.render')
              .bind('gridready.render', => @gradeGrid.invalidate() )
        columnDef

      @aggregateColumns = for id, group of @assignmentGroups
        html = "#{group.name}"
        if group.group_weight?
          percentage =  I18n.toPercentage(group.group_weight, precision: 0)
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
          width: testWidth(group.name, columnWidths.assignmentGroup.min, columnWidths.assignmentGroup.max)
          cssClass: "meta-cell assignment-group-cell",
          sortable: true
          type: 'assignment_group'
        }

      @aggregateColumns.push
        id: "total_grade"
        field: "total_grade"
        formatter: @groupTotalFormatter
        name: "Total"
        minWidth: columnWidths.total.min
        maxWidth: columnWidths.total.max
        width: testWidth("Total", columnWidths.total.min, columnWidths.total.max)
        cssClass: "total-cell"
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
        headerHeight: 38
      }, @options)

      grids = [{
        selector: '#gradebook_students_grid'
        columns:  @parentColumns
      }, {
        selector: '#gradebook_grid'
        columns:  @getVisibleGradeGridColumns()
        options:
          enableCellNavigation: true
          editable: true
          syncColumnCellResize: true
          enableColumnReorder: true
      }]

      @multiGrid = new MultiGrid(@rows, options, grids, 1)
      # this is the magic that actually updates group and final grades when you edit a cell
      @gradeGrid = @multiGrid.grids[1]
      @gradeGrid.onCellChange.subscribe (event, data) =>
        @calculateStudentGrade(data.item)
        @gradeGrid.invalidate()
      sortRowsBy = (sortFn) =>
        @rows.sort(sortFn)
        student.row = i for student, i in @rows
        @multiGrid.invalidate()
      @gradeGrid.onSort.subscribe (event, data) =>
        sortRowsBy (a, b) ->
          aScore = a[data.sortCol.field]?.score
          bScore = b[data.sortCol.field]?.score
          aScore = -99999999999 if not aScore and aScore != 0
          bScore = -99999999999 if not bScore and bScore != 0
          if data.sortAsc then bScore - aScore else aScore - bScore
      @multiGrid.grids[0].onSort.subscribe (event, data) =>
        propertyToSortBy = {display_name: 'sortable_name', secondary_identifier: 'secondary_identifier'}[data.sortCol.field]
        sortRowsBy (a, b) ->
          res = if a[propertyToSortBy] < b[propertyToSortBy] then -1
          else if a[propertyToSortBy] > b[propertyToSortBy] then 1
          else 0
          if data.sortAsc then res else 0 - res

      @multiGrid.parent_grid.onKeyDown.subscribe ->
        # TODO: start editing automatically when a number or letter is typed
        false
      @onGridInit()


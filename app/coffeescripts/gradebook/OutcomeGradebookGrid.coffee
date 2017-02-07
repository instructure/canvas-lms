define [
  'i18nObj'
  'i18n!gradebook'
  'jquery'
  'underscore'
  'compiled/views/gradebook/HeaderFilterView'
  'compiled/views/gradebook/OutcomeColumnView'
  'compiled/util/NumberCompare'
  'jst/gradebook/outcome_gradebook_cell'
  'jst/gradebook/outcome_gradebook_student_cell'
  'jsx/context_cards/StudentContextCardTrigger'
], (i18nObj, I18n, $, _, HeaderFilterView, OutcomeColumnView, numberCompare, cellTemplate, studentCellTemplate) ->

  ###
  xsslint safeString.method cellHtml
  ###

  Grid =
    filter: ['exceeds', 'mastery', 'near-mastery', 'remedial']

    averageFn: 'mean'

    dataSource: {}

    outcomes: []

    options:
      headerRowHeight        : 42
      rowHeight              : 38
      syncColumnCellResize   : true
      showHeaderRow          : true
      explicitInitialization : true
      fullWidthRows          : true
      numberOfColumnsToFreeze: 1

    Events:
      # Public: Draw header cell contents.
      #
      # grid - A SlickGrid instance.
      #
      # Returns nothing.
      headerRowCellRendered: (e, options) ->
        Grid.View.headerRowCell(options)

      # Public: Draw column label cell contents.
      #
      # grid - A SlickGrid instance.
      #
      # Returns nothing.
      headerCellRendered: (e, options) ->
        Grid.View.headerCell(options)

      init: (grid) ->
        headers = $('.outcome-gradebook-wrapper .slick-header')
        headerRows = $('.outcome-gradebook-wrapper .slick-headerrow')
        _.each(_.zip(headers, headerRows), ([header, headerRow]) ->
          $(headerRow).insertBefore($(header)))

      # Public: Generate a section change callback for the given grid.
      #
      # grid - A SlickGrid instance.
      #
      # Returns a function.
      sectionChangeFunction: (grid) ->
        (currentSection) ->
          rows = Grid.Util.toRows(Grid.dataSource.rollups, section: currentSection)
          grid.setData(rows, false)
          Grid.View.redrawHeader(grid)
          grid.invalidate()

      # Public: Sort and rerender the grid.
      #
      # e - jQuery event object.
      # grid - SlickGrid instance.
      # sortAsc - Boolean to determine if sort is ascending or descending.
      # sortCol - The column object to sort on.
      #
      # Returns nothing.
      sort: (e, {grid, sortAsc, sortCol}) ->
        sortFn = if sortCol.field == 'student' then '_sortStudents' else '_sortResults'
        rows = grid.getData().sort((a, b) -> Grid.Events[sortFn].call(null, a, b, sortAsc, sortCol.field))
        grid.setData(rows)
        grid.invalidate()

      # Internal: Sort the grid by student names.
      #
      # a - Object to sort.
      # b - Object to compare a against.
      # sortAsc - Boolean to determine if the sort is ascending or descending.
      #
      # Returns a number used to sort with.
      _sortStudents: (a, b, sortAsc) ->
        if ''.localeCompare
          nameA = a.student.sortable_name
          nameB = b.student.sortable_name
          n     = if sortAsc then 1 else -1
          nameA.localeCompare(nameB, i18nObj.locale or 'en', sensitivity: 'accent', ignorePunctuation: true, numeric: true) * n
        else
          nameA = a.student.sortable_name.toLowerCase()
          nameB = b.student.sortable_name.toLowerCase()
          f     = if sortAsc then 1 else -1
          if nameA < nameB
            -1 * f
          else if nameB < nameA
            1 * f
          else
            0

      # Internal: Sort the grid by outcome result.
      #
      # a - Object to sort.
      # b - Object to compare a against.
      # sortAsc - Boolean to determine if the sort is ascending or descending.
      # field - The name of the field to sort on (e.g. "outcome_6").
      #
      # Returns a number used to sort with.
      _sortResults: (a, b, sortAsc, field) ->
        scoreA = a[field]
        scoreB = b[field]
        val = numberCompare(scoreA, scoreB, descending: !sortAsc)
        if val == 0
          Grid.Events._sortStudents(a, b, sortAsc)
        else
          val

    Util:
      COLUMN_OPTIONS:
        width    : 121
        minWidth : 50
        sortable : true

      # Public: Translate an API response to columns and rows that can be used by SlickGrid.
      #
      # response - A response object from the outcome rollups API.
      #
      # Returns an array with [columns, rows].
      toGrid: (response, options = { column: {}, row: {} }) ->
        Grid.dataSource = response
        [Grid.Util.toColumns(response.linked.outcomes, options.column),
         Grid.Util.toRows(response.rollups, options.row)]

      # Public: Translate an array of outcomes to columns that can be used by SlickGrid.
      #
      # outcomes - An array of outcomes from the outcome rollups API.
      #
      # Returns an array of columns.
      toColumns: (outcomes, options = {}) ->
        options = _.extend({}, Grid.Util.COLUMN_OPTIONS, options)
        columns = _.map outcomes, (outcome) ->
          _.extend(id: "outcome_#{outcome.id}",
                   name: _.escape(outcome.title),
                   field: "outcome_#{outcome.id}",
                   cssClass: 'outcome-result-cell',
                   outcome: outcome, options)
        [Grid.Util._studentColumn()].concat(columns)

      # Internal: Create a student names column.
      #
      # Returns an object.
      _studentColumn: ->
        studentOptions = { width: 228 }

        _.extend({
          id: 'student',
          name: I18n.t('learning_outcome', 'Learning Outcome')
          field: 'student'
          cssClass: 'outcome-student-cell'
          headerCssClass: 'outcome-student-header-cell'
          formatter: Grid.View.studentCell
        }, _.extend(Grid.Util.COLUMN_OPTIONS, studentOptions))

      # Public: Translate an array of rollup data to rows that can be passed to SlickGrid.
      #
      # rollups - An array of rollup results from the outcome rollups API.
      #
      # Returns an array of rows.
      toRows: (rollups, options = {}) ->
        filtered_rollups = _.groupBy rollups, (rollup) -> rollup.links.user
        rows = _.reject(_.map(filtered_rollups, Grid.Util._toRowFn(options.section)), (v) -> v == null)
        rows.sort((a, b) -> Grid.Events._sortStudents(a, b, true))

      # Internal: Generate a toRow function that filters by the given section.
      #
      # Returns a function..
      _toRowFn: (section) ->
        (rollup) -> Grid.Util._toRow(rollup, section)

      # Internal: Translate an outcome result to a SlickGrid row.
      #
      # rollup - A rollup object from the API.
      # section - A section ID to filter by.
      #
      # Returns an object.
      _toRow: (rollup, section_filter) ->
        return null unless Grid.Util.sectionFilter(section_filter, rollup)
        user = rollup[0].links.user
        section_list = _.map(rollup, (rollup) -> rollup.links.section)
        return null if _.isEmpty(section_list)
        student = Grid.Util.lookupStudent(user)
        sections = Grid.Util.lookupSection(section_list)
        section_name = $.toSentence(_.pluck(sections, 'name').sort())
        courseID = ENV.context_asset_string.split('_')[1]
        row =
          student: _.extend(
            grades_html_url: "/courses/#{courseID}/grades/#{user}#tab-outcomes" # probably should get this from the enrollment api
            section_name: if _.keys(Grid.sections).length > 1 then section_name else null
            student)
        _.each rollup[0].scores, (score) ->
          row["outcome_#{score.links.outcome}"] = score.score
        row

      # Public: Filter the given row by its section.
      #
      # section - The ID of the current section selection.
      # row - A rollup row returned from the API.
      #
      # Returns a boolean.
      sectionFilter: (section, row)->
        return true unless section
        return true if _.find row,(r) -> r.links.section == section

      # Public: Parse and store a list of outcomes from the outcome rollups API.
      #
      # outcomes - An array of outcome objects.
      #
      # Returns nothing.
      saveOutcomes: (outcomes) ->
        [type, id] = ENV.context_asset_string.split('_')
        url = "/#{type}s/#{id}/outcomes"
        Grid.outcomes = _.reduce(outcomes, (result, outcome) ->
          outcome.url = url
          result["outcome_#{outcome.id}"] = outcome
          result
        , {})

      saveOutcomePaths: (outcomePaths) ->
        outcomePaths.forEach (path) ->
          pathString = _.pluck(path.parts, 'name').join(' > ')
          Grid.outcomes["outcome_#{path.id}"].path = pathString

      # Public: Look up an outcome in the current outcome list.
      #
      # name - The name of the outcome to look for.
      #
      # Returns an outcome or null.
      lookupOutcome: (name) ->
        Grid.outcomes[name]

      # Public: Parse and store a list of students from the outcome rollups API.
      #
      # students - An array of student objects.
      #
      # Returns nothing.
      saveStudents: (students) ->
        Grid.students = _.reduce(students, (result, student) ->
          result[student.id] = student
          result
        , {})

      # Public: Look up a student in the current student list.
      #
      # id - The id for the student to look for.
      #
      # Returns a student or null.
      lookupStudent: (id) ->
        Grid.students[id]

      # Public: Parse and store a list of section from the outcome rollups API (actually just from the gradebook's list for now)
      #
      # sections - An array of section objects.
      #
      # Returns nothing.
      saveSections: (sections) ->
        Grid.sections = _.reduce(sections, (result, section) ->
          result[section.id] = section
          result
        , {})

      # Public: Look up a section in the current section list.
      #
      # id - The id for the section to look for.
      #
      # Returns a section or null.
      lookupSection: (id_or_ids) ->
        _.pick(Grid.sections, id_or_ids)

    Math:
      mean: (values, round = false) ->
        total = _.reduce(values, ((a, b) -> a + b), 0)
        if round
          Math.round(total / values.length)
        else
          parseFloat((total / values.length).toString().slice(0, 4))

      median: (values) ->
        sortedValues = _.sortBy(values, _.identity)
        if values.length % 2 == 0
          i = values.length / 2
          Grid.Math.mean(sortedValues.slice(i - 1, i + 1))
        else
          sortedValues[Math.floor(values.length / 2)]

      mode: (values) ->
        counts = _.chain(values)
          .countBy(_.identity)
          .reduce((t, v, k) ->
            t.push([v, parseInt(k)])
            t
          , [])
          .sortBy(_.first)
          .reverse()
          .value()
        max = counts[0][0]
        mode = _.reject(counts, (n) -> n[0] < max)
        mode = Grid.Math.mean(_.map(mode, _.last), true)

      max: (values) -> Math.max(values...)

      min: (values) -> Math.min(values...)

      cnt: (values) -> values.length

    View:
      # Public: Render a SlickGrid cell.
      #
      # row - Current row index.
      # cell - Current cell index.
      # value - Current value of the cell.
      # columnDef - Object that defines the current column.
      # dataContext - Context for the cell.
      #
      # Returns cell HTML.
      cell: (row, cell, value, columnDef, dataContext) ->
        Grid.View.cellHtml(value, columnDef, true)

      # Internal: Determine HTML for a cell.
      #
      # value - The proposed value for the cell
      # columnDef - The object for the current column
      # applyFilter - Wheter filtering should be applied
      #
      # Returns cell HTML
      cellHtml: (value, columnDef, shouldFilter) ->
        outcome     = Grid.Util.lookupOutcome(columnDef.field)
        return unless outcome and _.isNumber(value)
        className   = Grid.View.masteryClassName(value, outcome)
        return '' if shouldFilter and !_.include(Grid.filter, className)
        cellTemplate(score: Math.round(value * 100.0) / 100.0, className: className, masteryScore: outcome.mastery_points)

      studentCell: (row, cell, value, columnDef, dataContext) ->
        studentCellTemplate(_.extend value, course_id: ENV.GRADEBOOK_OPTIONS.context_id)

      # Public: Create a string class name for the given score.
      #
      # score - The number score to evaluate.
      # outcome - The outcome to compare the score against.
      #
      # Returns a string ('mastery', 'near-mastery', or 'remedial').
      masteryClassName: (score, outcome) ->
        mastery     = outcome.mastery_points
        nearMastery = mastery / 2
        exceedsMastery = mastery + (mastery / 2)
        return 'exceeds' if score >= exceedsMastery
        return 'mastery' if score >= mastery
        return 'near-mastery' if score >= nearMastery
        'remedial'

      getColumnResults: (data, column) ->
        _.chain(data)
          .pluck(column.field)
          .filter(_.isNumber)
          .value()

      headerRowCell: ({node, column, grid}, fn = Grid.averageFn) ->
        return Grid.View.studentHeaderRowCell(node, column, grid) if column.field == 'student'

        results = Grid.View.getColumnResults(grid.getData(), column)
        return $(node).empty() unless results.length
        value = Grid.Math[fn].call(this, (results))
        $(node).empty().append(Grid.View.cellHtml(value, column, false))

      redrawHeader: (grid, fn = Grid.averageFn) ->
        Grid.averageFn = fn
        cols = grid.getColumns()
        _.each(cols, (col) ->
          header = grid.getHeaderRowColumn(col.id)
          Grid.View.headerRowCell(node: header, column: col, grid: grid, fn))

      studentHeaderRowCell: (node, column, grid) ->
        $(node).addClass('average-filter')
        view = new HeaderFilterView(grid: grid, redrawFn: Grid.View.redrawHeader)
        view.render()
        $(node).append(view.$el)

      headerCell: ({node, column, grid}, fn = Grid.averageFn) ->
        return if column.field == 'student'
        totalsFn = _.partial(Grid.View.calculateRatingsTotals, grid, column)
        view = new OutcomeColumnView(el: node, attributes: column.outcome, totalsFn: totalsFn)
        view.render()

      calculateRatingsTotals: (grid, column) ->
        results = Grid.View.getColumnResults(grid.getData(), column)
        ratings = column.outcome.ratings || []
        ratings.result_count = results.length
        points = _.pluck ratings, 'points'
        counts = _.countBy results, (result) ->
          _.find points, (x) -> x <= result
        _.each ratings, (rating) ->
          rating.percent = Math.round((counts[rating.points] || 0) / results.length * 100)

define [
  'i18n!gradebook2'
  'underscore'
  'compiled/views/gradebook/HeaderFilterView'
  'compiled/views/gradebook/OutcomeColumnView'
  'jst/gradebook2/outcome_gradebook_cell'
  'jst/gradebook2/outcome_gradebook_student_cell'
], (I18n, _, HeaderFilterView, OutcomeColumnView, cellTemplate, studentCellTemplate) ->

  Grid =
    filter: ['mastery', 'near-mastery', 'remedial']

    averageFn: 'mean'

    dataSource: {}

    outcomes: []

    options:
      headerRowHeight        : 42
      rowHeight              : 38
      syncColumnCellResize   : true
      showHeaderRow          : true
      explicitInitialization : true
      fullWidthRows:           true

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
        header       = $(grid.getHeaderRow()).parent()
        columnHeader = header.prev()

        header.insertBefore(columnHeader)

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

    Util:
      COLUMN_OPTIONS:
        width: 121

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
                   name: outcome.title,
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
        _.reject(_.map(rollups, Grid.Util._toRowFn(options.section)), (v) -> v == null)

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
      _toRow: (rollup, section) ->
        return null unless Grid.Util.sectionFilter(section, rollup)
        row = { student: Grid.Util.lookupStudent(rollup.links.user), section: rollup.links.section }
        _.each rollup.scores, (score) ->
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
        _.isEqual(section.toString(), row.links.section.toString())

      # Public: Parse and store a list of outcomes from the outcome rollups API.
      #
      # outcomes - An array of outcome objects.
      #
      # Returns nothing.
      saveOutcomes: (outcomes) ->
        [type, id] = ENV.context_asset_string.split('_')
        url = "/#{type}s/#{id}/outcomes/"
        Grid.outcomes = _.reduce(outcomes, (result, outcome) ->
          outcome.url = url
          result["outcome_#{outcome.id}"] = outcome
          result
        , {})

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
      # name - The id for the student to look for.
      #
      # Returns an student or null.
      lookupStudent: (id) ->
        Grid.students[id]

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
        outcome     = Grid.Util.lookupOutcome(columnDef.field)
        return unless outcome and !(_.isNull(value) or _.isUndefined(value))
        className   = Grid.View.masteryClassName(value, outcome)
        return '' unless _.include(Grid.filter, className)
        cellTemplate(score: value, className: className, masteryScore: outcome.mastery_points)

      studentCell: (row, cell, value, columnDef, dataContext) ->
        studentCellTemplate(value)

      # Public: Create a string class name for the given score.
      #
      # score - The number score to evaluate.
      # outcome - The outcome to compare the score against.
      #
      # Returns a string ('mastery', 'near-mastery', or 'remedial').
      masteryClassName: (score, outcome) ->
        mastery     = outcome.mastery_points
        nearMastery = mastery / 2
        return 'mastery' if score >= mastery
        return 'near-mastery' if score >= nearMastery
        'remedial'

      headerRowCell: ({node, column, grid}, fn = Grid.averageFn) ->
        return Grid.View.studentHeaderRowCell(node, column, grid) if column.field == 'student'

        results = _.chain(grid.getData())
          .pluck(column.field)
          .reject((value) -> _.isNull(value) or _.isUndefined(value))
          .value()
        return $(node).empty() unless results.length
        value = Grid.Math[fn].call(this, (results))
        $(node).empty().append(Grid.View.cell(null, null, value, column, null))

      redrawHeader: (grid, fn = Grid.averageFn) ->
        header = grid.getHeaderRow().childNodes
        cols   = grid.getColumns()
        Grid.averageFn = fn
        _.each(header, (node, i) -> Grid.View.headerRowCell(node: node, column: cols[i], grid: grid, fn))

      studentHeaderRowCell: (node, column, grid) ->
        $(node).addClass('average-filter')
        view = new HeaderFilterView(grid: grid, redrawFn: Grid.View.redrawHeader)
        view.render()
        $(node).append(view.$el)

      headerCell: ({node, column, grid}, fn = Grid.averageFn) ->
        return if column.field == 'student'
        # TODO: calculate outcome statistics when opening the popup
        view = new OutcomeColumnView(el: node, attributes: column.outcome)
        view.render()

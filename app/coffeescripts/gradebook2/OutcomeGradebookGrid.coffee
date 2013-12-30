define [
  'i18n!gradebook2'
  'underscore'
  'jst/gradebook2/outcome_gradebook_cell'
  'jst/gradebook2/outcome_gradebook_student_cell'
], (I18n, _, cellTemplate, studentCellTemplate) ->

  Grid =
    filter: ['mastery', 'near-mastery', 'remedial']

    outcomes: []

    options:
      headerRowHeight        : 42
      rowHeight              : 40
      syncColumnCellResize   : true
      showHeaderRow          : true
      explicitInitialization : true

    Events:
      # Public: Draw header cell contents.
      #
      # grid - A SlickGrid instance.
      #
      # Returns nothing.
      headerRowCellRendered: (e, {node, column, grid}) ->
        if column.field == 'student'
          $(node).empty().addClass('hidden')
        else
          results = _.chain(grid.getData())
            .pluck(column.field)
            .reject((value) -> !value)
            .value()
          total   = _.reduce(results, ((a, b) -> a + b), 0)
          average = Math.round(total / results.length)
          $(node).empty().append(Grid.View.cell(null, null, average, column, null))

      init: (grid) ->
        header       = $(grid.getHeaderRow()).parent()
        columnHeader = header.prev()

        header.insertBefore(columnHeader)

    Util:
      COLUMN_OPTIONS:
        width: 175

      # Public: Translate an API response to columns and rows that can be used by SlickGrid.
      #
      # response - A response object from the outcome rollups API.
      #
      # Returns an array with [columns, rows].
      toGrid: (response, options = { column: {}, row: {} }) ->
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
                   cssClass: 'outcome-result-cell', options)
        [Grid.Util._studentColumn()].concat(columns)

      # Internal: Create a student names column.
      #
      # Returns an object.
      _studentColumn: ->
        _.extend({
          id: 'student',
          name: I18n.t('learning_outcome', 'Learning Outcome')
          field: 'student'
          cssClass: 'outcome-student-cell'
          headerCssClass: 'outcome-student-header-cell'
          formatter: Grid.View.studentCell
        }, Grid.Util.COLUMN_OPTIONS)

      # Public: Translate an array of rollup data to rows that can be passed to SlickGrid.
      # TODO: once section results are returned, allow filtering by them here.
      #
      # rollups - An array of rollup results from the outcome rollups API.
      #
      # Returns an array of rows.
      toRows: (rollups, options = {}) ->
        _.map(rollups, Grid.Util._toRow)

      # Internal: Translate a given rollup from the API to a SlickGrid row.
      #
      # rollup - A rollup object from the outcome results API.
      #
      # Returns a SlickGrid row object.
      _toRow: (rollup) ->
        row = { student: rollup.name, section: rollup.links.section }
        _.each rollup.scores, (score) ->
          row["outcome_#{score.links.outcome}"] = score.score
        row

      # Public: Parse and store a list of outcomes from the outcome rollups API.
      #
      # outcomes - An array of outcome objects.
      #
      # Returns nothing.
      saveOutcomes: (outcomes) ->
        Grid.outcomes = _.reduce(outcomes, (result, outcome) ->
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
        cellTemplate(score: value, className: className)

      studentCell: (row, cell, value, columnDef, dataContext) ->
        studentCellTemplate(name: value)

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

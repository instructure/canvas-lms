/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {
  uniq,
  reduce,
  groupBy,
  includes,
  isObject,
  reject,
  chain,
  some,
  isNumber,
  pick,
  isNull,
  isEmpty,
  find,
  partial,
  keys,
  map,
  each,
  zip,
  extend as lodashExtend,
  escape as lodashEscape,
} from 'lodash'
import HeaderFilterView from './react/HeaderFilterView'
import OutcomeFilterView from './react/OutcomeFilterView'
import OutcomeColumnView from './backbone/views/OutcomeColumnView'
import listFormatterPolyfill from '@canvas/util/listFormatter'
import cellTemplate from './jst/outcome_gradebook_cell.handlebars'
import studentCellTemplate from './jst/outcome_gradebook_student_cell.handlebars'

import React from 'react'
import ReactDOM from 'react-dom'

const I18n = useI18nScope('gradebookOutcomeGradebookGrid')

const listFormatter = Intl.ListFormat
  ? new Intl.ListFormat(ENV.LOCALE || navigator.language)
  : listFormatterPolyfill

/*
xsslint safeString.method cellHtml
*/

const Grid = {
  filter: [],
  ratings: [],
  averageFn: 'mean',
  section: undefined,
  dataSource: {},
  outcomes: [],
  gridRef: null,
  options: {
    headerRowHeight: 42,
    rowHeight: 42,
    syncColumnCellResize: true,
    showHeaderRow: true,
    explicitInitialization: true,
    fullWidthRows: true,
    numberOfColumnsToFreeze: 1,
  },
  Events: {
    // Public: Draw header cell contents.

    // grid - A SlickGrid instance.

    // Returns nothing.
    headerRowCellRendered(e, options) {
      return Grid.View.headerRowCell(options)
    },
    // Public: Draw column label cell contents.

    // grid - A SlickGrid instance.

    // Returns nothing.
    headerCellRendered(e, options) {
      return Grid.View.headerCell(options)
    },
    init() {
      const headers = $('.outcome-gradebook-wrapper .slick-header')
      const headerRows = $('.outcome-gradebook-wrapper .slick-headerrow')
      each(zip(headers, headerRows), function ([header, headerRow]) {
        return $(headerRow).insertBefore($(header))
      })
    },
  },
  Util: {
    COLUMN_OPTIONS: {
      width: 121,
      minWidth: 50,
      sortable: true,
    },
    // Public: Translate an API response to columns and rows that can be used by SlickGrid.

    // response - A response object from the outcome rollups API.

    // Returns an array with [columns, rows].
    toGrid(
      response,
      options = {
        column: {},
      }
    ) {
      Grid.dataSource = response
      return [
        Grid.Util.toColumns(response.linked.outcomes, response.rollups, options.column),
        Grid.Util.toRows(response.rollups),
      ]
    },
    // Public: Translate an array of outcomes to columns that can be used by SlickGrid.

    // outcomes - An array of outcomes from the outcome rollups API.
    // rollups  - An array of rollups from the outcome rollups API.

    // Returns an array of columns.
    toColumns(outcomes, rollups, options = {}) {
      options = lodashExtend({}, Grid.Util.COLUMN_OPTIONS, options)
      const columns = map(outcomes, function (outcome) {
        return lodashExtend(
          {
            id: `outcome_${outcome.id}`,
          },
          {
            name: lodashEscape(outcome.title),
            field: `outcome_${outcome.id}`,
            cssClass: 'outcome-result-cell',
            hasResults: some(rollups, r => {
              return find(r.scores, s => {
                return s.links.outcome === outcome.id
              })
            }),
            outcome,
          },
          options
        )
      })
      return [Grid.Util._studentColumn()].concat(columns)
    },
    // Internal: Create a student names column.

    // Returns an object.
    _studentColumn() {
      // var studentOptions
      const studentOptions = {
        width: 231,
      }
      return lodashExtend(
        {
          id: 'student',
          name: I18n.t('learning_outcome', 'Learning Outcome'),
          field: 'student',
          cssClass: 'outcome-student-cell',
          headerCssClass: 'outcome-student-header-cell',
          formatter: Grid.View.studentCell,
        },
        lodashExtend({}, Grid.Util.COLUMN_OPTIONS, studentOptions)
      )
    },
    // Public: Translate an array of rollup data to rows that can be passed to SlickGrid.

    // rollups - An array of rollup results from the outcome rollups API.

    // Returns an array of rows.
    toRows(rollups, _options = {}) {
      const user_ids = uniq(
        map(rollups, function (r) {
          return r.links.user
        })
      )
      const filtered_rollups = groupBy(rollups, function (rollup) {
        return rollup.links.user
      })
      const ordered_rollups = map(user_ids, function (u) {
        return filtered_rollups[u]
      })
      return reject(
        map(ordered_rollups, function (rollup) {
          return Grid.Util._toRow(rollup)
        }),
        isNull
      )
    },
    // Internal: Translate an outcome result to a SlickGrid row.

    // rollup - A rollup object from the API.

    // Returns an object.
    _toRow(rollup) {
      const user = rollup[0].links.user
      const section_list = map(rollup, function (rollup2) {
        return rollup2.links.section
      })
      const section_enrollment_status = () => {
        const enrollment_status = rollup.map(r => r.links.status)
        return enrollment_status.every(e => e === 'completed')
          ? I18n.t('concluded')
          : enrollment_status.every(e => e === 'inactive')
          ? I18n.t('inactive')
          : ''
      }
      if (isEmpty(section_list)) {
        return null
      }
      const student = Grid.Util.lookupStudent(user)
      const sections = Grid.Util.lookupSection(section_list)
      const section_name = listFormatter.format(
        map(sections, 'name')
          .filter(x => x)
          .sort()
      )
      const courseID = ENV.context_asset_string.split('_')[1]
      const row = {
        student: lodashExtend(
          {
            grades_html_url: `/courses/${courseID}/grades/${user}#tab-outcomes`,
            section_name: keys(Grid.sections).length > 1 ? section_name : null,
            enrollment_status: section_enrollment_status(),
          },
          student
        ),
      }
      each(rollup[0].scores, function (score) {
        return (row[`outcome_${score.links.outcome}`] = pick(score, 'score', 'hide_points'))
      })
      return row
    },
    // Public: Parse and store a list of outcomes from the outcome rollups API.

    // outcomes - An array of outcome objects.

    // Returns nothing.
    saveOutcomes(outcomes) {
      const [type, id] = ENV.context_asset_string.split('_')
      const url = `/${type}s/${id}/outcomes`
      return (Grid.outcomes = reduce(
        outcomes,
        function (result, outcome) {
          outcome.url = url
          result[`outcome_${outcome.id}`] = outcome
          return result
        },
        {}
      ))
    },
    saveOutcomePaths(outcomePaths) {
      return outcomePaths.forEach(function (path) {
        const pathString = map(path.parts, 'name').join(' > ')
        return (Grid.outcomes[`outcome_${path.id}`].path = pathString)
      })
    },
    // Public: Look up an outcome in the current outcome list.

    // name - The name of the outcome to look for.

    // Returns an outcome or null.
    lookupOutcome(name) {
      return Grid.outcomes[name]
    },
    // Public: Parse and store a list of students from the outcome rollups API.

    // students - An array of student objects.

    // Returns nothing.
    saveStudents(students) {
      return (Grid.students = reduce(
        students,
        function (result, student) {
          result[student.id] = student
          return result
        },
        {}
      ))
    },
    // Public: Look up a student in the current student list.

    // id - The id for the student to look for.

    // Returns a student or null.
    lookupStudent(id) {
      return Grid.students[id]
    },
    // Public: Parse and store a list of section from the outcome rollups API (actually just from the gradebook's list for now)

    // sections - An array of section objects.

    // Returns nothing.
    saveSections(sections) {
      return (Grid.sections = reduce(
        sections,
        function (result, section) {
          result[section.id] = section
          return result
        },
        {}
      ))
    },
    // Public: Look up a section in the current section list.

    // id - The id for the section to look for.

    // Returns a section or null.
    lookupSection(id_or_ids) {
      return pick(Grid.sections, id_or_ids)
    },
  },
  Math: {
    mean(values, round = false) {
      const total = reduce(
        values,
        function (a, b) {
          return a + b
        },
        0
      )
      if (round) {
        return Math.round(total / values.length)
      } else {
        return parseFloat((total / values.length).toString().slice(0, 4))
      }
    },
    max(values) {
      return Math.max(...values)
    },
    min(values) {
      return Math.min(...values)
    },
    cnt(values) {
      return values.length
    },
  },
  View: {
    // Public: Render a SlickGrid cell.

    // row - Current row index.
    // cell - Current cell index.
    // value - Object with current score and hide_points status of the cell
    // columnDef - Object that defines the current column.
    // dataContext - Context for the cell.

    // Returns cell HTML.
    cell(_row, _cell, value, columnDef, _dataContext) {
      const score = value?.score
      const hide_points = value?.hide_points
      return Grid.View.cellHtml(score, hide_points, columnDef, true)
    },
    // Internal: Determine HTML for a cell.

    // score - The proposed value for the cell
    // hide_points - Whether or not to show raw points or tier description
    // columnDef - The object for the current column
    // applyFilter - Whether filtering should be applied

    // Returns cell HTML
    cellHtml(score, hide_points, columnDef, shouldFilter) {
      const outcome = Grid.Util.lookupOutcome(columnDef.field)
      if (!(outcome && isNumber(score))) {
        return
      }
      const [className, color, description] = Grid.View.masteryDetails(score, outcome)
      if (shouldFilter && !includes(Grid.filter, className)) {
        return ''
      }
      const cssColor = color ? `background-color:${color};` : ''
      if (hide_points) {
        return cellTemplate({
          color: cssColor,
          className,
          description,
        })
      } else {
        return cellTemplate({
          color: cssColor,
          score: Math.round(score * 100.0) / 100.0,
          className,
          masteryScore: outcome.mastery_points,
        })
      }
    },
    // This only renders student rows, not column headers
    studentCell(_row, _cell, value, _columnDef, _dataContext) {
      return studentCellTemplate(
        lodashExtend(value, {
          course_id: ENV.GRADEBOOK_OPTIONS.context_id,
        })
      )
    },
    masteryDetails(score, outcome) {
      let idx, scaled, total_points
      if (Grid.ratings.length > 0) {
        total_points = outcome.points_possible
        if (total_points === 0) {
          total_points = outcome.mastery_points
        }
        scaled = total_points === 0 ? score : (score / total_points) * Grid.ratings[0].points
        idx = Grid.ratings.findIndex(function (r) {
          return scaled >= r.points
        })
        idx = idx === -1 ? Grid.ratings.length - 1 : idx
        return [`rating_${idx}`, `\#${Grid.ratings[idx].color}`, Grid.ratings[idx].description]
      } else {
        return Grid.View.legacyMasteryDetails(score, outcome)
      }
    },
    // Public: Create a string class name and color for the given score.

    // score - The number score to evaluate.
    // outcome - The outcome to compare the score against.

    // Returns an array with a className and CSS color.
    legacyMasteryDetails(score, outcome) {
      const mastery = outcome.mastery_points
      const nearMastery = mastery / 2
      const exceedsMastery = mastery + mastery / 2
      if (score >= exceedsMastery) {
        return ['rating_0', '#127A1B', I18n.t('Exceeds Mastery')]
      }
      if (score >= mastery) {
        return ['rating_1', ENV.use_high_contrast ? '#127A1B' : '#0B874B', I18n.t('Meets Mastery')]
      }
      if (score >= nearMastery) {
        return ['rating_2', ENV.use_high_contrast ? '#C23C0D' : '#FC5E13', I18n.t('Near Mastery')]
      }
      return ['rating_3', '#E0061F', I18n.t('Well Below Mastery')]
    },
    getColumnResults(data, column) {
      return chain(data).map(column.field).filter(isObject).value()
    },
    headerRowCell({node, column, grid}, score) {
      if (column.field === 'student') {
        return Grid.View.studentHeaderRowCell(node, column, grid)
      }
      return $(node)
        .empty()
        .append(Grid.View.cellHtml(score?.score, score?.hide_points, column, false))
    },
    _aggregateUrl(stat) {
      const course = ENV.context_asset_string.split('_')[1]
      const sectionParam = Grid.section && Grid.section !== '0' ? `&section_id=${Grid.section}` : ''
      const filters = Grid.gridRef._getOutcomeFiltersParams()
        ? `${Grid.gridRef._getOutcomeFiltersParams()}`
        : ''
      return `/api/v1/courses/${course}/outcome_rollups?aggregate=course&aggregate_stat=${stat}${sectionParam}${filters}`
    },
    redrawHeader(grid, fn = Grid.averageFn) {
      Grid.averageFn = fn
      const cols = grid.getColumns()
      const dfd = $.getJSON(Grid.View._aggregateUrl(fn)).fail(function (_e) {
        return $.flashError(I18n.t('There was an error fetching course statistics'))
      })
      return dfd.then((response, _status, _xhr) => {
        // do for each column
        each(cols, function (col) {
          const header = grid.getHeaderRowColumn(col.id)
          const score = col.outcome
            ? find(response.rollups[0].scores, function (s) {
                return s.links.outcome === col.outcome.id
              })
            : undefined
          return Grid.View.headerRowCell(
            {
              node: header,
              column: col,
              grid,
            },
            score
          )
        })
      })
    },
    addEnrollmentFilters(node) {
      const existingExclusions = Grid.gridRef._getOutcomeFilters()
      const menu = React.createElement(
        OutcomeFilterView,
        {
          showInactiveEnrollments: !existingExclusions.includes('inactive_enrollments'),
          showConcludedEnrollments: !existingExclusions.includes('concluded_enrollments'),
          showUnassessedStudents: !existingExclusions.includes('missing_user_rollups'),
          toggleInactiveEnrollments: Grid.gridRef._toggleStudentsWithInactiveEnrollments,
          toggleConcludedEnrollments: Grid.gridRef._toggleStudentsWithConcludedEnrollments,
          toggleUnassessedStudents: Grid.gridRef._toggleStudentsWithNoResults,
        },
        null
      )
      ReactDOM.render(menu, node)
    },
    studentHeaderRowCell(node, _column, grid) {
      const menu = React.createElement(
        HeaderFilterView,
        {
          grid,
          averageFn: Grid.averageFn,
          redrawFn: Grid.View.redrawHeader
        },
        null
      )
      ReactDOM.render(menu, node)
    },
    headerCell({node, column, grid}, _fn = Grid.averageFn) {
      if (column.field === 'student') {
        $(node).empty()
        this.addEnrollmentFilters(node)
        return
      }
      const totalsFn = partial(Grid.View.calculateRatingsTotals, grid, column)
      const view = new OutcomeColumnView({
        el: node,
        attributes: column.outcome,
        totalsFn,
      })
      return view.render()
    },
    calculateRatingsTotals(grid, column) {
      const results = Grid.View.getColumnResults(grid.getData(), column)
      const ratings = column.outcome.ratings || []
      return (ratings.result_count = results.length)
    },
  },
}

export default Grid

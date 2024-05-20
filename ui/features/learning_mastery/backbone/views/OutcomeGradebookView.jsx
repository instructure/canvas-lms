/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import React from 'react'
import {filter, uniq, reject, range, extend as lodashExtend} from 'lodash'
import ReactDOM from 'react-dom'
import {View} from '@canvas/backbone'
import Slick from 'slickgrid'
import Grid from '@canvas/outcome-gradebook-grid'
import userSettings from '@canvas/user-settings'
import CheckboxView from './CheckboxView'
import SectionFilter from '@canvas/gradebook-content-filters/react/SectionFilter'
import template from '../../jst/outcome_gradebook.handlebars'
import 'jquery-tinypubsub'
import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import '@canvas/jquery/jquery.disableWhileLoading'

const I18n = useI18nScope('gradebookOutcomeGradebookView')

const Dictionary = {
  exceedsMastery: {
    color: '#127A1B',
    label: I18n.t('Exceeds Mastery'),
  },
  mastery: {
    color: ENV.use_high_contrast ? '#127A1B' : '#0B874B',
    label: I18n.t('Meets Mastery'),
  },
  nearMastery: {
    color: ENV.use_high_contrast ? '#C23C0D' : '#FC5E13',
    label: I18n.t('Near Mastery'),
  },
  remedial: {
    color: '#E0061F',
    label: I18n.t('Well Below Mastery'),
  },
}

extend(OutcomeGradebookView, View)

OutcomeGradebookView.prototype.tagName = 'div'

OutcomeGradebookView.prototype.className = 'outcome-gradebook'

OutcomeGradebookView.prototype.template = template

OutcomeGradebookView.optionProperty('learningMastery')

OutcomeGradebookView.prototype.hasOutcomes = $.Deferred()

// child views rendered using the {{view}} helper in the template
OutcomeGradebookView.prototype.checkboxes = [
  new CheckboxView(Dictionary.exceedsMastery),
  new CheckboxView(Dictionary.mastery),
  new CheckboxView(Dictionary.nearMastery),
  new CheckboxView(Dictionary.remedial),
]

OutcomeGradebookView.prototype.ratings = []

OutcomeGradebookView.prototype.events = {
  'click .sidebar-toggle': 'onSidebarToggle',
}

OutcomeGradebookView.prototype.sortField = 'student'

OutcomeGradebookView.prototype.sortOrderAsc = true

function OutcomeGradebookView(options) {
  this.updateExportLink = this.updateExportLink.bind(this)
  this._loadOutcomes = this._loadOutcomes.bind(this)
  this.updateCurrentSection = this.updateCurrentSection.bind(this)
  this.renderSectionMenu = this.renderSectionMenu.bind(this)
  this.renderGrid = this.renderGrid.bind(this)
  this.focusFilterKebabIfNeeded = this.focusFilterKebabIfNeeded.bind(this)
  this._toggleSort = this._toggleSort.bind(this)
  this._toggleStudentsWithConcludedEnrollments =
    this._toggleStudentsWithConcludedEnrollments.bind(this)
  this._toggleStudentsWithInactiveEnrollments =
    this._toggleStudentsWithInactiveEnrollments.bind(this)
  this._toggleStudentsWithNoResults = this._toggleStudentsWithNoResults.bind(this)
  this.setOutcomeOrder = this.setOutcomeOrder.bind(this)
  let ref
  OutcomeGradebookView.__super__.constructor.apply(this, arguments)
  this._validateOptions(options)
  if ((ref = ENV.GRADEBOOK_OPTIONS.outcome_proficiency) != null ? ref.ratings : void 0) {
    this.ratings = ENV.GRADEBOOK_OPTIONS.outcome_proficiency.ratings
    this.checkboxes = this.ratings.map(function (rating) {
      return new CheckboxView({
        color: '#' + rating.color,
        label: rating.description,
      })
    })
  }
  Grid.gridRef = this
}

OutcomeGradebookView.prototype.remove = function () {
  OutcomeGradebookView.__super__.remove.call(this)
  return ReactDOM.unmountComponentAtNode(document.querySelector('[data-component="SectionFilter"]'))
}

// Public: Show/hide the sidebar.
//
// e - Event object.
//
// Returns nothing.
OutcomeGradebookView.prototype.onSidebarToggle = function (e) {
  e.preventDefault()
  const isCollapsed = this._toggleSidebarCollapse()
  this._toggleSidebarArrow()
  return this._toggleSidebarTooltips(isCollapsed)
}

// Internal: Toggle collapsed class on sidebar.
//
// Returns true if collapsed, false if expanded.
OutcomeGradebookView.prototype._toggleSidebarCollapse = function () {
  return this.$('.outcome-gradebook-sidebar').toggleClass('collapsed').hasClass('collapsed')
}

// Internal: Toggle the direction of the sidebar collapse arrow.
//
// Returns nothing.
OutcomeGradebookView.prototype._toggleSidebarArrow = function () {
  return this.$('.sidebar-toggle')
    .toggleClass('icon-arrow-open-right')
    .toggleClass('icon-arrow-open-left')
}

// Internal: Toggle the direction of the sidebar collapse arrow.
//
// Returns nothing
OutcomeGradebookView.prototype._toggleSidebarTooltips = function (shouldShow) {
  if (shouldShow) {
    this.$('.checkbox-view').each(function () {
      return $(this)
        .find('.checkbox')
        .attr('data-tooltip', 'left')
        .attr('title', $(this).find('.checkbox-label').text())
    })
    return this.$('.filters').hide()
  } else {
    this.$('.checkbox').removeAttr('data-tooltip').removeAttr('title')
    return this.$('.filters').show()
  }
}

// Internal: Validate options passed to constructor.
//
// options - The options hash passed to the constructor function.
//
// Returns nothing on success, raises on failure.
OutcomeGradebookView.prototype._validateOptions = function (arg) {
  const learningMastery = arg.learningMastery
  if (!learningMastery) {
    throw new Error('Missing required option: "learningMastery"')
  }
}

// Internal: Listen for events on child views.
//
// Returns nothing.
OutcomeGradebookView.prototype._attachEvents = function () {
  const _this = this
  const ref = this.checkboxes
  let j
  for (let i = (j = 0), len = ref.length; j < len; i = ++j) {
    const view = ref[i]
    view.on('togglestate', this._createFilter('rating_' + i))
  }
  this.updateExportLink(this.learningMastery.getCurrentSectionId())
  return this.$('#no_results_outcomes').change(function () {
    return _this._toggleOutcomesWithNoResults(this.checked)
  })
}

OutcomeGradebookView.prototype._setFilterSetting = function (name, value) {
  let filters = userSettings.contextGet('lmgb_filters')
  if (!filters) {
    filters = {}
  }
  filters[name] = value
  return userSettings.contextSet('lmgb_filters', filters)
}

OutcomeGradebookView.prototype._getFilterSetting = function (name) {
  const filters = userSettings.contextGet('lmgb_filters')
  return filters && filters[name]
}

OutcomeGradebookView.prototype._toggleOutcomesWithNoResults = function (enabled) {
  this._setFilterSetting('outcomes_no_results', enabled)
  if (enabled) {
    const columns = [this.columns[0]].concat(
      filter(
        this.columns,
        (function (_this) {
          return function (c) {
            return c.hasResults
          }
        })(this)
      )
    )
    this.grid.setColumns(columns)
  } else {
    this.grid.setColumns(this.columns)
  }
  return Grid.View.redrawHeader(this.grid, Grid.averageFn)
}

OutcomeGradebookView.prototype._toggleStudentsWithNoResults = function (enabled) {
  this._setFilterSetting('students_no_results', enabled)
  this.updateExportLink(this.learningMastery.getCurrentSectionId())
  this.focusFilterKebab = true
  return this._rerender()
}

OutcomeGradebookView.prototype._toggleStudentsWithInactiveEnrollments = function (enabled) {
  this._setFilterSetting('inactive_enrollments', enabled)
  this.updateExportLink(this.learningMastery.getCurrentSectionId())
  this.focusFilterKebab = true
  return this._rerender()
}

OutcomeGradebookView.prototype._toggleStudentsWithConcludedEnrollments = function (enabled) {
  this._setFilterSetting('concluded_enrollments', enabled)
  this.updateExportLink(this.learningMastery.getCurrentSectionId())
  this.focusFilterKebab = true
  return this._rerender()
}

OutcomeGradebookView.prototype._rerender = function () {
  this.grid.setData([])
  this.grid.invalidate()
  this.hasOutcomes = $.Deferred()
  // eslint-disable-next-line promise/catch-or-return
  $.when(this.hasOutcomes).then(this.renderGrid)
  return this._loadOutcomes()
}

OutcomeGradebookView.prototype._toggleSort = function (e, arg) {
  const sortCol = arg.sortCol
  const target = $(e.target).attr('data-component')
  // Don't sort if user clicks the enrollments filter kabob
  if (target === 'lmgb-student-filter-trigger') {
    return
  } else if (sortCol.field === this.sortField) {
    // Change sort direction
    this.sortOrderAsc = !this.sortOrderAsc
  } else {
    // Change in sort column
    this.sortField = sortCol.field
    this.sortOrderAsc = true
  }
  return this._rerender()
}

// Internal: Listen for events on grid.
//
// Returns nothing.
OutcomeGradebookView.prototype._attachGridEvents = function () {
  this.grid.onHeaderRowCellRendered.subscribe(Grid.Events.headerRowCellRendered)
  this.grid.onHeaderCellRendered.subscribe(Grid.Events.headerCellRendered)
  this.grid.onColumnsReordered.subscribe(this.setOutcomeOrder)
  return this.grid.onSort.subscribe(this._toggleSort)
}

// Public: Create object to be passed to the view.
//
// Returns an object.
OutcomeGradebookView.prototype.toJSON = function () {
  return lodashExtend(
    {},
    {
      checkboxes: this.checkboxes,
    }
  )
}

OutcomeGradebookView.prototype._loadFilterSettings = function () {
  return this.$('#no_results_outcomes').prop(
    'checked',
    this._getFilterSetting('outcomes_no_results')
  )
}

// Public: Render the view once all needed data is loaded.
//
// Returns this.
OutcomeGradebookView.prototype.render = function () {
  OutcomeGradebookView.__super__.render.call(this)
  this.renderSectionMenu()
  // eslint-disable-next-line promise/catch-or-return
  $.when(this.hasOutcomes).then(this.renderGrid)
  return this
}

OutcomeGradebookView.prototype.focusFilterKebabIfNeeded = function () {
  let ref
  if (this.focusFilterKebab) {
    if (
      (ref = document.querySelector('button[data-component=lmgb-student-filter-trigger]')) != null
    ) {
      ref.focus()
    }
  }
  return (this.focusFilterKebab = false)
}

// Internal: Render SlickGrid component.
//
// response - Outcomes rollup data from API.
//
// Returns nothing.
OutcomeGradebookView.prototype.renderGrid = function (response) {
  Grid.filter = filter(
    range(this.checkboxes.length),
    (function (_this) {
      return function (i) {
        return _this.checkboxes[i].checked
      }
    })(this)
  ).map(function (i) {
    return 'rating_' + i
  })
  Grid.ratings = this.ratings
  Grid.Util.saveOutcomes(response.linked.outcomes)
  Grid.Util.saveStudents(response.linked.users)
  Grid.Util.saveOutcomePaths(response.linked.outcome_paths)
  Grid.Util.saveSections(this.learningMastery.getSections())
  const ref = Grid.Util.toGrid(response, {
    column: {
      formatter: Grid.View.cell,
    },
  })
  let columns = ref[0]
  const rows = ref[1]
  this.columns = columns
  if (this.$('#no_results_outcomes:checkbox:checked').length === 1) {
    columns = [columns[0]].concat(
      filter(
        columns,
        (function (_this) {
          return function (c) {
            return c.hasResults
          }
        })(this)
      )
    )
  }
  if (this.grid) {
    this.grid.setData(rows)
    this.grid.setColumns(columns)
    Grid.View.redrawHeader(this.grid, Grid.averageFn)
  } else {
    this.grid = new Slick.Grid('.outcome-gradebook-wrapper', rows, columns, Grid.options)
    this._attachGridEvents()
    this.grid.init()
    Grid.Events.init(this.grid)
    this._attachEvents()
    Grid.section = this.learningMastery.getCurrentSectionId()
    Grid.View.redrawHeader(this.grid, Grid.averageFn)
  }
  return this.focusFilterKebabIfNeeded()
}

OutcomeGradebookView.prototype.isLoaded = false

OutcomeGradebookView.prototype.onShow = function () {
  if (!this.isLoaded) {
    this._loadFilterSettings()
  }
  if (!this.isLoaded) {
    this.loadOutcomes()
  }
  this.isLoaded = true
  this.$el.fillWindowWithMe({
    onResize: (function (_this) {
      return function () {
        if (_this.grid) {
          return _this.grid.resizeCanvas()
        }
      }
    })(this),
  })
  return $('.post-grades-button-placeholder').hide()
}

// Public: Load a specific result page
//
// Returns nothing.
OutcomeGradebookView.prototype.loadPage = function (page) {
  this.hasOutcomes = $.Deferred()
  // eslint-disable-next-line promise/catch-or-return
  $.when(this.hasOutcomes).then(this.renderGrid)
  return this._loadOutcomes(page)
}

// Internal: Render Section selector.
// Returns nothing.
OutcomeGradebookView.prototype.renderSectionMenu = function () {
  const sectionList = this.learningMastery.getSections()
  const mountPoint = document.querySelector('[data-component="SectionFilter"]')
  if (sectionList.length > 1) {
    const selectedSectionId = this.learningMastery.getCurrentSectionId() || '0'
    Grid.section = selectedSectionId
    const props = {
      sections: sectionList,
      onSelect: this.updateCurrentSection,
      selectedSectionId,
      disabled: false,
    }
    const component = React.createElement(SectionFilter, props)
    // eslint-disable-next-line react/no-render-return-value
    return (this.sectionFilterMenu = ReactDOM.render(component, mountPoint))
  }
}

OutcomeGradebookView.prototype.updateCurrentSection = function (sectionId) {
  this.learningMastery.updateCurrentSectionId(sectionId)
  Grid.section = sectionId
  this._rerender()
  this.updateExportLink(sectionId)
  return this.renderSectionMenu()
}

// Public: Load all outcome results from API.
//
// Returns nothing.
OutcomeGradebookView.prototype.loadOutcomes = function () {
  return this._loadOutcomes()
}

OutcomeGradebookView.prototype._rollupsUrl = function (course, exclude, page) {
  const excluding = exclude === '' ? '' : '&exclude[]=' + exclude
  let sortField = this.sortField
  let sortOutcomeId = null
  let ref
  if (sortField.startsWith('outcome_')) {
    ref = sortField.split('_')
    sortField = ref[0]
    sortOutcomeId = ref[1]
  }
  let sortParams = '&sort_by=' + sortField
  if (sortOutcomeId) {
    sortParams = sortParams + '&sort_outcome_id=' + sortOutcomeId
  }
  if (!this.sortOrderAsc) {
    sortParams += '&sort_order=desc'
  }
  const sectionParam = Grid.section && Grid.section !== '0' ? '&section_id=' + Grid.section : ''
  return (
    '/api/v1/courses/' +
    course +
    '/outcome_rollups?rating_percents=true&per_page=20&include[]=outcomes&include[]=users&include[]=outcome_paths' +
    excluding +
    '&page=' +
    page +
    sortParams +
    sectionParam
  )
}

// Public: Set ordering for outcome columns in gradebook grid
//
// Returns nothing.
OutcomeGradebookView.prototype.setOutcomeOrder = function () {
  const course_id = ENV.context_asset_string.split('_')[1]
  const columns = this.grid.getColumns().slice()

  // save ordering of columns to grid for frontend state
  this.columns = columns.slice()

  // Need to remove first column because it is the student column
  columns.shift()

  const outcomes = columns.map((c, index) => {
    return {
      outcome_id: parseInt(c.outcome.id, 10),
      position: index + 1,
    }
  })

  $.ajax({
    url: this._assignOrderUrl(course_id),
    type: 'POST',
    data: JSON.stringify(outcomes),
    contentType: 'application/json; charset=utf-8'
  })

  return Grid.View.redrawHeader(this.grid, Grid.averageFn)
}

OutcomeGradebookView.prototype._assignOrderUrl = function (course) {
  return `/api/v1/courses/${course}/assign_outcome_order`
}

OutcomeGradebookView.prototype._loadOutcomes = function (page) {
  if (page == null) {
    page = 1
  }
  const filter = this._getOutcomeFiltersParams()
  const course = ENV.context_asset_string.split('_')[1]
  this.$('.outcome-gradebook-wrapper').disableWhileLoading(this.hasOutcomes)
  return this._loadPage(this._rollupsUrl(course, filter, page))
}

OutcomeGradebookView.prototype._getOutcomeFilters = function () {
  const outcome_filters = []
  if (!this._getFilterSetting('inactive_enrollments')) {
    outcome_filters.push('inactive_enrollments')
  }
  if (!this._getFilterSetting('concluded_enrollments')) {
    outcome_filters.push('concluded_enrollments')
  }
  if (!this._getFilterSetting('students_no_results')) {
    outcome_filters.push('missing_user_rollups')
  }
  return outcome_filters
}

OutcomeGradebookView.prototype._getOutcomeFiltersParams = function () {
  return this._getOutcomeFilters()
    .map(
      (function (_this) {
        return function (value) {
          return '&exclude[]=' + value
        }
      })(this)
    )
    .join('')
}

// Internal: Load a page of outcome results from the given URL.
//
// url - The URL to load results from.
// outcomes - An existing response from the API.
//
// Returns nothing.
OutcomeGradebookView.prototype._loadPage = function (url, outcomes) {
  const dfd = $.getJSON(url).fail(function (_e) {
    return $.flashError(I18n.t('There was an error fetching outcome results'))
  })
  return dfd.then(
    (function (_this) {
      return function (response, _status, _xhr) {
        outcomes = _this._mergeResponses(outcomes, response)
        _this.hasOutcomes.resolve(outcomes)
        return _this.learningMastery.renderPagination(
          response.meta.pagination.page,
          response.meta.pagination.page_count
        )
      }
    })(this)
  )
}

// Internal: Merge two API responses into one.
//
// a - The first API response received.
// b - The second API response received.
//
// Returns nothing.
OutcomeGradebookView.prototype._mergeResponses = function (a, b) {
  if (!a) {
    return b
  }
  const response = {}
  response.meta = lodashExtend({}, a.meta, b.meta)
  response.linked = {
    outcomes: a.linked.outcomes,
    outcome_paths: a.linked.outcome_paths,
    users: a.linked.users.concat(b.linked.users),
  }
  response.rollups = a.rollups.concat(b.rollups)
  return response
}

// Internal: Create an event listener function used to filter SlickGrid results.
//
// name - The class name to toggle on/off (e.g. 'mastery', 'remedial').
//
// Returns a function.
OutcomeGradebookView.prototype._createFilter = function (name) {
  return (function (_this) {
    return function (isChecked) {
      Grid.filter = isChecked
        ? uniq(Grid.filter.concat([name]))
        : reject(Grid.filter, function (o) {
            return o === name
          })
      return _this.grid.invalidate()
    }
  })(this)
}

OutcomeGradebookView.prototype.updateExportLink = function (section) {
  let url = ENV.GRADEBOOK_OPTIONS.context_url + '/outcome_rollups.csv'
  let params = '' + this._getOutcomeFiltersParams()
  if (section && section !== '0') {
    if (params !== '') {
      params += '&'
    }
    params += 'section_id=' + section
  }
  if (params !== '') {
    url += '?' + params
  }
  return $('.export-content').attr('href', url)
}

export default OutcomeGradebookView

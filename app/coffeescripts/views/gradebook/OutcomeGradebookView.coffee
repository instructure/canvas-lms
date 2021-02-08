#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

import I18n from 'i18n!gradebookOutcomeGradebookView'
import $ from 'jquery'
import _ from 'underscore'
import React from 'react'
import ReactDOM from 'react-dom'
import {View} from 'Backbone'

import Slick from 'vendor/slickgrid'
import Grid from 'jsx/gradebook/OutcomeGradebookGrid'
import userSettings from '../../userSettings'
import CheckboxView from 'jsx/gradebook/views/CheckboxView'
import SectionMenuView from 'jsx/gradebook/views/SectionMenuView'
import SectionFilter from 'jsx/gradebook/default_gradebook/components/content-filters/SectionFilter'
import template from 'jst/gradebook/outcome_gradebook'
import 'vendor/jquery.ba-tinypubsub'
import '../../jquery.rails_flash_notifications'
import 'jquery.instructure_misc_plugins'
import 'jquery.disableWhileLoading'

Dictionary =
  exceedsMastery:
    color : '#127A1B'
    label : I18n.t('Exceeds Mastery')
  mastery:
    color : if ENV.use_high_contrast then '#127A1B' else '#00AC18'
    label : I18n.t('Meets Mastery')
  nearMastery:
    color : if ENV.use_high_contrast then '#C23C0D' else '#FC5E13'
    label : I18n.t('Near Mastery')
  remedial:
    color : '#EE0612'
    label : I18n.t('Well Below Mastery')

export default class OutcomeGradebookView extends View

    tagName: 'div'

    className: 'outcome-gradebook'

    template: template

    @optionProperty 'learningMastery'

    hasOutcomes: $.Deferred()

    # child views rendered using the {{view}} helper in the template
    checkboxes: [
      new CheckboxView(Dictionary.exceedsMastery),
      new CheckboxView(Dictionary.mastery),
      new CheckboxView(Dictionary.nearMastery),
      new CheckboxView(Dictionary.remedial)
    ]

    inactive_concluded_lmgb_filters: ENV.GRADEBOOK_OPTIONS?.inactive_concluded_lmgb_filters

    ratings: []

    events:
      'click .sidebar-toggle': 'onSidebarToggle'

    sortField: 'student'

    sortOrderAsc: true

    constructor: (options) ->
      super
      @_validateOptions(options)
      if ENV.GRADEBOOK_OPTIONS.outcome_proficiency?.ratings
        @ratings = ENV.GRADEBOOK_OPTIONS.outcome_proficiency.ratings
        @checkboxes = @ratings.map (rating) -> new CheckboxView({color: "\##{rating.color}", label: rating.description})
      Grid.gridRef = @

    remove: ->
      super()
      ReactDOM.unmountComponentAtNode(document.querySelector('[data-component="SectionFilter"]'))

    # Public: Show/hide the sidebar.
    #
    # e - Event object.
    #
    # Returns nothing.
    onSidebarToggle: (e) ->
      e.preventDefault()
      isCollapsed = @_toggleSidebarCollapse()
      @_toggleSidebarArrow()
      @_toggleSidebarTooltips(isCollapsed)

    # Internal: Toggle collapsed class on sidebar.
    #
    # Returns true if collapsed, false if expanded.
    _toggleSidebarCollapse: ->
      @$('.outcome-gradebook-sidebar')
        .toggleClass('collapsed')
        .hasClass('collapsed')

    # Internal: Toggle the direction of the sidebar collapse arrow.
    #
    # Returns nothing.
    _toggleSidebarArrow: ->
      @$('.sidebar-toggle')
        .toggleClass('icon-arrow-open-right')
        .toggleClass('icon-arrow-open-left')

    # Internal: Toggle the direction of the sidebar collapse arrow.
    #
    # Returns nothing.
    _toggleSidebarTooltips: (shouldShow) ->
      if shouldShow
        @$('.checkbox-view').each ->
          $(this).find('.checkbox')
            .attr('data-tooltip', 'left')
            .attr('title', $(this).find('.checkbox-label').text())
        @$('.filters').hide()
      else
        @$('.checkbox').removeAttr('data-tooltip').removeAttr('title')
        @$('.filters').show()

    # Internal: Validate options passed to constructor.
    #
    # options - The options hash passed to the constructor function.
    #
    # Returns nothing on success, raises on failure.
    _validateOptions: ({learningMastery}) ->
      throw new Error('Missing required option: "learningMastery"') unless learningMastery

    # Internal: Listen for events on child views.
    #
    # Returns nothing.
    _attachEvents: ->
      _this = @
      view.on('togglestate', @_createFilter("rating_#{i}")) for view, i in @checkboxes
      @updateExportLink(@learningMastery.getCurrentSectionId())
      @$('#no_results_outcomes').change(() -> _this._toggleOutcomesWithNoResults(this.checked))
      if !@inactive_concluded_lmgb_filters
        @$('#no_results_students').change(() -> _this._toggleStudentsWithNoResults(this.checked))

    _setFilterSetting: (name, value) ->
      filters = userSettings.contextGet('lmgb_filters')
      filters = {} unless filters
      filters[name] = value
      userSettings.contextSet('lmgb_filters', filters)

    _getFilterSetting: (name) ->
      filters = userSettings.contextGet('lmgb_filters')
      filters && filters[name]

    _toggleOutcomesWithNoResults: (enabled) ->
      @_setFilterSetting('outcomes_no_results', enabled)
      if enabled
        columns = [@columns[0]].concat(_.filter(@columns, (c) => c.hasResults))
        @grid.setColumns(columns)
      else
        @grid.setColumns(@columns)
      Grid.View.redrawHeader(@grid, Grid.averageFn)

    _toggleStudentsWithNoResults: (enabled) =>
      @_setFilterSetting('students_no_results', enabled)
      @updateExportLink(@learningMastery.getCurrentSectionId())
      @_rerender()

    _toggleStudentsWithInactiveEnrollments: (enabled) =>
      @_setFilterSetting('inactive_enrollments', enabled)
      @updateExportLink(@learningMastery.getCurrentSectionId())
      @_rerender()

    _toggleStudentsWithConcludedEnrollments: (enabled) =>
      @_setFilterSetting('concluded_enrollments', enabled)
      @updateExportLink(@learningMastery.getCurrentSectionId())
      @_rerender()

    _rerender: ->
      @grid.setData([])
      @grid.invalidate()
      @hasOutcomes = $.Deferred()
      $.when(@hasOutcomes).then(@renderGrid)
      @_loadOutcomes()

    _toggleSort: (e, {grid, sortAsc, sortCol}) =>
      target = $(e.target).attr('data-component')
      # Don't sort if user clicks the enrollments filter kabob
      if target == 'lmgb-student-filter-trigger'
        return
      else if sortCol.field == @sortField
        # Change sort direction
        @sortOrderAsc = !@sortOrderAsc
      else
        # Change in sort column
        @sortField = sortCol.field
        @sortOrderAsc = true
      @_rerender()

    # Internal: Listen for events on grid.
    #
    # Returns nothing.
    _attachGridEvents: ->
      @grid.onHeaderRowCellRendered.subscribe(Grid.Events.headerRowCellRendered)
      @grid.onHeaderCellRendered.subscribe(Grid.Events.headerCellRendered)
      @grid.onSort.subscribe(@_toggleSort)

    # Public: Create object to be passed to the view.
    #
    # Returns an object.
    toJSON: ->
      _.extend({}, checkboxes: @checkboxes, inactive_concluded_lmgb_filters: @inactive_concluded_lmgb_filters)

    _loadFilterSettings: ->
      @$('#no_results_outcomes').prop('checked', @._getFilterSetting('outcomes_no_results'))
      if !@inactive_concluded_lmgb_filters
        @$('#no_results_students').prop('checked', @._getFilterSetting('students_no_results'))

    # Public: Render the view once all needed data is loaded.
    #
    # Returns this.
    render: ->
      super()
      @renderSectionMenu()
      $.when(@hasOutcomes).then(@renderGrid)
      this

    # Internal: Render SlickGrid component.
    #
    # response - Outcomes rollup data from API.
    #
    # Returns nothing.
    renderGrid: (response) =>
      Grid.filter = _.filter(_.range(@checkboxes.length), (i) => @checkboxes[i].checked).map (i) -> "rating_#{i}"
      Grid.ratings = @ratings
      Grid.Util.saveOutcomes(response.linked.outcomes)
      Grid.Util.saveStudents(response.linked.users)
      Grid.Util.saveOutcomePaths(response.linked.outcome_paths)
      Grid.Util.saveSections(@learningMastery.getSections())
      [columns, rows] = Grid.Util.toGrid(response, column: { formatter: Grid.View.cell })
      @columns = columns
      if @$('#no_results_outcomes:checkbox:checked').length == 1
        columns = [columns[0]].concat(_.filter(columns, (c) => c.hasResults))
      if @grid
        @grid.setData(rows)
        @grid.setColumns(columns)
        Grid.View.redrawHeader(@grid, Grid.averageFn)
      else
        @grid = new Slick.Grid(
          '.outcome-gradebook-wrapper',
          rows,
          columns,
          Grid.options)
        @_attachGridEvents()
        @grid.init()
        Grid.Events.init(@grid)
        @_attachEvents()
        Grid.section = @learningMastery.getCurrentSectionId()
        Grid.View.redrawHeader(@grid,  Grid.averageFn)

    isLoaded: false
    onShow: ->
      @_loadFilterSettings() if !@isLoaded
      @loadOutcomes() if !@isLoaded
      @isLoaded = true
      @$el.fillWindowWithMe({
        onResize: => @grid.resizeCanvas() if @grid
      })
      $(".post-grades-button-placeholder").hide();

    # Public: Load a specific result page
    #
    # Returns nothing.
    loadPage: (page) ->
      @hasOutcomes = $.Deferred()
      $.when(@hasOutcomes).then(@renderGrid)
      @_loadOutcomes(page)

    # Internal: Render Section selector.
    # Returns nothing.
    renderSectionMenu: =>
      sectionList = @learningMastery.getSections()
      mountPoint = document.querySelector('[data-component="SectionFilter"]')
      if sectionList.length > 1
        selectedSectionId = @learningMastery.getCurrentSectionId() || '0'
        Grid.section = selectedSectionId
        props =
          sections: sectionList
          onSelect: @updateCurrentSection
          selectedSectionId: selectedSectionId
          disabled: false

        component = React.createElement(SectionFilter, props)
        @sectionFilterMenu = ReactDOM.render(component, mountPoint)

    updateCurrentSection: (sectionId) =>
      @learningMastery.updateCurrentSectionId(sectionId)
      Grid.section = sectionId
      @_rerender()
      @updateExportLink(sectionId)
      @renderSectionMenu()

    # Public: Load all outcome results from API.
    #
    # Returns nothing.
    loadOutcomes: () ->
      @_loadOutcomes()

    _rollupsUrl: (course, exclude, page) ->
      excluding = if exclude == '' then '' else "&exclude[]=#{exclude}"
      sortField = @sortField
      sortOutcomeId = null
      [sortField, sortOutcomeId] = sortField.split('_') if sortField.startsWith('outcome_')
      sortParams = "&sort_by=#{sortField}"
      sortParams = "#{sortParams}&sort_outcome_id=#{sortOutcomeId}" if sortOutcomeId
      sortParams = "#{sortParams}&sort_order=desc" if !@sortOrderAsc
      sectionParam = if Grid.section and Grid.section != "0" then "&section_id=#{Grid.section}" else ""
      "/api/v1/courses/#{course}/outcome_rollups?rating_percents=true&per_page=20&include[]=outcomes&include[]=users&include[]=outcome_paths#{excluding}&page=#{page}#{sortParams}#{sectionParam}"

    _loadOutcomes: (page = 1) =>
      filter = @_getOutcomeFiltersParams()
      course = ENV.context_asset_string.split('_')[1]
      @$('.outcome-gradebook-wrapper').disableWhileLoading(@hasOutcomes)
      @_loadPage(@_rollupsUrl(course, filter, page))

    _getOutcomeFilters: ->
      outcome_filters = []
      if @inactive_concluded_lmgb_filters
        if !@._getFilterSetting('inactive_enrollments') then outcome_filters.push('inactive_enrollments')
        if !@._getFilterSetting('concluded_enrollments') then outcome_filters.push('concluded_enrollments')
        if !@._getFilterSetting('students_no_results') then outcome_filters.push('missing_user_rollups')
      else
        if @._getFilterSetting('students_no_results') then outcome_filters.push('missing_user_rollups')

      return outcome_filters

    _getOutcomeFiltersParams: ->
      return @_getOutcomeFilters().map((value)  => "&exclude[]=#{value}").join('')

    # Internal: Load a page of outcome results from the given URL.
    #
    # url - The URL to load results from.
    # outcomes - An existing response from the API.
    #
    # Returns nothing.
    _loadPage: (url, outcomes) ->
      dfd  = $.getJSON(url).fail((e) ->
        $.flashError(I18n.t('There was an error fetching outcome results'))
      )
      dfd.then (response, status, xhr) =>
        outcomes = @_mergeResponses(outcomes, response)
        @hasOutcomes.resolve(outcomes)
        @learningMastery.renderPagination(
          response.meta.pagination.page,
          response.meta.pagination.page_count
        )

    # Internal: Merge two API responses into one.
    #
    # a - The first API response received.
    # b - The second API response received.
    #
    # Returns nothing.
    _mergeResponses: (a, b) ->
      return b unless a
      response = {}
      response.meta    = _.extend({}, a.meta, b.meta)
      response.linked  = {
        outcomes: a.linked.outcomes
        outcome_paths: a.linked.outcome_paths
        users: a.linked.users.concat(b.linked.users)
      }
      response.rollups = a.rollups.concat(b.rollups)
      response

    # Internal: Create an event listener function used to filter SlickGrid results.
    #
    # name - The class name to toggle on/off (e.g. 'mastery', 'remedial').
    #
    # Returns a function.
    _createFilter: (name) ->
      filterFunction = (isChecked) =>
        Grid.filter = if isChecked
          _.uniq(Grid.filter.concat([name]))
        else
          _.reject(Grid.filter, (o) -> o == name)
        @grid.invalidate()

    updateExportLink: (section) =>
      url = "#{ENV.GRADEBOOK_OPTIONS.context_url}/outcome_rollups.csv"
      params = "#{@_getOutcomeFiltersParams()}"

      if section and section != '0'
        params += "&" if params != ''
        params += "section_id=#{section}"

      url += "?#{params}" if params != ''
      $('.export-content').attr('href', url)

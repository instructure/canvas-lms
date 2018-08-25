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

define [
  'i18n!gradebook'
  'jquery'
  'underscore'
  'Backbone'
  'vendor/slickgrid'
  '../../gradebook/OutcomeGradebookGrid'
  '../../userSettings'
  '../gradebook/CheckboxView'
  '../gradebook/SectionMenuView'
  'jst/gradebook/outcome_gradebook'
  'vendor/jquery.ba-tinypubsub'
  '../../jquery.rails_flash_notifications'
  'jquery.instructure_misc_plugins'
], (I18n, $, _, {View}, Slick, Grid, userSettings, CheckboxView, SectionMenuView, template, cellTemplate) ->

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

  class OutcomeGradebookView extends View

    tagName: 'div'

    className: 'outcome-gradebook-container'

    template: template

    @optionProperty 'gradebook'

    hasOutcomes: $.Deferred()

    # child views rendered using the {{view}} helper in the template
    checkboxes: [
      new CheckboxView(Dictionary.exceedsMastery),
      new CheckboxView(Dictionary.mastery),
      new CheckboxView(Dictionary.nearMastery),
      new CheckboxView(Dictionary.remedial)
    ]

    ratings: []

    events:
      'click .sidebar-toggle': 'onSidebarToggle'

    constructor: (options) ->
      super
      @_validateOptions(options)
      if ENV.GRADEBOOK_OPTIONS.outcome_proficiency?.ratings
        @ratings = ENV.GRADEBOOK_OPTIONS.outcome_proficiency.ratings
        @checkboxes = @ratings.map (rating) -> new CheckboxView({color: "\##{rating.color}", label: rating.description})

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
    _validateOptions: ({gradebook}) ->
      throw new Error('Missing required option: "gradebook"') unless gradebook

    # Internal: Listen for events on child views.
    #
    # Returns nothing.
    _attachEvents: ->
      view.on('togglestate', @_createFilter("rating_#{i}")) for view, i in @checkboxes
      $.subscribe('currentSection/change', Grid.Events.sectionChangeFunction(@grid))
      $.subscribe('currentSection/change', @updateExportLink)
      @updateExportLink(@gradebook.sectionToShow)
      _this = @
      @$('#no_results_outcomes').change(() -> _this._toggleOutcomesWithNoResults(this.checked))
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

    _toggleStudentsWithNoResults: (enabled) ->
      @_setFilterSetting('students_no_results', enabled)
      @grid.setData([])
      @grid.invalidate()
      @hasOutcomes = $.Deferred()
      $.when(@hasOutcomes).then(@renderGrid)
      @_loadOutcomes()

    # Internal: Listen for events on grid.
    #
    # Returns nothing.
    _attachGridEvents: ->
      @grid.onHeaderRowCellRendered.subscribe(Grid.Events.headerRowCellRendered)
      @grid.onHeaderCellRendered.subscribe(Grid.Events.headerCellRendered)
      @grid.onSort.subscribe(Grid.Events.sort)

    # Public: Create object to be passed to the view.
    #
    # Returns an object.
    toJSON: ->
      _.extend({}, checkboxes: @checkboxes)

    _loadFilterSettings: ->
      @$('#no_results_outcomes').prop('checked', @._getFilterSetting('outcomes_no_results'))
      @$('#no_results_students').prop('checked', @._getFilterSetting('students_no_results'))

    # Public: Render the view once all needed data is loaded.
    #
    # Returns this.
    render: ->
      $.when(@gradebook.hasSections)
        .then(=> super)
        .then(@_drawSectionMenu)
      $.when(@hasOutcomes).then(@renderGrid)
      this

    # Internal: Render SlickGrid component.
    #
    # response - Outcomes rollup data from API.
    #
    # Returns nothing.
    renderGrid: (response) =>
      Grid.filter = _.range(@checkboxes.length).map (i) -> "rating_#{i}"
      Grid.ratings = @ratings
      Grid.Util.saveOutcomes(response.linked.outcomes)
      Grid.Util.saveStudents(response.linked.users)
      Grid.Util.saveOutcomePaths(response.linked.outcome_paths)
      Grid.Util.saveSections(@gradebook.sections) # might want to put these into the api results at some point
      [columns, rows] = Grid.Util.toGrid(response, column: { formatter: Grid.View.cell }, row: { section: @menu.currentSection })
      @columns = columns
      if @$('#no_results_outcomes:checkbox:checked').length == 1
        columns = [columns[0]].concat(_.filter(columns, (c) => c.hasResults))
      if @grid
        @grid.setData(rows)
        @grid.setColumns(columns)
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
        Grid.View.redrawHeader(@grid,  Grid.averageFn, @menu.currentSection)

    isLoaded: false
    onShow: ->
      @_loadFilterSettings() if !@isLoaded
      @loadOutcomes() if !@isLoaded
      @isLoaded = true
      @$el.fillWindowWithMe({
        onResize: => @grid.resizeCanvas() if @grid
      })
      $(".post-grades-button-placeholder").hide();

    # Public: Load all outcome results from API.
    #
    # Returns nothing.
    loadOutcomes: () ->
      $.when(@gradebook.hasSections).then(@_loadOutcomes)

    _rollupsUrl: (course, exclude) ->
      excluding = if exclude == '' then '' else "&exclude[]=#{exclude}"
      "/api/v1/courses/#{course}/outcome_rollups?per_page=100&include[]=outcomes&include[]=users&include[]=outcome_paths#{excluding}"

    _loadOutcomes: =>
      exclude = if @$('#no_results_students').prop('checked') then 'missing_user_rollups' else ''
      course = ENV.context_asset_string.split('_')[1]
      @$('.outcome-gradebook-wrapper').disableWhileLoading(@hasOutcomes)
      @_loadPage(@_rollupsUrl(course, exclude))

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
        if response.meta.pagination.next
          @_loadPage(response.meta.pagination.next, outcomes)
        else
          @hasOutcomes.resolve(outcomes)

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

    # Internal: Initialize the child SectionMenuView. This happens here because
    #   the menu needs to wait for relevant course sections to load.
    #
    # Returns nothing.
    _drawSectionMenu: =>
      @menu = new SectionMenuView(
        sections: @gradebook.sectionList()
        currentSection: @gradebook.sectionToShow
        el: $('.section-button-placeholder'),
      )
      @menu.render()

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
      url += "?section_id=#{section}" if section
      $('.export-content').attr('href', url)

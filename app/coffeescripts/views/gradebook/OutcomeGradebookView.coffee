define [
  'i18n!gradebook2'
  'jquery'
  'underscore'
  'Backbone'
  'vendor/slickgrid'
  'compiled/gradebook2/OutcomeGradebookGrid'
  'compiled/views/gradebook/CheckboxView'
  'compiled/views/gradebook/SectionMenuView'
  'jst/gradebook2/outcome_gradebook'
  'vendor/jquery.ba-tinypubsub'
  'jquery.instructure_misc_plugins'
], (I18n, $, _, {View}, Slick, Grid, CheckboxView, SectionMenuView, template, cellTemplate) ->

  Dictionary =
    exceedsMastery:
      color : '#6a843f'
      label : I18n.t('Exceeds Mastery')
    mastery:
      color : '#8aac53'
      label : I18n.t('Meets Mastery')
    nearMastery:
      color : '#e0d773'
      label : I18n.t('Near Mastery')
    remedial:
      color : '#df5b59'
      label : I18n.t('Well Below Mastery')

  class OutcomeGradebookView extends View

    tagName: 'div'

    className: 'outcome-gradebook-container'

    template: template

    @optionProperty 'gradebook'

    hasOutcomes: $.Deferred()

    # child views rendered using the {{view}} helper in the template
    checkboxes:
      'exceeds':         new CheckboxView(Dictionary.exceedsMastery)
      mastery:           new CheckboxView(Dictionary.mastery)
      'near-mastery':    new CheckboxView(Dictionary.nearMastery)
      remedial:          new CheckboxView(Dictionary.remedial)

    events:
      'click .sidebar-toggle': 'onSidebarToggle'

    constructor: (options) ->
      super
      @_validateOptions(options)

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
      else
        @$('.checkbox').removeAttr('data-tooltip').removeAttr('title')

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
      view.on('togglestate', @_createFilter(name)) for name, view of @checkboxes
      $.subscribe('currentSection/change', Grid.Events.sectionChangeFunction(@grid))
      $.subscribe('currentSection/change', @updateExportLink)
      @updateExportLink(@gradebook.sectionToShow)

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
      _.extend({}, @checkboxes)

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
      Grid.Util.saveOutcomes(response.linked.outcomes)
      Grid.Util.saveStudents(response.linked.users)
      Grid.Util.saveOutcomePaths(response.linked.outcome_paths)
      Grid.Util.saveSections(@gradebook.sections) # might want to put these into the api results at some point
      [columns, rows] = Grid.Util.toGrid(response, column: { formatter: Grid.View.cell }, row: { section: @menu.currentSection })
      @grid = new Slick.Grid(
        '.outcome-gradebook-wrapper',
        rows,
        columns,
        Grid.options)
      @_attachGridEvents()
      @grid.init()
      Grid.Events.init(@grid)
      @_attachEvents()

    isLoaded: false
    onShow: ->
      @loadOutcomes() if !@isLoaded
      @isLoaded = true
      @$el.fillWindowWithMe({
        onResize: => @grid.resizeCanvas() if @grid
      })
      $(".post-grades-placeholder").hide();

    # Public: Load all outcome results from API.
    #
    # Returns nothing.
    loadOutcomes: () ->
      $.when(@gradebook.hasSections).then(@_loadOutcomes)

    _loadOutcomes: =>
      course = ENV.context_asset_string.split('_')[1]
      @$('.outcome-gradebook-wrapper').disableWhileLoading(@hasOutcomes)
      @_loadPage("/api/v1/courses/#{course}/outcome_rollups?per_page=100&include[]=outcomes&include[]=users&include[]=outcome_paths")

    # Internal: Load a page of outcome results from the given URL.
    #
    # url - The URL to load results from.
    # outcomes - An existing response from the API.
    #
    # Returns nothing.
    _loadPage: (url, outcomes) ->
      dfd  = $.getJSON(url)
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

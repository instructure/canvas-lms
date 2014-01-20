define [
  'i18n!gradebook2'
  'underscore'
  'Backbone'
  'vendor/slickgrid'
  'compiled/gradebook2/OutcomeGradebookGrid'
  'compiled/views/gradebook/CheckboxView'
  'compiled/views/gradebook/SectionMenuView'
  'jst/gradebook2/outcome_gradebook'
  'vendor/jquery.ba-tinypubsub'
], (I18n, _, {View}, Slick, Grid, CheckboxView, SectionMenuView, template, cellTemplate) ->

  Dictionary =
    mastery:
      color : '#8bab58'
      label : I18n.t('mastery', 'mastery')
    nearMastery:
      color : '#e0d679'
      label : I18n.t('near_mastery', 'near mastery')
    remedial:
      color : '#dd5c5c'
      label : I18n.t('remedial', 'remedial')

  class OutcomeGradebookView extends View

    tagName: 'div'

    className: 'outcome-gradebook-container'

    template: template

    @optionProperty 'gradebook'

    hasOutcomes: $.Deferred()

    # child views rendered using the {{view}} helper in the template
    checkboxes:
      mastery:        new CheckboxView(Dictionary.mastery)
      'near-mastery': new CheckboxView(Dictionary.nearMastery)
      remedial:       new CheckboxView(Dictionary.remedial)

    constructor: (options) ->
      super
      @_validateOptions(options)

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
      _.extend({}, @checkboxes, menu: @menu)

    # Public: Render the view once all needed data is loaded.
    #
    # Returns this.
    render: ->
      $.when(@gradebook.hasSections)
        .then(@_initMenu)
        .then(=> super)
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

    # Public: Load all outcome results from API.
    #
    # Returns nothing.
    loadOutcomes: () ->
      course = ENV.context_asset_string.split('_')[1]
      @$('.outcome-gradebook-wrapper').disableWhileLoading(@hasOutcomes)
      @_loadPage("/api/v1/courses/#{course}/outcome_rollups?per_page=100")

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
      response.linked  = { outcomes: a.linked.outcomes, users: a.linked.users.concat(b.linked.users) }
      response.rollups = a.rollups.concat(b.rollups)
      response

    # Internal: Initialize the child SectionMenuView. This happens here because
    #   the menu needs to wait for relevant course sections to load.
    #
    # Returns nothing.
    _initMenu: =>
      @menu = new SectionMenuView(
        sections: @gradebook.sectionList()
        currentSection: @gradebook.sectionToShow
        className: 'outcome-gradebook-section-select'
      )

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

define [
  'i18n!jobs'
  'jquery'
  'vendor/slickgrid'
  'jquery.ajaxJSON'
  'jqueryui/dialog'
], (I18n, $, Slick) ->
  ###
  xsslint safeString.identifier klass d out_of runtime_string
  ###

  fillin_job_data = (job) ->
    $('#show-job .show-field').each (idx, field) =>
      field_name = field.id.replace("job-", '')
      $(field).text(job[field_name] || '')
    $('#job-id-link').attr('href', "/jobs?flavor=id&q=#{job.id}")

  selected_job = null

  class FlavorGrid
    constructor: (@options, @type_name, @grid_name) ->
      @data = []
      @$element = $(@grid_name)
      @setTimer()
      @query = ''

    setTimer: () =>
      setTimeout @refresh, 0
      if @options.refresh_rate
        setTimeout (=> @refresh(@setTimer)), @options.refresh_rate

    saveSelection: =>
      if @type_name == 'running'
        @oldSelected = {}
        for row in @grid.getSelectedRows()
          @oldSelected[@data[row]['id']] = true

    restoreSelection: =>
      if @type_name == 'running'
        index = 0
        newSelected = []
        for item in @data
          newSelected.push index if @oldSelected[item['id']]
          index += 1
        @restoringSelection = true
        @grid.setSelectedRows(newSelected)
        @restoringSelection = false

    refresh: (cb) =>
      @$element.queue () =>
        $.ajaxJSON @options.url, "GET", { flavor: @options.flavor, q: @query }, (data) =>
          @saveSelection()
          @data.length = 0
          @loading = {}
          @data.push item for item in data[@type_name]
          if data.total && data.total > @data.length
            @data.push({}) for i in [@data.length ... data.total]

          if (@sortData)
            @sort(null, @sortData)
          else
            @grid.invalidate()
            @restoreSelection()

          cb?()
          @updated?()
          @$element.dequeue()

    change_flavor: (flavor) =>
      @options.flavor = flavor
      @grid.setSelectedRows []
      @refresh()

    grid_options: () ->
      { rowHeight: 20 }

    init: () ->
      @columns = @build_columns()
      @loading = {}
      @grid = new Slick.Grid(@grid_name, @data, @columns, @grid_options())
      this

  class window.Jobs extends FlavorGrid
    constructor: (options, type_name = 'jobs', grid_name = '#jobs-grid') ->
      Jobs.max_attempts = options.max_attempts if options.max_attempts
      super(options, type_name, grid_name)
      if options.starting_query
        @query = options.starting_query
      @show_search($('#jobs-flavor').val())

    search: (query) ->
      @query = query
      @refresh()

    show_search: (flavor) =>
      switch flavor
        when "id", "strand", "tag"
          $('#jobs-search').show()
          $('#jobs-search').attr('placeholder', flavor)
        else
          $('#jobs-search').hide()

    change_flavor: (flavor) =>
      @show_search(flavor)
      super(flavor)

    attempts_formatter: (r,c,d) =>
      return '' unless @data[r].id
      max = (@data[r].max_attempts || Jobs.max_attempts)
      if d == 0
        klass = ''
      else if d < max
        klass = 'has-failed-attempts'
      else if d == @options.on_hold_attempt_count
        klass = 'on-hold'
        d = 'hold'
      else
        klass = 'has-failed-max-attempts'
      out_of = if d == 'hold' then '' else "/ #{max}"
      "<span class='#{klass}'>#{d}#{out_of}</span>"

    load: (row) =>
      @$element.queue () =>
        row = row - (row % @options.limit)
        if @loading[row]
          @$element.dequeue()
          return
        @loading[row] = true
        $.ajaxJSON @options.url, "GET", { flavor: @options.flavor, q: @query, offset: row }, (data) =>
          @data[row ... row + data[@type_name].length] = data[@type_name]
          @grid.invalidate()
          @$element.dequeue()

    id_formatter: (r,c,d) =>
      if @data[r].id
        @data[r].id
      else
        @load(r)
        "<span class='unloaded-id'>-</span>"

    build_columns: () ->
      [
        id: 'id'
        name: I18n.t('columns.id', 'id')
        field: 'id'
        width: 100
        formatter: @id_formatter
      ,
        id: 'tag'
        name: I18n.t('columns.tag', 'tag')
        field: 'tag'
        width: 200
      ,
        id: 'attempts'
        name: I18n.t('columns.attempt', 'attempt')
        field: 'attempts'
        width: 65
        formatter: @attempts_formatter
      ,
        id: 'priority'
        name: I18n.t('columns.priority', 'priority')
        field: 'priority'
        width: 60
      ,
        id: 'strand'
        name: I18n.t('columns.strand', 'strand')
        field: 'strand'
        width: 100
      ,
        id: 'run_at'
        name: I18n.t('columns.run_at', 'run at')
        field: 'run_at'
        width: 165
      ]

    init: () ->
      super()
      @grid.setSelectionModel(new Slick.RowSelectionModel())
      @grid.onSelectedRowsChanged.subscribe =>
        return if @restoringSelection
        rows = @grid.getSelectedRows()
        row = if rows?.length == 1 then rows[0] else -1
        selected_job = @data[rows[0]] || {}
        fillin_job_data(selected_job)
      this

    selectAll: () ->
      @grid.setSelectedRows([0...@data.length])
      @grid.onSelectedRowsChanged.notify()

    onSelected: (action) ->
      params =
        flavor: @options.flavor
        q: @query
        update_action: action

      if @grid.getSelectedRows().length < 1
        alert('No jobs are selected')
        return

      all_jobs = @grid.getSelectedRows().length > 1 && @grid.getSelectedRows().length == @data.length

      if all_jobs
        message = switch action
          when 'hold' then I18n.t 'confirm.hold_all', "Are you sure you want to hold *all* jobs of this type and matching this query?"
          when 'unhold' then I18n.t 'confirm.unhold_all', "Are you sure you want to unhold *all* jobs of this type and matching this query?"
          when 'destroy' then I18n.t 'confirm.destroy_all', "Are you sure you want to destroy *all* jobs of this type and matching this query?"
        return unless confirm(message)

      # special case -- if they've selected all, then don't send the ids so that
      # we can operate on jobs that match the query but haven't even been loaded
      # yet
      unless all_jobs
        params.job_ids = (@data[row].id for row in @grid.getSelectedRows())

      $.ajaxJSON @options.batch_update_url, "POST", params, @refresh
      @grid.setSelectedRows []

    updated: () ->
      $('#jobs-total').text @data.length
      if @data.length == 1 && @type_name == 'jobs'
        @grid.setSelectedRows [0]
        @grid.onSelectedRowsChanged.notify()

    getFullJobDetails: (cb) ->
      if !selected_job || selected_job.handler
        cb()
      else
        $.ajaxJSON "#{@options.job_url}/#{selected_job.id}", "GET", {flavor: @options.flavor}, (data) =>
          selected_job.handler = data.handler
          selected_job.last_error = data.last_error
          fillin_job_data(selected_job)
          cb()

  class Workers extends Jobs
    constructor: (options) ->
      super(options, 'running', '#running-grid')

    runtime_formatter: (r,c,d) =>
      runtime = (new Date() - Date.parse(d)) / 1000
      if runtime >= @options.super_slow_threshold
        klass = 'super-slow'
      else if runtime > @options.slow_threshold
        klass = 'slow'
      else
        klass = ''
      format = 'HH:mm:ss'
      format = 'd\\dHH:mm:ss' if runtime > 86400
      runtime_string = new Date(null, null, null, null, null, runtime).toString(format)
      runtime_string = 'FOREVA' if runtime > 86400 * 28
      "<span class='#{klass}'>#{runtime_string}</span>"

    build_columns: () ->
      cols = [
        id: 'worker'
        name: I18n.t('columns.worker', 'worker')
        field: 'locked_by'
        width: 90
      ].concat(super())
      cols.pop()
      cols.push(
        id: 'runtime',
        name: I18n.t('columns.runtime', 'runtime')
        field: 'locked_at'
        width: 85
        formatter: @runtime_formatter
      )
      for col in cols
        col.sortable = true
      cols

    updated: () ->

    init: () ->
      super()
      @sort = (event, data) =>
        @sortData = data
        @saveSelection() if event
        field = data.sortCol.field

        @data.sort (a, b) =>
          aField = a[field] || ''
          bField = b[field] || ''
          if aField > bField
            result = 1
          else if aField < bField
            result = -1
          else
            result = 0

          result = -result unless data.sortAsc
          result = -result if field == 'locked_at'
          result

        @grid.invalidate()
        @restoreSelection()
      @grid.onSort.subscribe(@sort)
      @grid.setSortColumn('runtime', false)
      @sortData = {
        sortCol:
          field: 'locked_at'
        sortAsc: false
      }

  class Tags extends FlavorGrid
    constructor: (options) ->
      super(options, 'tags', '#tags-grid')

    build_columns: () ->
      [
        id: 'tag'
        name: I18n.t('columns.tag', 'tag')
        field: 'tag'
        width: 200
      ,
        id: 'count'
        name: I18n.t('columns.count', 'count')
        field: 'count'
        width: 50
      ]

    grid_options: () ->
      $.extend(super(), { enableCellNavigation: false })

    init: () ->
      super()
      @grid.setSelectionModel(new Slick.RowSelectionModel())
      this

  $.extend(window,
    Jobs: Jobs
    Workers: Workers
    Tags: Tags
  )

  $(document).ready () ->
    $('#tags-flavor').change () ->
      window.tags.change_flavor($(this).val())
    $('#jobs-flavor').change () ->
      window.jobs.change_flavor($(this).val())

    $('#jobs-refresh').click () ->
      window.jobs.refresh()

    search_event = if $('#jobs-search')[0].onsearch == undefined then 'change' else 'search'
    $('#jobs-search').bind search_event, () ->
      window.jobs.search $(this).val()

    $('#select-all-jobs').click () -> window.jobs.selectAll()

    $('#hold-jobs').click () -> window.jobs.onSelected('hold')
    $('#un-hold-jobs').click () -> window.jobs.onSelected('unhold')
    $('#delete-jobs').click () -> window.jobs.onSelected('destroy')

    $('#job-handler-show').click () ->
      window.jobs.getFullJobDetails () ->
        $('#job-handler-wrapper').clone().dialog
          title: I18n.t('titles.job_handler', 'Job Handler')
          width: 900
          height: 700
          modal: true
      false

    $('#job-last_error-show').click () ->
      window.jobs.getFullJobDetails () ->
        $('#job-last_error-wrapper').clone().dialog
          title: I18n.t('titles.last_error', 'Last Error')
          width: 900
          height: 700
          modal: true
      false

  { Jobs, Workers, Tags }


define [
  'jquery'
  'i18n!calendar'
  'compiled/calendar/TimeBlockListManager'
  'compiled/calendar/TimeBlockRow'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
  'vendor/date'
], ($, I18n, TimeBlockListManager, TimeBlockRow) ->

  class TimeBlockList
    # blocks is an array of [ Date:start, Date:end, Bool:locked ].
    # The UI only supports start/end times which
    # are in the same day in the user's timezone.
    constructor: (element, splitterSelector, blocks) ->
      @element = $(element)
      @splitterDiv = $(splitterSelector)
      @blocksManager = new TimeBlockListManager(blocks)
      @splitterDiv.find('.split-link').click @handleSplitClick

      @element.delegate 'input', 'change', (event) =>
        @addRow() if $(event.currentTarget).closest('tr').is ':last-child'
      @render()

    render: ->
      @rows = []
      @element.empty()
      @addRow(block) for block in @blocksManager.blocks
      @addRow() #add a blank row at the bottom

    rowRemoved: (rowToRemove) ->
      @rows = for row in @rows when row isnt rowToRemove
        aNonLockedRowExists = true unless row.locked
        row

      @addRow() unless aNonLockedRowExists

    addRow: (data) =>
      row = new TimeBlockRow(this, data)
      @element.append row.$row
      @rows.push row
      row

    handleSplitClick: (event) =>
      event.preventDefault()
      duration = @splitterDiv.find('[name=duration]').val()
      @split duration

    split: (minutes) ->
      if minutes && @validate()
        @blocksManager.split minutes
        @render()

    # weird side-effect: populates the blocksManager
    validate: ->
      valid = true
      @blocksManager.reset()
      for row in @rows
        if row.validate() and not row.incomplete()
          @blocksManager.add row.getData()... unless row.blank()
        else
          valid = false

      if @blocksManager.blocks.length == 0
        alert(I18n.t 'no_dates_error', 'You need to specify at least one date and time')
        valid = false
      else if !valid
        alert(I18n.t 'time_block_errors', 'There are errors in your time block selections.')
      valid

    blocks: ->
      [ range.start, range.end ] for range in @blocksManager.blocks when !range.locked

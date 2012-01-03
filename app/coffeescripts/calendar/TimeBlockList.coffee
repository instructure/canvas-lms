define 'compiled/calendar/TimeBlockList', [
  'compiled/calendar/TimeBlockListManager'
  'jst/calendar/timeBlockList'
  'jst/calendar/_timeBlock'
], (TimeBlockListManager, timeBlockListTemplate, timeBlockTemplate) ->

  class
    # blocks is an array of [ Date, Date ] pairs, representing
    # start/end times. The UI only supports start/end times which
    # are in the same day in the user's timezone.
    constructor: (selector, blocks) ->
      @div = $ selector
      @blocksManager = new TimeBlockListManager(blocks)
      @render()

    render: (blocks) =>
      data = { time_blocks: blocks || [] }

      unless blocks?
        for block in @blocksManager.blocks
          data.time_blocks.push {
            formatted_date: block.start.toString('MMM d, yyyy')
            formatted_start_time: block.start.toString('h:mmtt')
            formatted_end_time: block.end.toString('h:mmtt')
            locked: block.locked
          }

      @div.html timeBlockListTemplate(data)

      @addHandlers(row) for row in @div.find('tr')

      @div.find('.split-link').click @splitClick

      @lastRow = @div.find('tr:last')

    addHandlers: (row) ->
      $row = $(row)
      $row.find('.date_field[disabled!="disabled"]').date_field()
      $row.find('.time_field[disabled!="disabled"]').time_field()

      $row.find('input').change @inputChange
      $row.find('input').blur @inputBlur
      $row.find('input').focus @inputFocus

      $row.find('.delete-block-link').click @deleteClick

    inputChange: (event) =>
      input = event.target

      $row = $(input).closest('tr')
      if $row.get(0) == $('.time-block-list-body tr:last').get(0)
        $('.time-block-list-body').append timeBlockTemplate(locked: false, formatted_date: "", formatted_start_time: "", formatted_end_time: "")
        @addHandlers('.time-block-list-body tr:last')

        # refocus the field we were in previously
        numRows = $('.time-block-list-body').find('tr').length
        $focusRow = $('.time-block-list-body').find("tr:nth-child(#{numRows - 1})")
        # please don't hate me for doing this
        $focusRow.find("[name='#{input.name}']").parent().next().find("input").focus()

    inputBlur: (event) =>
      input = event.target
      $input = $(input)
      unless @validField(input)
        # blank rows are OK
        allBlank = true
        for i in $input.closest('tr').find('input')
          allBlank = false if i.value != ''

        $input.addClass 'error' unless allBlank
      else
        $input.val $input.nextAll('.datetime_suggest').text()

    deleteClick: (event) =>
      event.preventDefault()
      $(event.target).closest("tr").remove()

    inputFocus: (event) ->
      input  = event.target
      $input = $(input)
      $input.removeClass 'error'

      $('.time-block-list-body').find('tr').each (i, row) =>
        $row = $(row)

        if row == $input.closest('tr').get(0)
          $row.addClass 'focused'
        else
          $row.removeClass 'focused'

    splitClick: (event) =>
      event.preventDefault()
      duration = @div.find('[name=duration]').val()
      if duration && @validate()
        @split(duration)
        @render()

    split: (minutes) ->
      @blocksManager.split minutes

    # weird side-effect: populates the blocksManager
    validate: ->
      valid = true

      @blocksManager.reset()
      lastRow = $('.time-block-list-body tr:last').get(0)

      $('.time-block-list-body').find('tr').each (i, row) =>
        return if row == lastRow

        $row = $(row)
        for fieldName in ['date', 'start_time', 'end_time']
          $input = $row.find("[name='#{fieldName}']")
          unless @validField($input)
            valid = false

        if valid
          data = $row.getFormData()
          start  = Date.parse "#{data.date} #{data.start_time}"
          end    = Date.parse "#{data.date} #{data.end_time}"
          locked = $(row).hasClass('locked')
          @blocksManager.add start, end, locked

      alert "fix your errors" unless valid
      valid

    validField: (input) ->
      $input = $(input)
      invalidDate = $input.nextAll('.datetime_suggest').hasClass('invalid_datetime')
      !($input.val() == '') && !invalidDate

    blocks: () ->
      ary = []
      for range in @blocksManager.blocks
        ary.push [ range.start, range.end ] unless range.locked
      ary

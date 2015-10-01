define ['jquery', 'moment', 'compiled/util/fcUtil', 'bower/fullcalendar/dist/fullcalendar'], ($, moment, fcUtil) ->

  class TimeBlockListManager
    # takes an optional array of Date pairs
    constructor: (blocks) ->
      @blocks = []

      if blocks
        @add start, end, locked for [start, end, locked] in blocks

    add: (start, end, locked) ->
      # add overlap-rejection logic
      @blocks.push {start: start, end: end, locked: locked}

    consolidate: ->
      @sort()

      consolidatedBlocks = []
      consolidatedBlocks.last = -> this[this.length - 1]

      for block in @blocks
        unless consolidatedBlocks.last()
          consolidatedBlocks.push(block)
          continue

        lastBlock = consolidatedBlocks.last()
        if +lastBlock.end == +block.start && !lastBlock.locked && !block.locked
          lastBlock.end = block.end
        else
          consolidatedBlocks.push block

      @blocks = consolidatedBlocks

    # split each block into multiple blocks of the given length
    split: (minutes) ->
      @consolidate()

      splitBlockLength = minutes * 60 * 1000

      for block in @blocks
        continue if block.locked
        while moment.duration(block.end.diff(block.start)).asMilliseconds() > minutes * 60 * 1000
          oldStart = fcUtil.clone(block.start)
          newStart = fcUtil.clone(oldStart).add(splitBlockLength, "millisecond")
          block.start = fcUtil.clone(newStart)
          @add(oldStart, newStart)

      @sort()

    sort: ->
      @blocks = @blocks.sort (a, b) ->
        if a.end <= b.start
          -1
        else
          1

    delete: (index) ->
      if index? && @blocks.length > index && !@blocks[index].locked
        @blocks.splice(index, 1)

    reset: -> @blocks = []

#
# Copyright (C) 2012 - present Instructure, Inc.
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

define ['jquery', 'moment', '../util/fcUtil'], ($, moment, fcUtil) ->

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

      for block in @blocks
        continue if block.locked
        nextBreak = fcUtil.clone(block.start).add(minutes, 'minutes')
        while block.end > nextBreak
          @add(block.start, fcUtil.clone(nextBreak))
          block.start = fcUtil.clone(nextBreak)
          nextBreak.add(minutes, 'minutes')

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

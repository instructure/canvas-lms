/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import fcUtil from './jquery/fcUtil'

export default class TimeBlockListManager {
  // takes an optional array of Date pairs
  constructor(blocks) {
    this.blocks = []
    if (blocks) {
      for (let i = 0, len = blocks.length; i < len; i++) {
        const ref = blocks[i],
          start = ref[0],
          end = ref[1],
          locked = ref[2]
        this.add(start, end, locked)
      }
    }
  }

  add(start, end, locked) {
    // add overlap-rejection logic
    return this.blocks.push({start, end, locked})
  }

  consolidate() {
    this.sort()

    const consolidatedBlocks = []
    consolidatedBlocks.last = function () {
      return this[this.length - 1]
    }

    this.blocks.forEach(block => {
      if (!consolidatedBlocks.last()) {
        consolidatedBlocks.push(block)
        return
      }

      const lastBlock = consolidatedBlocks.last()
      if (+lastBlock.end === +block.start && !lastBlock.locked && !block.locked) {
        lastBlock.end = block.end
      } else {
        consolidatedBlocks.push(block)
      }
    })

    return (this.blocks = consolidatedBlocks)
  }

  // split each block into multiple blocks of the given length
  split(minutes) {
    this.consolidate()

    this.blocks.forEach(block => {
      if (block.locked) return
      const nextBreak = fcUtil.clone(block.start).add(minutes, 'minutes')
      while (block.end > nextBreak) {
        this.add(block.start, fcUtil.clone(nextBreak))
        block.start = fcUtil.clone(nextBreak)
        nextBreak.add(minutes, 'minutes')
      }
    })

    return this.sort()
  }

  sort() {
    return (this.blocks = this.blocks.sort((a, b) => {
      if (a.end <= b.start) {
        return -1
      } else {
        return 1
      }
    }))
  }

  delete(index) {
    if (index != null && this.blocks.length > index && !this.blocks[index].locked) {
      return this.blocks.splice(index, 1)
    }
  }

  reset() {
    return (this.blocks = [])
  }
}

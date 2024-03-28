/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {useState} from 'react'
import FindReplaceTray from './FindReplaceTray'
import {SearchReplacePlugin} from '../types'
import {UndoManager} from 'tinymce'

type FindReplaceTrayControllerProps = {
  plugin: SearchReplacePlugin
  onDismiss: () => void
  initialText?: string
  undoManager?: UndoManager
}

export default function FindReplaceTrayController({
  plugin,
  onDismiss,
  initialText = '',
  undoManager,
}: FindReplaceTrayControllerProps) {
  // this component really just exists to make the index easier to track
  const [findIndex, setFindIndex] = useState(0)
  const [findCount, setFindCount] = useState(0)

  const newFindIndex = (direction: 1 | -1) => {
    let newIndex = 0
    if (findCount === 0) {
      newIndex = 0
    } else if (direction === 1) {
      // at max count, wrap back to 1
      if (findIndex === findCount) {
        newIndex = 1
      } else newIndex = findIndex + 1
    } else if (direction === -1) {
      // at 1, wrap back to max
      if (findIndex === 1) {
        newIndex = findCount
      } else newIndex = findIndex - 1
    }
    return newIndex
  }

  const done = () => {
    plugin.done(false)
    setFindCount(0)
    setFindIndex(0)
  }

  const handleDismiss = () => {
    done()
    onDismiss()
  }

  const handleNext = () => {
    plugin.next()
    setFindIndex(newFindIndex(1))
  }

  const handlePrevious = () => {
    plugin.prev()
    setFindIndex(newFindIndex(-1))
  }

  const handleFind = (text: string) => {
    if (!text) {
      done()
    } else {
      const count = plugin.find(text)
      setFindCount(count)
      const index = count ? 1 : 0
      setFindIndex(index)
    }
  }

  const handleReplace = (text: string, forward = true, all = false) => {
    if (!text) return
    undoManager?.add()
    plugin.replace(text, forward, all)
    if (findCount === 1 || all) {
      done()
      return
    }
    // we can't just find again, because that will reset index to 1
    let newIndex
    const newFindCount = findCount - 1
    if (forward) {
      newIndex = findIndex === findCount ? 1 : findIndex
    } else {
      newIndex = findIndex === 1 ? newFindCount : findIndex - 1
    }
    setFindCount(newFindCount)
    setFindIndex(newIndex)
  }

  return (
    <FindReplaceTray
      onRequestClose={handleDismiss}
      onNext={handleNext}
      onPrevious={handlePrevious}
      onFind={handleFind}
      onReplace={handleReplace}
      index={findIndex}
      max={findCount}
      initialText={initialText}
    />
  )
}

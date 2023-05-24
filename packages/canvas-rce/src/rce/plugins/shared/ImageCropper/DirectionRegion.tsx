/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import formatMessage from '../../../../format-message'

export enum Direction {
  LEFT = 37,
  UP = 38,
  RIGHT = 39,
  DOWN = 40,
  NONE = 0,
}

const directionToWord = (direction: Direction): String | null => {
  switch (direction) {
    case Direction.LEFT:
      return formatMessage('Left')
    case Direction.UP:
      return formatMessage('Up')
    case Direction.RIGHT:
      return formatMessage('Right')
    case Direction.DOWN:
      return formatMessage('Down')
    case Direction.NONE:
      return null
  }
}

type ComponentProps = {
  readonly direction: Direction
}

export const DirectionRegion = ({direction}: ComponentProps) => {
  const directionWord = directionToWord(direction)
  const directionMessage = directionWord
    ? formatMessage('Moving image to crop {directionWord}', {directionWord})
    : ''
  return (
    <ScreenReaderContent aria-live="assertive" aria-relevant="all">
      {directionMessage}
    </ScreenReaderContent>
  )
}

/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {
  IconCompleteSolid,
  IconTroubleSolid,
  IconWarningSolid,
  IconLikeSolid,
  IconLikeLine,
} from '@instructure/ui-icons'
import {canvas} from '@instructure/ui-themes'
import {IconButton} from '@instructure/ui-buttons'

const honeyInstUI10 = '#B07E00'

export const getStatusByRelevance = (relevance: string) => {
  if (relevance === 'needs_review') {
    return <IconWarningSolid style={{fill: honeyInstUI10}} />
  } else {
    if (relevance === 'relevant') {
      return <IconCompleteSolid style={{fill: canvas.colors.contrasts.green5782}} />
    } else {
      return <IconTroubleSolid style={{fill: canvas.colors.contrasts.red5782}} />
    }
  }
}

export const formatDate = (date: Date) => {
  const locale = ENV?.LOCALES?.[0] ?? 'en-US'
  return date.toLocaleString(locale, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    hour12: true,
  })
}

type RatingButtonProps = {
  type: 'like' | 'dislike'
  disabled: boolean
  isActive: boolean
  onClick: () => void
  screenReaderText: string
  dataTestId: string
}

export const RatingButton: React.FC<RatingButtonProps> = ({
  type,
  disabled,
  isActive,
  onClick,
  screenReaderText,
  dataTestId,
}) => {
  const rotate = type === 'like' ? '0' : '180'

  return (
    <IconButton
      onClick={onClick}
      size="small"
      withBackground={false}
      withBorder={false}
      screenReaderLabel={screenReaderText}
      data-testid={dataTestId}
      disabled={disabled}
    >
      {isActive ? <IconLikeSolid rotate={rotate} /> : <IconLikeLine rotate={rotate} />}
    </IconButton>
  )
}

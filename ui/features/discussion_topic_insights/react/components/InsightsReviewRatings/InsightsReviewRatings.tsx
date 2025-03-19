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
import React, {useState} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {IconLikeLine, IconLikeSolid} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discussion_insights')

type RatingButtonProps = {
  type: 'like' | 'dislike'
  isActive: boolean
  onClick: () => void
  screenReaderText: string
  dataTestId: string
}

const RatingButton: React.FC<RatingButtonProps> = ({
  type,
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
    >
      {isActive ? <IconLikeSolid rotate={rotate} /> : <IconLikeLine rotate={rotate} />}
    </IconButton>
  )
}

const InsightsReviewRatings = () => {
  const [liked, setLiked] = useState(false)
  const [disliked, setDisliked] = useState(false)

  const handleLikeClick = () => {
    setLiked(!liked)
    setDisliked(false)
  }
  const handleDislikeClick = () => {
    setDisliked(!disliked)
    setLiked(false)
  }

  return (
    <>
      <RatingButton
        type="like"
        isActive={liked}
        onClick={handleLikeClick}
        screenReaderText={I18n.t('Like review')}
        dataTestId="insights-like-button"
      />
      <RatingButton
        type="dislike"
        isActive={disliked}
        onClick={handleDislikeClick}
        screenReaderText={I18n.t('Dislike review')}
        dataTestId="insights-dislike-button"
      />
    </>
  )
}

export default InsightsReviewRatings

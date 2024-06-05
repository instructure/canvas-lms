/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconLikeLine, IconLikeSolid} from '@instructure/ui-icons'

interface RatingButtonProps {
  action: 'like' | 'dislike'
  isActive: boolean
  isEnabled: boolean
  onClick: () => void
  screenReaderText: string
  dataTestId: string
}

const I18n = useI18nScope('discussion_posts')

const RatingButton: React.FC<RatingButtonProps> = ({
  action,
  isActive,
  isEnabled,
  onClick,
  screenReaderText,
  dataTestId,
}) => {
  const rotate = action === 'like' ? '0' : '180'

  return (
    <IconButton
      onClick={onClick}
      size="small"
      withBackground={false}
      withBorder={false}
      color={isActive ? 'primary' : 'secondary'}
      screenReaderLabel={screenReaderText}
      interaction={isEnabled ? 'enabled' : 'disabled'}
      data-testid={dataTestId}
    >
      {isActive ? <IconLikeSolid rotate={rotate} /> : <IconLikeLine rotate={rotate} />}
    </IconButton>
  )
}

interface DiscussionSummaryRatingsProps {
  onLikeClick: () => void
  onDislikeClick: () => void
  liked?: boolean
  disliked?: boolean
  isEnabled: boolean
}

export const DiscussionSummaryRatings: React.FC<DiscussionSummaryRatingsProps> = props => {
  return (
    <>
      <RatingButton
        action="like"
        isActive={props.liked}
        isEnabled={props.isEnabled}
        onClick={props.onLikeClick}
        screenReaderText={I18n.t('Like summary')}
        dataTestId="summary-like-button"
      />
      <RatingButton
        action="dislike"
        isActive={props.disliked}
        isEnabled={props.isEnabled}
        onClick={props.onDislikeClick}
        screenReaderText={I18n.t('Dislike summary')}
        dataTestId="summary-dislike-button"
      />
    </>
  )
}

export default DiscussionSummaryRatings

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

import React, {useContext} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconLikeLine, IconLikeSolid} from '@instructure/ui-icons'
import { Text } from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

interface RatingButtonProps {
  action: 'like' | 'dislike'
  isActive: boolean
  isEnabled: boolean
  onClick: () => void
  screenReaderText: string
  dataTestId: string
}

const I18n = createI18nScope('discussion_posts')

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
  const {setOnSuccess} = useContext(AlertManagerContext)
  return (
    <Flex>
      {props.liked || props.disliked ? (
        <Flex.Item margin="0 small 0 0"><Text color="secondary" size="small">{I18n.t('Thank you for sharing!')}</Text></Flex.Item>
      ) : (
        <Flex.Item margin="0 small 0 0"><Text color="secondary" size="small">{I18n.t('Do you like this summary?')}</Text></Flex.Item>
      )}
      <RatingButton
        action="like"
        // @ts-expect-error
        isActive={props.liked}
        isEnabled={props.isEnabled}
        onClick={() => {
          if(props.liked) {
            setOnSuccess(I18n.t('Like summary, deselected'))
          } else {
            setOnSuccess(I18n.t('Like summary, selected'))
          }
          props.onLikeClick()
        }}
        screenReaderText={ props.liked ? I18n.t('Like summary, selected') : I18n.t('Like summary')}
        dataTestId="summary-like-button"
      />
      <RatingButton
        action="dislike"
        // @ts-expect-error
        isActive={props.disliked}
        isEnabled={props.isEnabled}
        onClick={() => {
          if(props.disliked) {
            setOnSuccess(I18n.t('Dislike summary, deselected'))
          } else {
            setOnSuccess(I18n.t('Dislike summary, selected'))
          }
          props.onDislikeClick()
        }}
        screenReaderText={ props.disliked ? I18n.t('Dislike summary, selected') : I18n.t('Dislike summary')}
        dataTestId="summary-dislike-button"
      />
    </Flex>
  )
}

export default DiscussionSummaryRatings

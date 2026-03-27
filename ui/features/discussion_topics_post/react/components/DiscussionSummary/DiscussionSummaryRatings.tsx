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

import React, {useContext, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconLikeLine, IconLikeSolid} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
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
  onSubmitFeedbackComment?: (comment: string) => Promise<void> | void
  liked?: boolean
  disliked?: boolean
  isEnabled: boolean
}

export const DiscussionSummaryRatings: React.FC<DiscussionSummaryRatingsProps> = props => {
  const {setOnSuccess} = useContext(AlertManagerContext)
  const [feedbackComment, setFeedbackComment] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleDislikeClick = () => {
    if (props.disliked) {
      setOnSuccess(I18n.t('Dislike summary, deselected'))
      setFeedbackComment(null)
    } else {
      setOnSuccess(I18n.t('Dislike summary, selected'))
      setFeedbackComment('')
    }
    props.onDislikeClick()
  }

  const handleSubmitComment = async () => {
    if (!feedbackComment?.trim() || !props.onSubmitFeedbackComment) {
      setFeedbackComment(null)
      return
    }
    setIsSubmitting(true)
    await props.onSubmitFeedbackComment(feedbackComment.trim())
    setIsSubmitting(false)
    setOnSuccess(I18n.t('Feedback submitted. Thank you!'))
    setFeedbackComment(null)
  }

  return (
    <Flex direction="column">
      <Flex justifyItems="end">
        {props.liked || props.disliked ? (
          <Flex.Item margin="0 small 0 0">
            <Text color="secondary" size="small">
              {I18n.t('Thank you for sharing!')}
            </Text>
          </Flex.Item>
        ) : (
          <Flex.Item margin="0 small 0 0">
            <Text color="secondary" size="small">
              {I18n.t('Do you like this summary?')}
            </Text>
          </Flex.Item>
        )}
        <RatingButton
          action="like"
          isActive={!!props.liked}
          isEnabled={props.isEnabled}
          onClick={() => {
            if (props.liked) {
              setOnSuccess(I18n.t('Like summary, deselected'))
            } else {
              setOnSuccess(I18n.t('Like summary, selected'))
            }
            setFeedbackComment(null)
            props.onLikeClick()
          }}
          screenReaderText={props.liked ? I18n.t('Like summary, selected') : I18n.t('Like summary')}
          dataTestId="summary-like-button"
        />
        <RatingButton
          action="dislike"
          isActive={!!props.disliked}
          isEnabled={props.isEnabled}
          onClick={handleDislikeClick}
          screenReaderText={
            props.disliked ? I18n.t('Dislike summary, selected') : I18n.t('Dislike summary')
          }
          dataTestId="summary-dislike-button"
        />
      </Flex>
      {props.disliked && feedbackComment !== null && (
        <Flex direction="column" gap="medium" margin="medium 0 0 0">
          <Text size="small">
            {I18n.t('Can you please explain why you disapprove of the summary?')}
          </Text>
          <Flex gap="small" alignItems="end">
            <Flex.Item shouldGrow={true}>
              <TextInput
                renderLabel={I18n.t('Explanation')}
                value={feedbackComment}
                onChange={(_e, value) => setFeedbackComment(value)}
                placeholder={I18n.t('Start typing...')}
                data-testid="summary-feedback-comment"
              />
            </Flex.Item>
            <Flex.Item>
              <Button
                color="secondary"
                onClick={handleSubmitComment}
                interaction={
                  props.isEnabled && feedbackComment?.trim() && !isSubmitting
                    ? 'enabled'
                    : 'disabled'
                }
                aria-busy={isSubmitting}
                data-testid="summary-feedback-submit"
              >
                {isSubmitting ? (
                  <Flex gap="x-small">
                    <Spinner size="x-small" renderTitle={I18n.t('Sending feedback')} />
                    <Text>{I18n.t('Sending...')}</Text>
                  </Flex>
                ) : (
                  I18n.t('Send Feedback')
                )}
              </Button>
            </Flex.Item>
          </Flex>
        </Flex>
      )}
    </Flex>
  )
}

export default DiscussionSummaryRatings

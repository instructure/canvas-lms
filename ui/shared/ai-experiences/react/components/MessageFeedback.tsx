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

import React, {useState, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {Alert} from '@instructure/ui-alerts'
import {IconLikeLine, IconLikeSolid} from '@instructure/ui-icons'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {FeedbackItem} from '../../types'
import {navyButtonTheme, navyPillButtonTheme, RADIUS_PILL} from '../brand'

const I18n = createI18nScope('ai_experiences')

const activeVoteButtonTheme = navyPillButtonTheme
const inactiveVoteButtonTheme = {borderRadius: RADIUS_PILL}
const submitButtonTheme = navyButtonTheme

interface MessageFeedbackProps {
  messageId: string
  initialFeedback: FeedbackItem[]
  courseId: string | number
  aiExperienceId: string
  conversationId: string
}

type UiState = 'idle' | 'dislike-form' | 'submitted'

interface FeedbackResponse {
  feedback: FeedbackItem
}

const MessageFeedback = ({
  messageId,
  initialFeedback,
  courseId,
  aiExperienceId,
  conversationId,
}: MessageFeedbackProps) => {
  const [feedback, setFeedback] = useState<FeedbackItem | null>(initialFeedback[0] ?? null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [uiState, setUiState] = useState<UiState>('idle')
  const [feedbackText, setFeedbackText] = useState('')
  const [error, setError] = useState<string | null>(null)
  const formRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    if (uiState === 'dislike-form') {
      formRef.current?.scrollIntoView({behavior: 'smooth', block: 'nearest'})
    }
  }, [uiState])

  const feedbackBasePath = `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/conversations/${conversationId}/messages/${messageId}/feedback`

  const postFeedback = async (vote: 'liked' | 'disliked', message?: string) => {
    setIsSubmitting(true)
    setError(null)
    try {
      if (feedback) {
        await doFetchApi({
          path: `${feedbackBasePath}/${feedback.id}`,
          method: 'DELETE',
        })
      }

      const body: Record<string, string> = {vote}
      if (message) body.feedback_message = message

      const {json} = await doFetchApi<FeedbackResponse>({
        path: feedbackBasePath,
        method: 'POST',
        body,
      })
      if (json?.feedback) setFeedback(json.feedback)
    } catch {
      setError(I18n.t('Failed to save feedback. Please try again.'))
      throw new Error('feedback_failed')
    } finally {
      setIsSubmitting(false)
    }
  }

  const removeFeedback = async () => {
    if (!feedback) return
    setIsSubmitting(true)
    setError(null)
    try {
      await doFetchApi({
        path: `${feedbackBasePath}/${feedback.id}`,
        method: 'DELETE',
      })
      setFeedback(null)
    } catch {
      setError(I18n.t('Failed to remove feedback. Please try again.'))
      throw new Error('feedback_failed')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleLike = async () => {
    try {
      if (feedback?.vote === 'liked') {
        await removeFeedback()
      } else {
        await postFeedback('liked')
      }
    } catch {
      // error state already set in postFeedback/removeFeedback
    }
  }

  const handleDislike = async () => {
    if (feedback?.vote === 'disliked') {
      try {
        await removeFeedback()
        setUiState('idle')
      } catch {
        // error state already set in removeFeedback
      }
    } else {
      setUiState('dislike-form')
    }
  }

  const handleSkip = async () => {
    try {
      await postFeedback('disliked')
      setUiState('idle')
    } catch {
      // error state already set in postFeedback
    }
  }

  const handleSubmit = async () => {
    try {
      await postFeedback('disliked', feedbackText)
      setUiState('submitted')
    } catch {
      // error state already set in postFeedback
    }
  }

  const isLiked = feedback?.vote === 'liked'
  const isDisliked = feedback?.vote === 'disliked'
  const buttonInteraction = isSubmitting ? ('disabled' as const) : ('enabled' as const)
  const submitInteraction =
    isSubmitting || !feedbackText.trim() ? ('disabled' as const) : ('enabled' as const)

  return (
    <View as="div" margin="xx-small 0 0 0">
      <Flex gap="x-small" alignItems="center">
        <IconButton
          size="small"
          withBackground={isLiked}
          withBorder={true}
          color={isLiked ? 'primary' : 'secondary'}
          screenReaderLabel={I18n.t('Like this response')}
          onClick={handleLike}
          interaction={buttonInteraction}
          data-testid="message-feedback-like"
          themeOverride={isLiked ? activeVoteButtonTheme : inactiveVoteButtonTheme}
        >
          {isLiked ? <IconLikeSolid /> : <IconLikeLine />}
        </IconButton>
        <span style={{display: 'inline-block', transform: 'rotate(180deg)'}}>
          <IconButton
            size="small"
            withBackground={isDisliked}
            withBorder={true}
            color={isDisliked ? 'primary' : 'secondary'}
            screenReaderLabel={I18n.t('Dislike this response')}
            onClick={handleDislike}
            interaction={buttonInteraction}
            data-testid="message-feedback-dislike"
            themeOverride={isDisliked ? activeVoteButtonTheme : inactiveVoteButtonTheme}
          >
            {isDisliked ? <IconLikeSolid /> : <IconLikeLine />}
          </IconButton>
        </span>
      </Flex>

      {error && (
        <Alert
          variant="error"
          margin="x-small 0 0 0"
          renderCloseButtonLabel={I18n.t('Close')}
          onDismiss={() => setError(null)}
          data-testid="message-feedback-error"
        >
          {error}
        </Alert>
      )}

      {uiState === 'dislike-form' && (
        <View
          as="div"
          margin="x-small 0 0 0"
          padding="small"
          borderWidth="small"
          borderRadius="medium"
          background="primary"
          elementRef={el => {
            formRef.current = el as HTMLDivElement | null
          }}
        >
          <TextArea
            label={I18n.t('What was the issue?')}
            value={feedbackText}
            onChange={e => setFeedbackText(e.target.value)}
            height="80px"
            disabled={isSubmitting}
            data-testid="message-feedback-text"
          />
          <View as="div" margin="x-small 0 small 0">
            <Text size="small" color="secondary">
              {I18n.t('For example: Inappropriate, irrelevant, etc.')}
            </Text>
          </View>
          <Flex alignItems="center" justifyItems="space-between">
            <Flex.Item shouldGrow shouldShrink>
              <Text size="small">
                {I18n.t(
                  'By submitting this report, you agree to share your current conversation to Instructure for improvements.',
                )}
              </Text>
            </Flex.Item>
            <Flex.Item>
              <Flex gap="small">
                <Button
                  interaction={buttonInteraction}
                  onClick={handleSkip}
                  data-testid="message-feedback-skip"
                >
                  {I18n.t('Skip')}
                </Button>
                <Button
                  color="primary"
                  interaction={submitInteraction}
                  onClick={handleSubmit}
                  data-testid="message-feedback-submit"
                  themeOverride={submitButtonTheme}
                >
                  {I18n.t('Submit')}
                </Button>
              </Flex>
            </Flex.Item>
          </Flex>
        </View>
      )}

      {uiState === 'submitted' && (
        <View
          as="div"
          margin="x-small 0 0 0"
          padding="small"
          borderWidth="small"
          borderRadius="medium"
          background="primary"
          data-testid="message-feedback-success"
        >
          <Text>{I18n.t('Feedback submitted.')}</Text>
        </View>
      )}
    </View>
  )
}

export default MessageFeedback

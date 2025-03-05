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

import React, {useState, useEffect, useCallback} from 'react'
import type {Dispatch, SetStateAction} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Spinner} from '@instructure/ui-spinner'
import {DiscussionSummaryRatings} from './DiscussionSummaryRatings'
import {DiscussionSummaryGenerateButton} from './DiscussionSummaryGenerateButton'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconEndLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'

export interface DiscussionSummaryProps {
  onDisableSummaryClick: () => void
  isMobile: boolean
  summary: {id: number; text: string} | null
  onSetSummary: Dispatch<SetStateAction<{id: number; text: string} | null>>
  isFeedbackLoading: boolean
  onSetIsFeedbackLoading: (isFeedbackLoading: boolean) => void
  liked: boolean
  onSetLiked: (liked: boolean) => void
  disliked: boolean
  onSetDisliked: (disliked: boolean) => void
  postDiscussionSummaryFeedback: (action: string) => Promise<void>
}

const I18n = createI18nScope('discussion_posts')

export const DiscussionSummary: React.FC<DiscussionSummaryProps> = props => {
  const [previousUserInput, setPreviousUserInput] = useState('')
  const [userInput, setUserInput] = useState('')
  const [summaryError, setSummaryError] = useState<string | null>(null)
  const [isSummaryLoading, setIsSummaryLoading] = useState(props.summary === null)

  // @ts-expect-error
  const contextType = ENV.context_type.toLowerCase()
  // @ts-expect-error
  const contextId = ENV.context_id
  // @ts-expect-error
  const apiUrlPrefix = `/api/v1/${contextType}s/${contextId}/discussion_topics/${ENV.discussion_topic_id}`

  const likeAction = props.liked ? 'reset_like' : 'like'
  const dislikeAction = props.disliked ? 'reset_like' : 'dislike'

  const resetState = () => {
    props.onSetSummary(null)
    setSummaryError(null)
    props.onSetLiked(false)
    props.onSetDisliked(false)
  }

  const generateSummary = async () => {
    setIsSummaryLoading(true)
  }

  const getDiscussionSummary = useCallback(async () => {
    const {json} = await doFetchApi({
      method: 'GET',
      path: `${apiUrlPrefix}/summaries`,
      params: {userInput},
    })
    return json
  }, [isSummaryLoading]) // eslint-disable-line react-hooks/exhaustive-deps

  const fetchSummary = useCallback(async () => {
    try {
      // @ts-expect-error
      props.onSetSummary(await getDiscussionSummary())
      setPreviousUserInput(userInput)
    } catch (error: any) {
      let errorMessage = 'An unexpected error occurred while loading the discussion summary.'

      try {
        const response = await error.response?.json()
        errorMessage = response?.error || errorMessage
      } catch {} // eslint-disable-line no-empty

      setSummaryError(errorMessage)
      setPreviousUserInput('')
    }

    setIsSummaryLoading(false)
  }, [isSummaryLoading]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (!isSummaryLoading) {
      return
    }

    resetState()
    fetchSummary()
  }, [isSummaryLoading]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (props.summary === null) {
      return
    }

    props.postDiscussionSummaryFeedback('seen')
  }, [props.summary]) // eslint-disable-line react-hooks/exhaustive-deps

  let content = null

  if (summaryError) {
    content = (
      <Flex.Item margin={props.isMobile ? '0 0 medium 0' : '0 0 small 0'}>
        <Text color="danger" data-testid="summary-error">
          {summaryError}
        </Text>
      </Flex.Item>
    )
  } else if (props.summary === null) {
    content = (
      <Flex justifyItems="start" margin="small 0">
        <Flex.Item>
          <Spinner renderTitle={I18n.t('Loading discussion summary')} size="x-small" />
        </Flex.Item>
        <Flex.Item margin="0 0 0 x-small">
          <Text data-testid="summary-loading">{I18n.t('Loading discussion summary...')}</Text>
        </Flex.Item>
      </Flex>
    )
  } else {
    content = (
      <>
        <Flex.Item margin={props.isMobile ? '0 0 mediumSmall 0' : '0 0 small 0'}>
          <Text fontStyle="italic" size="medium" weight="normal" data-testid="summary-text">
            {props.summary?.text?.split('\n').map((line, index) => (
              <React.Fragment key={index}>
                {line}
                <br />
              </React.Fragment>
            ))}
          </Text>
        </Flex.Item>
        <Flex.Item margin="0 0 medium 0" align="end">
          <DiscussionSummaryRatings
            liked={props.liked}
            disliked={props.disliked}
            onLikeClick={() => props.postDiscussionSummaryFeedback(likeAction)}
            onDislikeClick={() => props.postDiscussionSummaryFeedback(dislikeAction)}
            isEnabled={!props.isFeedbackLoading}
          />
        </Flex.Item>
      </>
    )
  }

  return (
    <Flex direction="column">
      <Flex.Item overflowX='hidden' margin={props.isMobile ? '0 0 x-small 0' : 'medium 0 x-small 0'}>
        <Text size="large" weight="bold">
          {I18n.t('Discussion Summary')}
        </Text>
        <span style={{float: 'right'}}>
          <IconButton
            size="small"
            onClick={props.onDisableSummaryClick}
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Turn off summary')}
            data-testid="summary-disable-icon-button"
          >
            <IconEndLine />
          </IconButton>
        </span>
      </Flex.Item>
      <Flex.Item margin="0 0 medium 0">
        <Text size="small" weight="normal" color="secondary">
          {I18n.t(
            'This summary is generated by AI and reflects the latest contributions to the discussion. Please note that the output may not always be accurate. Summaries are only visible to instructors.',
          )}
        </Text>
      </Flex.Item>
      <Flex gap="small" wrap="wrap" margin="medium 0" alignItems='end'>
        <Flex.Item width={props.isMobile ? '100%' : 'auto'} shouldGrow={true}>
          <TextInput
            renderLabel={I18n.t('Topics to focus on')}
            placeholder={I18n.t('Enter the areas or topics you want the summary to focus on')}
            onChange={(event, value) => {
              setUserInput(value)
            }}
            maxLength={255}
            data-testid="summary-user-input"
          />
        </Flex.Item>
        <Flex.Item width={props.isMobile ? '100%' : 'auto'}>
          <DiscussionSummaryGenerateButton
            onClick={generateSummary}
            isEnabled={!isSummaryLoading && !props.isFeedbackLoading && userInput !== previousUserInput}
            isMobile={props.isMobile}
          />
        </Flex.Item>
      </Flex>
      <Flex.Item margin="0 0 x-small 0">
        <Text size="small" weight="normal" color="secondary">
          {I18n.t('Generated Summary')}
        </Text>
      </Flex.Item>
      {content}
    </Flex>
  )
}

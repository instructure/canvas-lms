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

import React, {useContext, useState, useEffect, useCallback} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {DiscussionSummaryRatings} from './DiscussionSummaryRatings'
import {DiscussionSummaryRegenerateButton} from './DiscussionSummaryRegenerateButton'
import {DiscussionSummaryDisableButton} from './DiscussionSummaryDisableButton'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'

interface DiscussionSummaryProps {
  onDisableSummaryClick: () => void
  showButtonText: boolean
}

const I18n = useI18nScope('discussion_posts')

export const DiscussionSummary: React.FC<DiscussionSummaryProps> = props => {
  const {setOnFailure} = useContext(AlertManagerContext)
  const [summary, setSummary] = useState<{id: number; text: string} | null>(null)
  const [summaryError, setSummaryError] = useState<string | null>(null)
  const [shouldForceRegenerate, setShouldForceRegenerate] = useState<boolean | null>(false)
  const [liked, setLiked] = useState<boolean>(false)
  const [disliked, setDisliked] = useState<boolean>(false)
  const [isFeedbackLoading, setIsFeedbackLoading] = useState(false)

  const contextType = ENV.context_type.toLowerCase()
  const contextId = ENV.context_id
  const apiUrlPrefix = `/api/v1/${contextType}s/${contextId}/discussion_topics/${ENV.discussion_topic_id}`

  const likeAction = liked ? 'reset_like' : 'like'
  const dislikeAction = disliked ? 'reset_like' : 'dislike'

  const postDiscussionSummaryFeedback = useCallback(
    async (action: string) => {
      setIsFeedbackLoading(true)

      try {
        const {json} = await doFetchApi({
          method: 'POST',
          path: `${apiUrlPrefix}/summaries/${summary!.id}/feedback`,
          body: {
            _action: action,
          },
        })
        setLiked(json.liked)
        setDisliked(json.disliked)
      } catch (error) {
        setOnFailure(
          I18n.t('There was an unexpected error while submitting the discussion summary feedback.')
        )
      }

      setIsFeedbackLoading(false)
    },
    [apiUrlPrefix, summary, setOnFailure]
  )

  const resetState = () => {
    setSummary(null)
    setSummaryError(null)
    setLiked(false)
    setDisliked(false)
  }

  const regenerateSummary = async () => {
    if (summary) {
      await postDiscussionSummaryFeedback('regenerate')
    }

    setShouldForceRegenerate(true)
  }

  const disableSummary = async () => {
    if (summary) {
      await postDiscussionSummaryFeedback('disable_summary')
    }

    try {
      await doFetchApi({
        method: 'PUT',
        path: `${apiUrlPrefix}/summaries/disable`,
      })
    } catch (error) {
      setOnFailure(I18n.t('There was an unexpected error while disabling the discussion summary.'))
      return
    }

    props.onDisableSummaryClick()
  }

  const getDiscussionSummary = useCallback(async () => {
    const {json} = await doFetchApi({
      method: 'GET',
      path: `${apiUrlPrefix}/summaries`,
      params: shouldForceRegenerate ? {force: true} : undefined,
    })
    return json
  }, [shouldForceRegenerate]) // eslint-disable-line react-hooks/exhaustive-deps

  const fetchSummary = useCallback(async () => {
    try {
      setSummary(await getDiscussionSummary())
    } catch (error: any) {
      let errorMessage = 'An unexpected error occurred while loading the discussion summary.'

      try {
        const response = await error.response?.json()
        errorMessage = response?.error || errorMessage
      } catch {} // eslint-disable-line no-empty

      setSummaryError(errorMessage)
    }

    setShouldForceRegenerate(null)
  }, [shouldForceRegenerate]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (shouldForceRegenerate === null) {
      return
    }

    resetState()
    fetchSummary()
  }, [shouldForceRegenerate]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (summary === null) {
      return
    }

    postDiscussionSummaryFeedback('seen')
  }, [summary]) // eslint-disable-line react-hooks/exhaustive-deps

  if (summaryError) {
    return (
      <Flex direction="column">
        <Text color="danger" data-testid="summary-error">
          {summaryError}
        </Text>
        <Flex margin="small 0">
          <Flex.Item margin="0 small 0 0">
            <DiscussionSummaryRegenerateButton
              onClick={regenerateSummary}
              isEnabled={!isFeedbackLoading}
              buttonText={I18n.t('Retry')}
              showText={props.showButtonText}
            />
          </Flex.Item>
          <Flex.Item margin="0 small 0 0">
            <DiscussionSummaryDisableButton
              onClick={disableSummary}
              isEnabled={!isFeedbackLoading}
              showText={props.showButtonText}
            />
          </Flex.Item>
        </Flex>
      </Flex>
    )
  } else if (summary === null) {
    return (
      <Flex justifyItems="start">
        <Flex.Item>
          <Spinner renderTitle={I18n.t('Loading discussion summary')} size="x-small" />
        </Flex.Item>
        <Flex.Item margin="0 0 0 x-small">
          <Text data-testid="summary-loading">{I18n.t('Loading discussion summary...')}</Text>
        </Flex.Item>
      </Flex>
    )
  } else {
    /* eslint-disable react/no-array-index-key */
    return (
      <Flex direction="column" justifyItems="start">
        <Flex.Item>
          <Text weight="bold">{I18n.t('Discussion summary')}</Text>
        </Flex.Item>
        <Flex.Item>
          <Text fontStyle="italic" data-testid="summary-text">
            {summary.text.split('\n').map((line, index) => (
              <React.Fragment key={index}>
                {line}
                <br />
              </React.Fragment>
            ))}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Text size="x-small" color="secondary">
            {I18n.t(
              'This summary is generated by AI, and is up-to-date with the latest contributions to the discussion. Summaries are only visible to instructors.'
            )}
          </Text>
        </Flex.Item>
        <Flex margin="small 0">
          <Flex.Item>
            <DiscussionSummaryRatings
              liked={liked}
              disliked={disliked}
              onLikeClick={() => postDiscussionSummaryFeedback(likeAction)}
              onDislikeClick={() => postDiscussionSummaryFeedback(dislikeAction)}
              isEnabled={!isFeedbackLoading}
            />
          </Flex.Item>
          <Flex.Item margin="0 0 0 small">
            <DiscussionSummaryRegenerateButton
              onClick={regenerateSummary}
              isEnabled={!isFeedbackLoading}
              buttonText={I18n.t('Try Another Summary')}
              showText={props.showButtonText}
            />
          </Flex.Item>
          <Flex.Item margin="0 0 0 small">
            <DiscussionSummaryDisableButton
              onClick={disableSummary}
              isEnabled={!isFeedbackLoading}
              showText={props.showButtonText}
            />
          </Flex.Item>
        </Flex>
      </Flex>
    )
    /* eslint-enable react/no-array-index-key */
  }
}

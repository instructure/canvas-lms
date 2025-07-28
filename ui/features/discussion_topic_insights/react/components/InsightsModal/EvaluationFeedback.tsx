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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {getStatusByRelevance, RatingButton} from '../../utils'
import {Text} from '@instructure/ui-text'
import {useUpdateEntry} from '../../hooks/useUpdateEntry'

const I18n = createI18nScope('discussion_insights')

type EvaluationFeedbackProps = {
  relevance: string
  relevanceNotes: string
  entryId: number
  feedback: boolean | null
}

const EvaluationFeedback: React.FC<EvaluationFeedbackProps> = ({
  relevance,
  relevanceNotes,
  entryId,
  feedback,
}) => {
  const {loading, updateEntry} = useUpdateEntry()

  const handleFeedbackChange = (newFeedback: boolean) => {
    if (feedback === newFeedback) {
      updateEntry({
        entryId,
        entryFeedback: {
          action: 'reset_like',
          notes: '',
        },
      })
      return
    }

    updateEntry({
      entryId,
      entryFeedback: {
        action: newFeedback ? 'like' : 'dislike',
      },
    })
  }

  const relevanceText = (relevance: string) => {
    if (relevance === 'needs_review') {
      return I18n.t('Needs Review')
    } else if (relevance === 'relevant') {
      return I18n.t('Relevant')
    } else {
      return I18n.t('Irrelevant')
    }
  }

  return (
    <Flex gap="mediumSmall" direction="column">
      <Flex.Item>
        <Text weight="bold" size="large">
          {I18n.t('Evaluation')}
        </Text>
      </Flex.Item>
      <Flex direction="column" gap="small">
        <Flex gap="small" direction="row">
          {getStatusByRelevance(relevance)}
          <Text weight="bold">{relevanceText(relevance)}</Text>
        </Flex>
        <Flex.Item>
          <Text fontStyle="italic">{relevanceNotes}</Text>
        </Flex.Item>
      </Flex>
      <Flex justifyItems="end">
        {feedback != null ? (
          <Flex.Item margin="0 small 0 0">
            <Text color="secondary" size="small">
              {I18n.t('Thank you for sharing!')}
            </Text>
          </Flex.Item>
        ) : (
          <Flex.Item margin="0 small 0 0">
            <Text color="secondary" size="small">
              {I18n.t('Do you like this evaluation?')}
            </Text>
          </Flex.Item>
        )}
        <RatingButton
          type="like"
          disabled={loading}
          isActive={!!feedback}
          onClick={() => handleFeedbackChange(true)}
          screenReaderText={I18n.t('Like review')}
          dataTestId="insights-like-modal-button"
        />
        <RatingButton
          type="dislike"
          disabled={loading}
          isActive={feedback === false}
          onClick={() => handleFeedbackChange(false)}
          screenReaderText={I18n.t('Dislike review')}
          dataTestId="insights-dislike-modal-button"
        />
      </Flex>
    </Flex>
  )
}

export default EvaluationFeedback

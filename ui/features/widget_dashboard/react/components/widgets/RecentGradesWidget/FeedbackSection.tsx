/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {TruncateText} from '@instructure/ui-truncate-text'
import type {SubmissionComment} from '../../../types'

const I18n = createI18nScope('widget_dashboard')

interface FeedbackSectionProps {
  comments: SubmissionComment[]
  submissionId: string
  totalCommentsCount: number
  assignmentUrl: string
}

export const FeedbackSection: React.FC<FeedbackSectionProps> = ({
  comments,
  submissionId,
  totalCommentsCount,
  assignmentUrl,
}) => {
  const feedbackUrl = `${assignmentUrl}?open_feedback=true`
  return (
    <View as="div" data-testid={`feedback-section-${submissionId}`}>
      <Flex direction="column">
        <Flex.Item>
          <Text weight="bold" size="large" data-testid={`feedback-section-heading-${submissionId}`}>
            {I18n.t('Feedback')}
          </Text>
        </Flex.Item>
        {comments.length === 0 && totalCommentsCount === 0 ? (
          <Flex.Item>
            <Text color="secondary" data-testid={`feedback-none-${submissionId}`}>
              {I18n.t('None')}
            </Text>
          </Flex.Item>
        ) : (
          <>
            {comments.map(comment => (
              <Flex.Item key={comment._id}>
                <View as="div" padding="xx-small 0">
                  <Flex direction="column">
                    {comment.author && (
                      <Flex.Item>
                        <Text
                          size="small"
                          weight="bold"
                          wrap="break-word"
                          data-testid={`feedback-author-${comment._id}`}
                        >
                          {comment.author.name}
                        </Text>
                      </Flex.Item>
                    )}
                    <Flex.Item>
                      <div data-testid={`feedback-comment-${comment._id}`}>
                        <TruncateText maxLines={3}>
                          <Text size="small">{comment.comment || ''}</Text>
                        </TruncateText>
                      </div>
                    </Flex.Item>
                  </Flex>
                </View>
              </Flex.Item>
            ))}
            {totalCommentsCount > 0 && (
              <Flex.Item padding="small 0 0 0" overflowY="visible">
                <Button
                  color="primary-inverse"
                  size="medium"
                  href={feedbackUrl}
                  data-testid={`view-inline-feedback-button-${submissionId}`}
                >
                  {I18n.t('View all inline feedback (%{count})', {count: totalCommentsCount})}
                </Button>
              </Flex.Item>
            )}
          </>
        )}
      </Flex>
    </View>
  )
}

/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {IconDiscussionLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import canvas from '@instructure/ui-themes'
import {SubmissionComment} from '../../../api.d'
import useStore from './stores'
import {Badge} from '@instructure/ui-badge'

const I18n = useI18nScope('grade_summary')

export type SubmissionAttemptsProps = {
  attempts: {
    [key: string]: SubmissionComment[]
  }
}

export default function SubmissionAttempts({attempts}: SubmissionAttemptsProps) {
  const assignmentUrl = useStore(state => state.submissionTrayAssignmentUrl)
  const [allAttemptCounts, setAllAttemptCounts] = useState<string[]>([])

  useEffect(() => {
    setAllAttemptCounts(Object.keys(attempts).sort((a, b) => (a > b ? -1 : 1)))
  }, [attempts])

  return (
    <>
      {allAttemptCounts?.map(attempt => (
        <View as="div" key={`comment-attempt-${attempt}`} padding="0 0 medium 0">
          <View as="div" background="secondary">
            <Flex as="div" justifyItems="space-between">
              <View as="div" margin="x-small small">
                <Text size="small" weight="bold" data-testid="submission-comment-attempt">
                  {I18n.t('Attempt %{attempt} Feedback:', {attempt})}
                </Text>
              </View>
              <IconButton
                size="small"
                color="primary"
                screenReaderLabel={I18n.t('See comments details')}
                margin="x-small medium"
                href={assignmentUrl}
              >
                <IconDiscussionLine />
              </IconButton>
            </Flex>
          </View>
          <SubmissionAttemptComments comments={attempts[attempt]} />
        </View>
      ))}
    </>
  )
}

type SubmissionAttemptProps = {
  comments?: SubmissionComment[]
}
function SubmissionAttemptComments({comments}: SubmissionAttemptProps) {
  const {borders, colors, spacing} = canvas.variables

  return (
    <>
      {comments?.map((comment, i) => (
        <Flex as="div" direction="column" key={comment.id} data-testid="submission-comment">
          <div
            style={{
              margin: `${spacing.small}`,
              ...(i > 0 && {
                borderTop: `${borders.widthSmall} solid ${colors.borderMedium}`,
                paddingTop: `${spacing.small}`,
              }),
            }}
          >
            <Text weight="bold" size="small">
              {I18n.t('%{display_updated_at}', {display_updated_at: comment.display_updated_at})}
            </Text>
            {!comment?.is_read && (
              <View
                as="span"
                position="absolute"
                insetInlineEnd="1.5rem"
                data-testid="submission-comment-unread"
              >
                <Badge type="notification" standalone={true} placement="end center" />
              </View>
            )}
          </div>
          <View as="div" margin="0 medium 0 small">
            <Text size="small">{I18n.t('%{comment}', {comment: comment.comment})}</Text>
          </View>
          <View as="div" textAlign="end" margin="0 medium 0 0">
            <Text weight="bold" size="small">
              - {I18n.t('%{display_name}', {display_name: comment?.author?.display_name})}
            </Text>
          </View>
        </Flex>
      ))}
    </>
  )
}

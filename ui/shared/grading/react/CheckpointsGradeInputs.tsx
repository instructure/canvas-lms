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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import DefaultGradeInput from '@canvas/grading/react/DefaultGradeInput'
import type {GradingType} from '../../../api'
import {useScope as createI18nScope} from '@canvas/i18n'

// The following are lean types to be used in this file only, to be TypeScript compliant
export type AssignmentCheckpoint = {
  tag: string
  submission_id: string
  points_possible: number
  entered_score?: number
}

export type Assignment = {
  grading_type: GradingType
  checkpoints: AssignmentCheckpoint[]
}

type Props = {
  assignment: Assignment
  canEdit: boolean
  onReplyToTopicSubmissionChange: (enteredScore: number) => void
  onReplyToEntrySubmissionChange: (enteredScore: number) => void
}

export const REPLY_TO_TOPIC = 'reply_to_topic'
export const REPLY_TO_ENTRY = 'reply_to_entry'

const I18n = createI18nScope('sharedSetDefaultGradeDialog')

export default function CheckpointsGradeInputs({
  assignment,
  canEdit = false,
  onReplyToTopicSubmissionChange = () => {},
  onReplyToEntrySubmissionChange = () => {},
}: Props) {
  const replyToTopicCheckpoint = assignment.checkpoints.find(cp => cp.tag === REPLY_TO_TOPIC)
  const replyToEntryCheckpoint = assignment.checkpoints.find(cp => cp.tag === REPLY_TO_ENTRY)

  const getPassFailScore = (value: string, checkpoint: AssignmentCheckpoint) => {
    // If the value is complete, then return the max points for checkpoint
    // Else return the min which is 0
    if (value === 'complete') {
      return checkpoint.points_possible
    } else {
      return 0
    }
  }

  const updateReplyToTopicSubmission = (enteredScore: string, isPassFail: boolean) => {
    if (!replyToTopicCheckpoint) {
      return
    }
    if (isPassFail) {
      onReplyToTopicSubmissionChange(getPassFailScore(enteredScore, replyToTopicCheckpoint))
    } else {
      onReplyToTopicSubmissionChange(Number(enteredScore))
    }
  }

  const updateReplyToEntrySubmission = (enteredScore: string, isPassFail: boolean) => {
    if (!replyToEntryCheckpoint) {
      return
    }
    if (isPassFail) {
      onReplyToEntrySubmissionChange(getPassFailScore(enteredScore, replyToEntryCheckpoint))
    } else {
      onReplyToEntrySubmissionChange(Number(enteredScore))
    }
  }

  // Complete submissions have scores equal to points possible
  const getPassFailValue = (pointsPossible: number, score: number) => {
    return score === pointsPossible ? 'complete' : 'incomplete'
  }

  const getDefaultValue = (checkpoint?: AssignmentCheckpoint) => {
    if (!checkpoint) {
      return ''
    }

    if (assignment.grading_type === 'pass_fail') {
      return getPassFailValue(checkpoint.points_possible, checkpoint.entered_score || 0)
    }

    return checkpoint.entered_score ? String(checkpoint.entered_score) : ''
  }

  // The height of this contiainer is set to 8 rem so that error messages can fit correctly
  // without making the other default grade input off-center
  return (
    <Flex height="8rem" alignItems="start">
      <Flex.Item shouldShrink={true}>
        <View as="div" margin="small medium" data-testid="reply-to-topic-input">
          <DefaultGradeInput
            disabled={!canEdit}
            gradingType={assignment.grading_type}
            onGradeInputChange={updateReplyToTopicSubmission}
            header={I18n.t('Reply to Topic')}
            name="reply_to_topic_input"
            outOfTextValue={replyToTopicCheckpoint?.points_possible.toString()}
            defaultValue={getDefaultValue(replyToTopicCheckpoint)}
          />
        </View>
      </Flex.Item>
      <Flex.Item shouldShrink={true}>
        <View as="div" margin="small medium" data-testid="reply-to-entry-input">
          <DefaultGradeInput
            disabled={!canEdit}
            gradingType={assignment.grading_type}
            onGradeInputChange={updateReplyToEntrySubmission}
            header={I18n.t('Required Replies')}
            name="reply_to_entry_input"
            outOfTextValue={replyToEntryCheckpoint?.points_possible.toString()}
            defaultValue={getDefaultValue(replyToEntryCheckpoint)}
          />
        </View>
      </Flex.Item>
    </Flex>
  )
}

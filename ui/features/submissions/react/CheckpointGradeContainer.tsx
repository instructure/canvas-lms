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
import CheckpointsGradeInputs, {
  REPLY_TO_TOPIC,
  REPLY_TO_ENTRY,
} from '@canvas/grading/react/CheckpointsGradeInputs'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {useMutation} from '@apollo/client'
import {UPDATE_SUBMISSION_SCORE_MUTATION} from '../graphql/submission'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {GradingType} from 'api'
import {TextInput} from '@instructure/ui-text-input'

type AssignmentCheckpointSubmission = {
  tag: string
  submission_id: string
  points_possible: string
  submission_score: number
}

type ParentAssignmentSubmission = {
  grading_type: GradingType
  total_score: string
  checkpoint_submissions: AssignmentCheckpointSubmission[]
}

export type Props = {
  assignment: ParentAssignmentSubmission
}

const capitalizePassFailGrade = (grade: string) => {
  return grade.charAt(0).toUpperCase() + grade.slice(1)
}

const getTotalScore = (assignment: ParentAssignmentSubmission) => {
  if (!assignment.total_score) {
    return '-'
  }
  if (assignment.grading_type === 'pass_fail') {
    return capitalizePassFailGrade(assignment.total_score)
  }
  return assignment.total_score
}

const CheckpointGradeContainer = ({assignment}: Props) => {
  const I18n = useI18nScope('sharedSetDefaultGradeDialog')

  const replyToTopicCheckpoint = assignment.checkpoint_submissions.find(
    cp => cp.tag === REPLY_TO_TOPIC
  )
  const replyToEntryCheckpoint = assignment.checkpoint_submissions.find(
    cp => cp.tag === REPLY_TO_ENTRY
  )
  const totalPossiblePoints = assignment.checkpoint_submissions.reduce(
    (acc, cp) => acc + Number(cp.points_possible),
    0
  )

  const [totalScore, setTotalScore] = React.useState(getTotalScore(assignment))
  const [replyToTopicScore, setReplyToTopicScore] = React.useState<number>(
    replyToTopicCheckpoint?.submission_score || 0
  )
  const [replyToEntryScore, setReplyToEntryScore] = React.useState<number>(
    replyToEntryCheckpoint?.submission_score || 0
  )

  const [updateSubmission] = useMutation(UPDATE_SUBMISSION_SCORE_MUTATION, {
    onCompleted(data) {
      // If the grading type is pass/fail, then capitalize and display the score
      if (assignment.grading_type === 'pass_fail') {
        setTotalScore(
          capitalizePassFailGrade(data.updateSubmissionGrade.parentAssignmentSubmission.grade)
        )
      } else {
        setTotalScore(data.updateSubmissionGrade.parentAssignmentSubmission.grade)
      }
    },
    onError(_error) {
      showFlashError(I18n.t('There was an error updating the submission.'))()
    },
  })

  const updateReplyToTopicSubmission = (score: number) => {
    if (!replyToTopicCheckpoint || score === replyToTopicScore) {
      return
    }
    setReplyToTopicScore(score)
    updateSubmission({
      variables: {
        submissionId: replyToTopicCheckpoint.submission_id,
        score,
        isChildSubmission: true,
      },
    })
  }

  const updateReplyToEntrySubmission = (score: number) => {
    if (!replyToEntryCheckpoint || score === replyToEntryScore) {
      return
    }
    setReplyToEntryScore(score)
    updateSubmission({
      variables: {
        submissionId: replyToEntryCheckpoint.submission_id,
        score,
        isChildSubmission: true,
      },
    })
  }

  return (
    <Flex data-testid="checkpoint-grades-container">
      <Flex.Item shouldShrink={true}>
        <CheckpointsGradeInputs
          assignment={{
            grading_type: assignment.grading_type,
            checkpoints: assignment.checkpoint_submissions.map(checkpoint => ({
              tag: checkpoint.tag,
              submission_id: checkpoint.submission_id,
              points_possible: Number(checkpoint.points_possible),
              entered_score: checkpoint.submission_score,
            })),
          }}
          canEdit={!!ENV.CURRENT_USER_CAN_GRADE_SUBMISSION}
          onReplyToTopicSubmissionChange={updateReplyToTopicSubmission}
          onReplyToEntrySubmissionChange={updateReplyToEntrySubmission}
        />
      </Flex.Item>
      <Flex.Item height="8rem" margin="medium 0 0 small">
        <View as="div">
          <Text size="small" weight="bold">
            {I18n.t('Total Score')}
          </Text>
          <TextInput
            width={assignment.grading_type === 'pass_fail' ? '7rem' : '6rem'}
            value={totalScore}
            onChange={() => {}}
            disabled={true}
            data-testid="total-score-display"
            renderLabel={
              <Text size="x-small" weight="normal">
                {I18n.t(`out of %{totalPossiblePoints}`, {totalPossiblePoints})}
              </Text>
            }
          />
        </View>
      </Flex.Item>
    </Flex>
  )
}

export default CheckpointGradeContainer

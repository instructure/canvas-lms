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
import {
  ApiCallStatus,
  type AssignmentConnection,
  type GradebookUserSubmissionDetails,
} from '../../../types'
import {Flex} from '@instructure/ui-flex'
import DefaultGradeInput from './DefaultGradeInput'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  parentAssignment: AssignmentConnection
  parentSubmission: GradebookUserSubmissionDetails
  parentPassFailStatusIndex: number
  replyToTopicPassFailStatusIndex: number
  replyToEntryPassFailStatusIndex: number
  parentGradeInput: string
  replyToTopicGradeInput: string
  replyToEntryGradeInput: string
  submitScoreStatus: ApiCallStatus
  gradingStandardPointsBased: boolean
}

const findCheckpoint = (assignment: AssignmentConnection, tag: string) => {
  return (
    assignment.checkpoints &&
    assignment.checkpoints.find(({tag: checkpointTag}) => checkpointTag === tag)
  )
}

const buildCheckpointAssignment = (
  assignment: AssignmentConnection,
  checkpointTag: string
): AssignmentConnection => {
  const checkpoint = findCheckpoint(assignment, checkpointTag)
  return {
    ...assignment,
    checkpoints: undefined,
    pointsPossible: checkpoint?.pointsPossible || 0,
  }
}

export const CheckpointGradeInputs = ({
  parentAssignment,
  parentSubmission,
  parentPassFailStatusIndex,
  replyToTopicPassFailStatusIndex,
  replyToEntryPassFailStatusIndex,
  parentGradeInput,
  replyToTopicGradeInput,
  replyToEntryGradeInput,
  submitScoreStatus,
  gradingStandardPointsBased,
}: Props) => {
  const replyToTopicAssignment = buildCheckpointAssignment(parentAssignment, 'reply_to_topic')
  const replyToEntryAssignment = buildCheckpointAssignment(parentAssignment, 'reply_to_entry')

  return (
    <>
      <Flex>
        <Flex.Item shouldGrow={true}>
          <DefaultGradeInput
            assignment={replyToTopicAssignment}
            submission={parentSubmission}
            passFailStatusIndex={replyToTopicPassFailStatusIndex}
            gradeInput={replyToTopicGradeInput}
            submitScoreStatus={submitScoreStatus}
            context="student_and_reply_to_topic_assignment_grade"
            handleSetGradeInput={() => {}}
            handleSubmitGrade={() => {}}
            handleChangePassFailStatus={() => {}}
            gradingStandardPointsBased={gradingStandardPointsBased}
            header={I18n.t('Reply to Topic')}
            shouldShowOutOfText={false}
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <DefaultGradeInput
            assignment={replyToEntryAssignment}
            submission={parentSubmission}
            passFailStatusIndex={replyToEntryPassFailStatusIndex}
            gradeInput={replyToEntryGradeInput}
            submitScoreStatus={submitScoreStatus}
            context="student_and_reply_to_entry_assignment_grade"
            handleSetGradeInput={() => {}}
            handleSubmitGrade={() => {}}
            handleChangePassFailStatus={() => {}}
            gradingStandardPointsBased={gradingStandardPointsBased}
            header={I18n.t('Required Replies')}
            shouldShowOutOfText={false}
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <DefaultGradeInput
            assignment={parentAssignment}
            submission={parentSubmission}
            passFailStatusIndex={parentPassFailStatusIndex}
            gradeInput={parentGradeInput}
            submitScoreStatus={submitScoreStatus}
            context="student_and_assignment_grade"
            handleSetGradeInput={() => {}}
            handleSubmitGrade={() => {}}
            handleChangePassFailStatus={() => {}}
            gradingStandardPointsBased={gradingStandardPointsBased}
            header={I18n.t('Total')}
            shouldShowOutOfText={false}
          />
        </Flex.Item>
      </Flex>
    </>
  )
}

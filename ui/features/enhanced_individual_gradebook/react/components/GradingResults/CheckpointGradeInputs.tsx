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
import {useScope as createI18nScope} from '@canvas/i18n'
import {REPLY_TO_ENTRY, REPLY_TO_TOPIC} from './index'
import type {Spacing} from '@instructure/emotion'

const I18n = createI18nScope('enhanced_individual_gradebook')

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
  handleSetReplyToTopicGradeInput: (grade: string) => void
  handleSetReplyToEntryGradeInput: (grade: string) => void
  handleSubmitGrade?: (subAssignmentTag: string) => void
  handleChangeReplyToTopicPassFailStatus: (
    e: React.SyntheticEvent<Element, Event>,
    data: {value?: string | number},
  ) => void
  handleChangeReplyToEntryPassFailStatus: (
    e: React.SyntheticEvent<Element, Event>,
    data: {value?: string | number},
  ) => void
  elementWrapper?: 'span' | 'div'
  margin?: Spacing
  contextPrefix?: string
}

const findCheckpoint = (assignment: AssignmentConnection, tag: string) => {
  return (
    assignment.checkpoints &&
    assignment.checkpoints.find(({tag: checkpointTag}) => checkpointTag === tag)
  )
}

const buildCheckpointAssignment = (
  assignment: AssignmentConnection,
  checkpointTag: string,
): AssignmentConnection => {
  const checkpoint = findCheckpoint(assignment, checkpointTag)
  return {
    ...assignment,
    checkpoints: undefined,
    pointsPossible: checkpoint?.pointsPossible || 0,
  }
}

const findSubAssignmentSubmission = (submission: GradebookUserSubmissionDetails, tag: string) => {
  return (
    submission.subAssignmentSubmissions &&
    submission.subAssignmentSubmissions.find(({subAssignmentTag}) => subAssignmentTag === tag)
  )
}

const buildSubAssignmentSubmission = (
  submission: GradebookUserSubmissionDetails,
  tag: string,
): GradebookUserSubmissionDetails => {
  const subAssignmentSubmission = findSubAssignmentSubmission(submission, tag)
  return {
    ...submission,
    subAssignmentSubmissions: undefined,
    enteredScore: subAssignmentSubmission?.enteredScore || null,
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
  handleSetReplyToTopicGradeInput,
  handleSetReplyToEntryGradeInput,
  handleSubmitGrade,
  handleChangeReplyToTopicPassFailStatus,
  handleChangeReplyToEntryPassFailStatus,
  elementWrapper,
  margin,
  contextPrefix = 'student_and_',
}: Props) => {
  const replyToTopicAssignment = buildCheckpointAssignment(parentAssignment, REPLY_TO_TOPIC)
  const replyToEntryAssignment = buildCheckpointAssignment(parentAssignment, REPLY_TO_ENTRY)

  return (
    <>
      <Flex width="29rem" as="span">
        <Flex.Item shouldGrow={true}>
          <DefaultGradeInput
            assignment={replyToTopicAssignment}
            submission={buildSubAssignmentSubmission(parentSubmission, REPLY_TO_TOPIC)}
            passFailStatusIndex={replyToTopicPassFailStatusIndex}
            gradeInput={replyToTopicGradeInput}
            submitScoreStatus={submitScoreStatus}
            context={`${contextPrefix}reply_to_topic_assignment_grade`}
            handleSetGradeInput={handleSetReplyToTopicGradeInput}
            handleSubmitGrade={() => {
              if (handleSubmitGrade) {
                handleSubmitGrade(REPLY_TO_TOPIC)
              }
            }}
            handleChangePassFailStatus={handleChangeReplyToTopicPassFailStatus}
            gradingStandardPointsBased={gradingStandardPointsBased}
            header={I18n.t('Reply to Topic')}
            shouldShowOutOfText={false}
            elementWrapper={elementWrapper}
            margin={margin}
            width="9rem"
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <DefaultGradeInput
            assignment={replyToEntryAssignment}
            submission={buildSubAssignmentSubmission(parentSubmission, REPLY_TO_ENTRY)}
            passFailStatusIndex={replyToEntryPassFailStatusIndex}
            gradeInput={replyToEntryGradeInput}
            submitScoreStatus={submitScoreStatus}
            context={`${contextPrefix}reply_to_entry_assignment_grade`}
            handleSetGradeInput={handleSetReplyToEntryGradeInput}
            handleSubmitGrade={() => {
              if (handleSubmitGrade) {
                handleSubmitGrade(REPLY_TO_ENTRY)
              }
            }}
            handleChangePassFailStatus={handleChangeReplyToEntryPassFailStatus}
            gradingStandardPointsBased={gradingStandardPointsBased}
            header={I18n.t('Required Replies')}
            shouldShowOutOfText={false}
            elementWrapper={elementWrapper}
            margin={margin}
            width="9rem"
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <DefaultGradeInput
            assignment={parentAssignment}
            submission={parentSubmission}
            passFailStatusIndex={parentPassFailStatusIndex}
            gradeInput={parentGradeInput}
            submitScoreStatus={submitScoreStatus}
            context={`${contextPrefix}assignment_grade`}
            handleSetGradeInput={() => {}}
            handleSubmitGrade={() => {}}
            handleChangePassFailStatus={() => {}}
            gradingStandardPointsBased={gradingStandardPointsBased}
            header={I18n.t('Total')}
            shouldShowOutOfText={false}
            elementWrapper={elementWrapper}
            margin={margin}
            width="9rem"
          />
        </Flex.Item>
      </Flex>
    </>
  )
}

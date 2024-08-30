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

import React, {useContext, useEffect, useState} from 'react'
import {useQuery} from '@canvas/query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import {SpeedGraderCheckpoint} from './SpeedGraderCheckpoint'
import type {GradeStatusUnderscore} from '@canvas/grading/accountGradingStatus'
import AssessmentGradeInput from './AssessmentGradeInput'
import {Flex} from '@instructure/ui-flex'
import {useMutation, useQueryClient} from '@tanstack/react-query'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

const I18n = useI18nScope('SpeedGraderCheckpoints')

type Props = {
  courseId: string
  assignmentId: string
  studentId: string
  customGradeStatusesEnabled: boolean
  customGradeStatuses?: GradeStatusUnderscore[]
  lateSubmissionInterval: string
}

// All the following types are incomplete on purpose, we are only adding to them what we need for this components to work.
export type Assignment = {
  id: string
  course_id: string
  points_possible: number
  grading_type: string
  checkpoints: {
    tag: 'reply_to_topic' | 'reply_to_entry' | null
    points_possible: number
  }[]
}

export type SubAssignmentSubmission = {
  sub_assignment_tag: 'reply_to_topic' | 'reply_to_entry' | null
  score: number
  excused: boolean
  late_policy_status: string
  seconds_late: number
  custom_grade_status_id: null | string
  grade: string
  entered_grade: string
  user_id: string
}

export type Submission = SubAssignmentSubmission & {
  has_sub_assignment_submissions: boolean
  sub_assignment_submissions: SubAssignmentSubmission[]
}

const fetchAssignment = async (
  courseId: string,
  assignmentId: string
): Promise<Assignment | null> => {
  const path = `/api/v1/courses/${courseId}/assignments/${assignmentId}?include=checkpoints`

  const {json} = await doFetchApi({
    method: 'GET',
    path,
  })

  return json || null
}

const fetchSubmission = async (
  courseId: string,
  assignmentId: string,
  studentId: string
): Promise<Submission | null> => {
  const path = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${studentId}?include=sub_assignment_submissions`

  const {json} = await doFetchApi({
    method: 'GET',
    path,
  })

  return json || null
}

export type SubmissionGradeParams = {
  subAssignmentTag: 'reply_to_topic' | 'reply_to_entry' | null
  courseId: string
  assignmentId: string
  studentId: string
  grade: string | number | null
}

const putSubmissionGrade = ({
  subAssignmentTag,
  courseId,
  assignmentId,
  studentId,
  grade,
}: SubmissionGradeParams) => {
  return doFetchApi({
    method: 'PUT',
    path: `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${studentId}`,
    params: {
      course_id: courseId,
      sub_assignment_tag: subAssignmentTag,
      submission: {
        assignment_id: assignmentId,
        user_id: studentId,
        posted_grade: grade,
      },
    },
  })
}

export type SubmissionStatusParams = {
  subAssignmentTag: 'reply_to_topic' | 'reply_to_entry' | null
  courseId: string
  assignmentId: string
  studentId: string
  latePolicyStatus?: string
  customGradeStatusId?: string | null
  secondsLate?: number
}

const putSubmissionStatus = ({
  subAssignmentTag,
  courseId,
  assignmentId,
  studentId,
  latePolicyStatus,
  customGradeStatusId,
  secondsLate,
}: SubmissionStatusParams) => {
  return doFetchApi({
    method: 'PUT',
    path: `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${studentId}`,
    params: {
      course_id: courseId,
      sub_assignment_tag: subAssignmentTag,
      submission: {
        sub_assignment_tag: subAssignmentTag,
        assignment_id: assignmentId,
        user_id: studentId,
        ...(latePolicyStatus ? {late_policy_status: latePolicyStatus} : {}),
        ...(customGradeStatusId ? {custom_grade_status_id: customGradeStatusId} : {}),
        ...(secondsLate ? {seconds_late_override: secondsLate} : {}),
      },
    },
  })
}

export const REPLY_TO_TOPIC = 'reply_to_topic'
export const REPLY_TO_ENTRY = 'reply_to_entry'

const sortSubmissions = (a: SubAssignmentSubmission, b: SubAssignmentSubmission) => {
  const order = {
    [REPLY_TO_TOPIC]: 1,
    [REPLY_TO_ENTRY]: 2,
  }

  const getOrder = (subAssignmentTag: 'reply_to_topic' | 'reply_to_entry' | null) => {
    return subAssignmentTag && Object.keys(order).includes(subAssignmentTag)
      ? order[subAssignmentTag]
      : 0
  }

  return getOrder(a.sub_assignment_tag) - getOrder(b.sub_assignment_tag)
}

export const SpeedGraderCheckpointsContainer = (props: Props) => {
  const queryClient = useQueryClient()

  const [shouldAnnounceCurrentGradeChange, setShouldAnnounceCurrentGradeChange] = useState(false)
  const {setOnSuccess} = useContext(AlertManagerContext)

  const {data: assignment, isLoading: isLoadingAssignment} = useQuery({
    queryKey: ['speedGraderCheckpointsAssignment', props.courseId, props.assignmentId],
    queryFn: () => fetchAssignment(props.courseId, props.assignmentId),
    enabled: true,
    cacheTime: 0,
    staleTime: 0,
  })

  const {
    data: submission,
    isLoading: isLoadingSubmission,
    isRefetching: isRefetchingSubmission,
  } = useQuery({
    queryKey: [
      'speedGraderCheckpointsSubmission',
      props.courseId,
      props.assignmentId,
      props.studentId,
    ],
    queryFn: () => fetchSubmission(props.courseId, props.assignmentId, props.studentId),
    enabled: true,
    cacheTime: 0,
    staleTime: 0,
  })

  // make a screenreader announcement any time the current total grade
  // automatically changes for checkpointed discussions
  useEffect(() => {
    if (
      submission &&
      !isRefetchingSubmission &&
      submission.has_sub_assignment_submissions &&
      shouldAnnounceCurrentGradeChange
    ) {
      const announcement = submission.grade
        ? I18n.t('Current Total Updated: %{grade}', {grade: submission.grade})
        : I18n.t('Current Total Updated')
      setOnSuccess(announcement)
      setShouldAnnounceCurrentGradeChange(false)
    }
  }, [submission, isRefetchingSubmission, shouldAnnounceCurrentGradeChange, setOnSuccess])

  const invalidateSubmission = () => {
    queryClient.invalidateQueries([
      'speedGraderCheckpointsSubmission',
      props.courseId,
      props.assignmentId,
      props.studentId,
    ])
  }

  const {mutate: updateSubmissionGrade} = useMutation({
    mutationFn: putSubmissionGrade,
    onSuccess: () => {
      invalidateSubmission()
      setShouldAnnounceCurrentGradeChange(true)
    },
  })

  const {mutate: updateSubmissionStatus} = useMutation({
    mutationFn: putSubmissionStatus,
    onSuccess: () => {
      invalidateSubmission()
      setShouldAnnounceCurrentGradeChange(true)
    },
  })

  if (isLoadingAssignment || isLoadingSubmission) {
    return <Spinner renderTitle={I18n.t('Loading')} size="medium" margin="0" />
  }

  if (!assignment || !submission) {
    return null
  }

  if (!submission.has_sub_assignment_submissions) {
    return null
  }

  const getAssignmentWithPropsFromCheckpoints = (
    // eslint-disable-next-line @typescript-eslint/no-shadow
    assignment: Assignment,
    // eslint-disable-next-line @typescript-eslint/no-shadow
    submission: SubAssignmentSubmission
  ) => {
    return {
      ...assignment,
      points_possible:
        assignment.checkpoints.find(({tag}) => tag === submission.sub_assignment_tag)
          ?.points_possible || 0,
    }
  }

  return (
    <div>
      {submission.sub_assignment_submissions.sort(sortSubmissions).map(submission => {
        return (
          <SpeedGraderCheckpoint
            key={submission.sub_assignment_tag}
            assignment={getAssignmentWithPropsFromCheckpoints(assignment, submission)}
            subAssignmentSubmission={submission}
            customGradeStatusesEnabled={props.customGradeStatusesEnabled}
            customGradeStatuses={props.customGradeStatuses}
            lateSubmissionInterval={props.lateSubmissionInterval}
            updateSubmissionGrade={updateSubmissionGrade}
            updateSubmissionStatus={updateSubmissionStatus}
          />
        )
      })}
      <Flex margin="none none small" gap="small" alignItems="start">
        <Flex.Item>
          <AssessmentGradeInput
            assignment={assignment}
            showAlert={() => {}}
            submission={submission}
            courseId={props.courseId}
            hasHeader={true}
            header={I18n.t('Current Total')}
            isDisabled={true}
            isWidthDefault={false}
          />
        </Flex.Item>
      </Flex>
    </div>
  )
}

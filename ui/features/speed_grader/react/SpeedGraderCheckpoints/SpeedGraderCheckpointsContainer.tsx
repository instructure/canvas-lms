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

import React, {useContext, useEffect, useState, useCallback} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SpeedGraderCheckpoint, EXCUSED} from './SpeedGraderCheckpoint'
import type {GradeStatusUnderscore} from '@canvas/grading/accountGradingStatus'
import AssessmentGradeInput from './AssessmentGradeInput'
import {Flex} from '@instructure/ui-flex'
import {useMutation, useQuery, useQueryClient} from '@tanstack/react-query'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import OutlierScoreHelper from '@canvas/grading/OutlierScoreHelper'
import {showFlashWarning} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('SpeedGraderCheckpoints')

type SpeedGrader = {
  setOrUpdateSubmission: (submission: any) => any
  updateSelectMenuStatus: (student: any) => any
}

type Props = {
  EG: SpeedGrader
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
  missing: boolean
  late: boolean
  late_policy_status: string
  seconds_late: number
  custom_grade_status_id: null | string
  grade: string | number | null
  entered_grade: string
  user_id: string
  grade_matches_current_submission: boolean
}

export type Submission = SubAssignmentSubmission & {
  has_sub_assignment_submissions: boolean
  sub_assignment_submissions: SubAssignmentSubmission[]
}

const fetchAssignment = async (
  courseId: string,
  assignmentId: string,
): Promise<Assignment | null> => {
  const path = `/api/v1/courses/${courseId}/assignments/${assignmentId}?include=checkpoints`

  const {json} = await doFetchApi({
    method: 'GET',
    path,
  })

  // @ts-expect-error
  return json || null
}

const fetchSubmission = async (
  courseId: string,
  assignmentId: string,
  studentId: string,
): Promise<Submission | null> => {
  const path = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${studentId}?include=sub_assignment_submissions`

  const {json} = await doFetchApi({
    method: 'GET',
    path,
  })

  // @ts-expect-error
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
  const excuse = latePolicyStatus === EXCUSED
  return doFetchApi({
    method: 'PUT',
    path: `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${studentId}`,
    body: {
      course_id: courseId,
      sub_assignment_tag: subAssignmentTag,
      submission: {
        sub_assignment_tag: subAssignmentTag,
        assignment_id: assignmentId,
        user_id: studentId,
        ...(latePolicyStatus && !excuse ? {late_policy_status: latePolicyStatus} : {}),
        ...(customGradeStatusId ? {custom_grade_status_id: customGradeStatusId} : {}),
        ...(secondsLate ? {seconds_late_override: secondsLate} : {}),
        ...(latePolicyStatus ? {excuse} : {}),
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

const fetchAssignmentFunction = (context: {queryKey: [string, string, string]}) => {
  const [, courseId, assignmentId] = context.queryKey
  return fetchAssignment(courseId, assignmentId)
}

const fetchSubmissionFunction = (context: {queryKey: [string, string, string, string]}) => {
  const [, courseId, assignmentId, studentId] = context.queryKey
  return fetchSubmission(courseId, assignmentId, studentId)
}

export const SpeedGraderCheckpointsContainer = (props: Props) => {
  const queryClient = useQueryClient()

  const [shouldAnnounceCurrentGradeChange, setShouldAnnounceCurrentGradeChange] = useState(false)
  const {setOnSuccess} = useContext(AlertManagerContext)
  // @ts-expect-error
  const [lastSubmission, setLastSubmission] = useState<SubAssignmentSubmission>(null)

  const {data: assignment, isLoading: isLoadingAssignment} = useQuery({
    queryKey: ['speedGraderCheckpointsAssignment', props.courseId, props.assignmentId],
    queryFn: fetchAssignmentFunction,
    enabled: true,
    gcTime: 0,
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
    queryFn: fetchSubmissionFunction,
    enabled: true,
    gcTime: 0,
    staleTime: 0,
  })

  const showWarningIfOutlier = useCallback(() => {
    if (!lastSubmission) return

    const score = Number(lastSubmission.grade)
    const {points_possible: pointsPossible} = getAssignmentWithPropsFromCheckpoints(
      // @ts-expect-error
      assignment,
      lastSubmission,
    )
    const outlierScoreHelper = new OutlierScoreHelper(score, pointsPossible)

    if (outlierScoreHelper.hasWarning()) {
      // $.flashWarning(outlierScoreHelper.warningMessage())
      showFlashWarning(outlierScoreHelper.warningMessage())()
    }
  }, [assignment, lastSubmission])

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
      showWarningIfOutlier()
    }
  }, [
    submission,
    isRefetchingSubmission,
    shouldAnnounceCurrentGradeChange,
    setOnSuccess,
    showWarningIfOutlier,
  ])

  const invalidateSubmission = () => {
    queryClient.invalidateQueries({
      queryKey: [
        'speedGraderCheckpointsSubmission',
        props.courseId,
        props.assignmentId,
        props.studentId,
      ],
    })
  }

  const updateSubmissionUI = (data: object) => {
    if (props.EG) {
      // all_submissions[0] has submission_history vs data?.json which is a submission, but does not.
      /* @ts-expect-error */
      const submissionData = data?.json?.all_submissions[0]
      if (submissionData) {
        const student = props.EG.setOrUpdateSubmission(submissionData)
        props.EG.updateSelectMenuStatus(student)
      }
      invalidateSubmission()
      setShouldAnnounceCurrentGradeChange(true)
    }
  }

  const {mutate: updateSubmissionGrade} = useMutation({
    mutationFn: putSubmissionGrade,
    onSuccess: data => {
      updateSubmissionUI(data)
    },
  })

  const {mutate: updateSubmissionStatus} = useMutation({
    mutationFn: putSubmissionStatus,
    onSuccess: data => {
      updateSubmissionUI(data)
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
    assignment: Assignment,

    submission: SubAssignmentSubmission,
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
            setLastSubmission={setLastSubmission}
          />
        )
      })}
      <Flex margin="none none small" gap="small" alignItems="start">
        <Flex.Item>
          {/* @ts-expect-error */}
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

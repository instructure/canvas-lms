/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import {Button} from '@instructure/ui-buttons'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {
  ApiCallStatus,
  type AssignmentConnection,
  type GradebookOptions,
  type GradebookStudentDetails,
  type GradebookUserSubmissionDetails,
} from '../../../types'
import {useSubmitScore} from '../../hooks/useSubmitScore'
import {useGetComments} from '../../hooks/useComments'
import SubmissionDetailModal, {type GradeChangeApiUpdate} from './SubmissionDetailModal'
import ProxyUploadModal from '@canvas/proxy-submission/react/ProxyUploadModal'
import {
  submitterPreviewText,
  disableGrading,
  passFailStatusOptions,
} from '../../../utils/gradebookUtils'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import DefaultGradeInput from './DefaultGradeInput'

const I18n = useI18nScope('enhanced_individual_gradebook')

export type GradingResultsComponentProps = {
  currentStudent?: GradebookStudentDetails
  studentSubmissions?: GradebookUserSubmissionDetails[]
  assignment?: AssignmentConnection
  courseId: string
  gradebookOptions: GradebookOptions
  loadingStudent: boolean
  currentStudentHiddenName: string
  onSubmissionSaved: (submission: GradebookUserSubmissionDetails) => void
  dropped: boolean
}

export default function GradingResults({
  assignment,
  courseId,
  currentStudent,
  studentSubmissions,
  gradebookOptions,
  loadingStudent,
  currentStudentHiddenName,
  onSubmissionSaved,
  dropped,
}: GradingResultsComponentProps) {
  const submission = studentSubmissions?.find(s => s.assignmentId === assignment?.id)
  const [gradeInput, setGradeInput] = useState<string>('')
  const [excusedChecked, setExcusedChecked] = useState<boolean>(false)
  const [modalOpen, setModalOpen] = useState<boolean>(false)
  const [proxyUploadModalOpen, setProxyUploadModalOpen] = useState<boolean>(false)
  const [passFailStatusIndex, setPassFailStatusIndex] = useState<number>(0)

  const {submit, submitExcused, submitScoreError, submitScoreStatus, savedSubmission} =
    useSubmitScore()
  const {submissionComments, loadingComments, refetchComments} = useGetComments({
    courseId,
    submissionId: submission?.id,
  })

  useEffect(() => {
    if (submission) {
      if (assignment?.gradingType === 'pass_fail') {
        const index = passFailStatusOptions.findIndex(
          passFailStatusOption =>
            passFailStatusOption.value === submission.grade ||
            (passFailStatusOption.value === 'EX' && submission.excused)
        )
        if (index !== -1) {
          setPassFailStatusIndex(index)
        } else {
          setPassFailStatusIndex(0)
        }
      }
      setExcusedChecked(submission.excused)
      if (submission.excused) {
        setGradeInput(I18n.t('Excused'))
      } else if (submission.enteredGrade == null) {
        setGradeInput('-')
      } else if (assignment?.gradingType === 'letter_grade') {
        setGradeInput(GradeFormatHelper.replaceDashWithMinus(submission.enteredGrade))
      } else {
        setGradeInput(submission.enteredGrade)
      }
    }
  }, [assignment, submission])

  const handleGradeChange = useCallback(
    (updateEvent: GradeChangeApiUpdate) => {
      const {status, newSubmission, error} = updateEvent
      switch (status) {
        case ApiCallStatus.FAILED:
          showFlashError(error)(new Error('Failed to submit score'))
          break
        case ApiCallStatus.COMPLETED:
          if (!newSubmission) {
            return
          }
          onSubmissionSaved(newSubmission)
          setModalOpen(false)
          showFlashSuccess(I18n.t('Grade saved'))()
          break
      }
    },
    [onSubmissionSaved]
  )

  const handlePostComment = useCallback(() => {
    setModalOpen(false)
    refetchComments()
  }, [refetchComments])

  useEffect(() => {
    handleGradeChange({
      status: submitScoreStatus,
      newSubmission: savedSubmission,
      error: submitScoreError,
    })
  }, [submitScoreStatus, savedSubmission, submitScoreError, handleGradeChange])
  if (!submission || !assignment || !currentStudent) {
    return (
      <>
        <View as="div" data-testid="grading-results-empty">
          <View as="div" className="row-fluid">
            <View as="div" className="span4">
              <View as="h2">{I18n.t('Grading')}</View>
            </View>
            <View as="div" className="span8 pad-box top-only">
              <View as="p" className="submission_selection">
                {I18n.t('Select a student and an assignment to view and edit grades.')}
              </View>
            </View>
          </View>
        </View>
      </>
    )
  }

  const reloadSubmission = (proxyDetails: any) => {
    proxyDetails = {
      submissionType: proxyDetails.submission_type,
      proxySubmitter: proxyDetails.proxy_submitter,
      workflowState: proxyDetails.workflow_state,
      submittedAt: proxyDetails.submitted_at,
    }
    onSubmissionSaved({...submission, ...proxyDetails})
  }

  if (loadingStudent) {
    return <LoadingIndicator />
  }

  const {
    changeGradeUrl,
    customOptions: {hideStudentNames},
  } = gradebookOptions

  const submitScoreUrl = (changeGradeUrl ?? '')
    .replace(':assignment', assignment.id)
    .replace(':submission', submission.userId)

  const markExcused = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const {
      target: {checked},
    } = event
    await submitExcused(checked, submitScoreUrl)
  }

  const submitGrade = async () => {
    await submit(assignment, submission, gradeInput, submitScoreUrl)
  }

  const handleSetGradeInput = (input: string) => {
    setGradeInput(input)
  }

  const handleChangePassFailStatus = (
    event: React.SyntheticEvent,
    data: {value?: string | number | undefined}
  ) => {
    if (typeof data.value === 'string') {
      setGradeInput(data.value)
    }
    setPassFailStatusIndex(passFailStatusOptions.findIndex(option => option.value === data.value))
  }

  const latePenaltyFinalGradeDisplay = (grade: string | null) => {
    if (grade == null) {
      return ' -'
    }

    const displayGrade = GradeFormatHelper.formatGrade(grade)
    return GradeFormatHelper.replaceDashWithMinus(displayGrade)
  }

  return (
    <>
      <View as="div" data-testid="grading-results">
        <View as="div" className="row-fluid">
          <View as="div" className="span4">
            <View as="h2">{I18n.t('Grading')}</View>
          </View>
          <View as="div" className="span8 pad-box top-only">
            <View as="div" data-testid="student_and_assignment_grade_label">
              <View as="span">
                <Text size="small">
                  <View as="strong">{`${I18n.t('Grade for')} ${
                    hideStudentNames ? currentStudentHiddenName : currentStudent.name
                  } - ${assignment.name}`}</View>
                </Text>
                <SubmissionStatus submission={submission} />
              </View>
            </View>
            <View as="span">
              <Text data-testid="submitter-name" size="small">
                {submitterPreviewText(submission)}
              </Text>
            </View>
            <DefaultGradeInput
              assignment={assignment}
              submission={submission}
              passFailStatusIndex={passFailStatusIndex}
              gradeInput={gradeInput}
              submitScoreStatus={submitScoreStatus}
              context="student_and_assignment_grade"
              handleSetGradeInput={handleSetGradeInput}
              handleSubmitGrade={submitGrade}
              handleChangePassFailStatus={handleChangePassFailStatus}
            />
            <View as="div" margin="small 0 0 0">
              {submission.late && (
                <>
                  <View display="inline-block">
                    <View
                      data-testid="submission_late_penalty_label"
                      as="div"
                      padding="0 0 0 small"
                    >
                      <Text color="danger">{I18n.t('Late Penalty')}</Text>
                    </View>
                    <View
                      data-testid="late_penalty_final_grade_label"
                      as="div"
                      padding="0 0 0 small"
                    >
                      <Text>{I18n.t('Final Grade')}</Text>
                    </View>
                  </View>
                  <View display="inline-block">
                    <View
                      data-testid="submission_late_penalty_value"
                      as="div"
                      padding="0 0 0 small"
                    >
                      <Text color="danger">
                        {!Number.isNaN(Number(submission.deductedPoints))
                          ? I18n.n(-Number(submission.deductedPoints)) || ' -'
                          : ' -'}
                      </Text>
                    </View>
                    <View
                      data-testid="late_penalty_final_grade_value"
                      as="div"
                      padding="0 0 0 small"
                    >
                      <Text>{latePenaltyFinalGradeDisplay(submission.grade)}</Text>
                    </View>
                  </View>
                </>
              )}
            </View>

            {assignment.gradingType !== 'pass_fail' && (
              <div
                className="checkbox"
                style={{padding: 12, margin: '15px 0 0 0', background: '#eee', borderRadius: 5}}
              >
                <label className="checkbox" htmlFor="excuse_assignment">
                  <input
                    type="checkbox"
                    id="excuse_assignment"
                    name="excuse_assignment"
                    data-testid="excuse_assignment_checkbox"
                    checked={excusedChecked}
                    disabled={disableGrading(assignment, submitScoreStatus)}
                    onChange={markExcused}
                  />
                  {I18n.t('Excuse This Assignment for the Selected Student')}
                </label>
              </div>
            )}
            {dropped && (
              <p className="dropped muted" data-testid="dropped-assignment-message">
                This grade is currently dropped for this student.
              </p>
            )}
            {submission.gradeMatchesCurrentSubmission !== null &&
              !submission.gradeMatchesCurrentSubmission && (
                <View
                  as="div"
                  margin="large 0 0 0"
                  className="resubmitted_assignment_label"
                  data-testid="resubmitted_assignment_label"
                >
                  <Text color="secondary">
                    {I18n.t('This assignment has been resubmitted since it was graded last.')}
                  </Text>
                </View>
              )}

            <View as="div" className="span4" margin="small 0 0 0" width="14.6rem">
              <Button
                data-testid="submission-details-button"
                display="block"
                onClick={() => {
                  setModalOpen(true)
                }}
              >
                {I18n.t('Submission Details')}
              </Button>
            </View>
            <View as="div" className="span4" margin="medium" width="14.6rem">
              {gradebookOptions.proxySubmissionEnabled &&
                assignment.submissionTypes.includes('online_upload') && (
                  <Button
                    data-testid="proxy-submission-button"
                    display="block"
                    onClick={() => setProxyUploadModalOpen(true)}
                  >
                    {I18n.t('Submit for Student')}
                  </Button>
                )}
            </View>
          </View>
        </View>
      </View>
      <SubmissionDetailModal
        assignment={assignment}
        comments={submissionComments}
        gradebookOptions={gradebookOptions}
        student={currentStudent}
        submission={submission}
        loadingComments={loadingComments}
        modalOpen={modalOpen}
        submitScoreUrl={submitScoreUrl}
        handleClose={() => setModalOpen(false)}
        onGradeChange={handleGradeChange}
        onPostComment={handlePostComment}
      />
      <ProxyUploadModal
        data-testid="proxy-upload-modal"
        open={proxyUploadModalOpen}
        onClose={() => {
          setProxyUploadModalOpen(false)
        }}
        assignment={assignment}
        student={currentStudent}
        submission={submission}
        reloadSubmission={reloadSubmission}
      />
    </>
  )
}

type SubmissionStatusProps = {
  submission: GradebookUserSubmissionDetails
}
function SubmissionStatus({submission}: SubmissionStatusProps) {
  let text = ''

  if (submission.customGradeStatus) {
    text = submission.customGradeStatus.toUpperCase()
  } else if (submission.late) {
    text = 'LATE'
  } else if (submission.missing) {
    text = 'MISSING'
  } else if (submission.latePolicyStatus === 'extended') {
    text = 'EXTENDED'
  } else {
    return null
  }

  return (
    <View as="span">
      {submission.customGradeStatus ? (
        <Pill margin="small" data-testid="submission-status-pill">
          <View as="strong" padding="x-small">
            {text}
          </View>
        </Pill>
      ) : (
        <Pill margin="small" color="danger" data-testid="submission-status-pill">
          <View as="strong" padding="x-small">
            {I18n.t('%{text}', {text})}
          </View>
        </Pill>
      )}
    </View>
  )
}

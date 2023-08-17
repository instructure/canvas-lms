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
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {
  ApiCallStatus,
  AssignmentConnection,
  GradebookOptions,
  GradebookStudentDetails,
  GradebookUserSubmissionDetails,
} from '../../../types'
import {useSubmitScore} from '../../hooks/useSubmitScore'
import {useGetComments} from '../../hooks/useComments'
import SubmissionDetailModal, {GradeChangeApiUpdate} from './SubmissionDetailModal'
import ProxyUploadModal from '@canvas/proxy-submission/react/ProxyUploadModal'
import {outOfText, submitterPreviewText} from '../../../utils/gradebookUtils'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

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
}: GradingResultsComponentProps) {
  const submission = studentSubmissions?.find(s => s.assignmentId === assignment?.id)
  const [gradeInput, setGradeInput] = useState<string>('')
  const [excusedChecked, setExcusedChecked] = useState<boolean>(false)
  const [modalOpen, setModalOpen] = useState<boolean>(false)
  const [proxyUploadModalOpen, setProxyUploadModalOpen] = useState<boolean>(false)

  const {submit, submitExcused, submitScoreError, submitScoreStatus, savedSubmission} =
    useSubmitScore()
  const {submissionComments, loadingComments, refetchComments} = useGetComments({
    courseId,
    submissionId: submission?.id,
  })

  useEffect(() => {
    if (submission) {
      setExcusedChecked(submission.excused)
      setGradeInput(submission.excused ? I18n.t('Excused') : submission.enteredGrade ?? '-')
    }
  }, [submission])

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

            <View as="div" className="grade" margin="0 0 small 0">
              <TextInput
                display="inline-block"
                width="14rem"
                value={gradeInput}
                disabled={submitScoreStatus === ApiCallStatus.PENDING}
                renderLabel={<ScreenReaderContent>{I18n.t('Student Grade')}</ScreenReaderContent>}
                data-testid="student_and_assignment_grade_input"
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setGradeInput(e.target.value)}
                onBlur={() => submitGrade()}
              />
              <View as="span" margin="0 0 0 small">
                {outOfText(assignment, submission)}
              </View>
            </View>

            <View as="div">
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
                      <Text>
                        {submission.grade != null
                          ? GradeFormatHelper.formatGrade(submission.grade)
                          : ' -'}
                      </Text>
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
                    checked={excusedChecked}
                    disabled={submitScoreStatus === ApiCallStatus.PENDING}
                    onChange={markExcused}
                  />
                  {I18n.t('Excuse This Assignment for the Selected Student')}
                </label>
              </div>
            )}

            <View as="div" className="span4" margin="medium 0 0 0" width="14.6rem">
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

  if (submission.late) {
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
      <Pill margin="small" color="danger" data-testid="submission-status-pill">
        <View as="strong" padding="x-small">
          {I18n.t('%{text}', {text})}
        </View>
      </Pill>
    </View>
  )
}

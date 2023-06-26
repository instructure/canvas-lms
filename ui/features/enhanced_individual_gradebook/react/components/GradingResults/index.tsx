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
import {studentDisplayName, outOfText, submitterPreviewText} from '../../../utils/gradebookUtils'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  currentStudent?: GradebookStudentDetails
  studentSubmissions?: GradebookUserSubmissionDetails[]
  assignment?: AssignmentConnection
  courseId: string
  gradebookOptions: GradebookOptions
  loadingStudent: boolean
  onSubmissionSaved: (submission: GradebookUserSubmissionDetails) => void
}

export default function GradingResults({
  assignment,
  courseId,
  currentStudent,
  studentSubmissions,
  gradebookOptions,
  loadingStudent,
  onSubmissionSaved,
}: Props) {
  const submission = studentSubmissions?.find(s => s.assignmentId === assignment?.id)
  const [gradeInput, setGradeInput] = useState<string>('')
  const [excusedChecked, setExcusedChecked] = useState<boolean>(false)
  const [modalOpen, setModalOpen] = useState<boolean>(false)

  const {submit, submitExcused, submitScoreError, submitScoreStatus, savedSubmission} =
    useSubmitScore()
  const {submissionComments, loadingComments, refetchComments} = useGetComments({
    courseId,
    submissionId: submission?.id,
  })

  useEffect(() => {
    if (submission) {
      setExcusedChecked(submission.excused)
      setGradeInput(submission.excused ? I18n.t('Excused') : submission.grade ?? '-')
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
        <View as="div">
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
      <View as="div">
        <View as="div" className="row-fluid">
          <View as="div" className="span4">
            <View as="h2">{I18n.t('Grading')}</View>
          </View>
          <View as="div" className="span8 pad-box top-only">
            <View as="div">
              <View as="span">
                <Text size="small">
                  <View as="strong">{`${I18n.t('Grade for')} ${studentDisplayName(
                    currentStudent,
                    hideStudentNames
                  )} - ${assignment.name}`}</View>
                </Text>
                <SubmissionStatus submission={submission} />
              </View>
            </View>
            <View as="span">
              <Text size="small">{submitterPreviewText(submission)}</Text>
            </View>

            <View as="div" className="grade">
              <TextInput
                display="inline-block"
                width="14rem"
                value={gradeInput}
                disabled={submitScoreStatus === ApiCallStatus.PENDING}
                renderLabel={<ScreenReaderContent>{I18n.t('Student Grade')}</ScreenReaderContent>}
                onChange={e => setGradeInput(e.target.value)}
                onBlur={() => submitGrade()}
              />
              <View as="span" margin="0 0 0 small">
                {outOfText(assignment, submission)}
              </View>
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
                display="block"
                onClick={() => {
                  setModalOpen(true)
                }}
              >
                {I18n.t('Submission Details')}
              </Button>
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
      <Pill margin="small" color="danger">
        <View as="strong" padding="x-small">
          {I18n.t('%{text}', {text})}
        </View>
      </Pill>
    </View>
  )
}

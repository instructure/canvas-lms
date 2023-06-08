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

import React, {useEffect, useState} from 'react'
import $ from 'jquery'
import DateHelper from '@canvas/datetime/dateHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {
  ApiCallStatus,
  AssignmentConnection,
  GradebookOptions,
  GradebookUserSubmissionDetails,
} from '../../../types'
import {useCurrentStudentInfo} from '../../hooks/useCurrentStudentInfo'
import {Pill} from '@instructure/ui-pill'
import {Button} from '@instructure/ui-buttons'
import {useSubmitScore} from '../../hooks/useSubmitScore'
import SubmissionDetailModal from './SubmissionDetailModal'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  courseId: string
  studentId?: string | null
  assignment?: AssignmentConnection
  gradebookOptions: GradebookOptions
  onSubmissionSaved: (submission: GradebookUserSubmissionDetails) => void
}

export default function GradingResults({
  assignment,
  courseId,
  gradebookOptions,
  studentId,
  onSubmissionSaved,
}: Props) {
  const {currentStudent, studentSubmissions} = useCurrentStudentInfo(courseId, studentId)
  const submission = studentSubmissions?.find(s => s.assignmentId === assignment?.id)
  const [gradeInput, setGradeInput] = useState<string>('')
  const [modalOpen, setModalOpen] = useState<boolean>(false)

  const {submit, submitScoreError, submitScoreStatus, savedSubmission} = useSubmitScore()

  useEffect(() => {
    if (submission) {
      setGradeInput(submission?.grade ?? '-')
    }
  }, [submission])

  useEffect(() => {
    switch (submitScoreStatus) {
      case ApiCallStatus.FAILED:
        $.flashError(submitScoreError)
        break
      case ApiCallStatus.COMPLETED:
        if (!savedSubmission) {
          return
        }
        onSubmissionSaved(savedSubmission)
        break
    }
  }, [submitScoreError, submitScoreStatus, savedSubmission, onSubmissionSaved])

  if (!submission || !assignment) {
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

  const submitterPreviewText = () => {
    if (!submission.submissionType) {
      return I18n.t('Has not submitted')
    }
    const formattedDate = DateHelper.formatDatetimeForDisplay(submission.submittedAt)
    if (submission.proxySubmitter) {
      return I18n.t('Submitted by %{proxy} on %{date}', {
        proxy: submission.proxySubmitter,
        date: formattedDate,
      })
    }
    return I18n.t('Submitted on %{date}', {date: formattedDate})
  }

  const outOfText = () => {
    const {gradingType, pointsPossible} = assignment

    if (submission.excused) {
      return I18n.t('Excused')
    } else if (gradingType === 'gpa_scale') {
      return ''
    } else if (gradingType === 'letter_grade' || gradingType === 'pass_fail') {
      return I18n.t('(%{score} out of %{points})', {
        points: I18n.n(pointsPossible),
        score: submission.enteredScore,
      })
    } else if (pointsPossible === null || pointsPossible === undefined) {
      return I18n.t('No points possible')
    } else {
      return I18n.t('(out of %{points})', {points: I18n.n(pointsPossible)})
    }
  }

  const submitGrade = async () => {
    await submit(assignment, submission, gradeInput)
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
                {gradebookOptions.anonymizeStudents ? (
                  // TOOD: handle anonymous names
                  <Text size="small">
                    <View as="strong">Grade for: anonymous_name</View>
                  </Text>
                ) : (
                  <Text size="small">
                    <View as="strong">{`Grade for ${currentStudent?.name} - ${assignment.name}`}</View>
                  </Text>
                )}

                <SubmissionStatus submission={submission} />
              </View>
            </View>
            <View as="span">
              <Text size="small">{submitterPreviewText()}</Text>
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
                {outOfText()}
              </View>
            </View>

            {assignment.gradingType !== 'pass_fail' && (
              <div
                className="checkbox"
                style={{padding: 12, margin: '15px 0 0 0', background: '#eee', borderRadius: 5}}
              >
                <label className="checkbox" htmlFor="excuse_assignment">
                  <input type="checkbox" id="excuse_assignment" name="excuse_assignment" />
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
      <SubmissionDetailModal modalOpen={modalOpen} handleClose={() => setModalOpen(false)} />
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

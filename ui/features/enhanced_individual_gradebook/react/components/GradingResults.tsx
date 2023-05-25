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

import React from 'react'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import {AssignmentConnection, GradebookOptions} from '../../types'
import {useCurrentStudentInfo} from '../hooks/useCurrentStudentInfo'
import {TextInput} from '@instructure/ui-text-input'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  courseId: string
  studentId?: string | null
  assignment?: AssignmentConnection
  gradebookOptions: GradebookOptions // TODO: get this from gradebook settings
}

export default function GradingResults({assignment, courseId, gradebookOptions, studentId}: Props) {
  const {currentStudent, studentSubmissions} = useCurrentStudentInfo(courseId, studentId)
  const submission = studentSubmissions.find(s => s.assignmentId === assignment?.id)

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

  const renderSubmissionStatus = () => {
    switch (submission.state) {
      case 'late':
        return (
          <span className="late-pill">
            <ul className="pill pill-align error">
              <li className="error">
                <strong>late</strong>
              </li>
            </ul>
          </span>
        )
      case 'missing':
        return (
          <span className="missing-pill">
            <ul className="pill pill-align error">
              <li className="error">
                <strong>missing</strong>
              </li>
            </ul>
          </span>
        )
      case 'extended':
        return (
          <span className="extended-pill">
            <ul className="pill pill-align error">
              <li className="error">
                <strong>extended</strong>
              </li>
            </ul>
          </span>
        )
      default:
        return null
    }
  }

  const submitterPreviewText = () => {
    if (!submission.submissionType) {
      return I18n.t('Has not submitted')
    }
    if (submission.proxySubmitter) {
      return I18n.t('Submitted by %{proxy} on %{date}', {
        proxy: submission.proxySubmitter,
        date: submission.submittedAt, // TODO: format date
      })
    }
    // TODO: format date
    return I18n.t('Submitted on %{date}', {date: submission.submittedAt})
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

  return (
    <>
      <View as="div">
        <View as="div" className="row-fluid">
          <View as="div" className="span4">
            <View as="h2">{I18n.t('Grading')}</View>
          </View>
          <View as="div" className="span8 pad-box top-only">
            <View as="div">
              {/* TODO: fix text size */}
              <View as="span">
                {gradebookOptions.anonymizeStudents ? (
                  // TOOD: handle anonymous names
                  <View as="strong">Grade for: anonymous_name</View>
                ) : (
                  <View as="strong">{`Grade for ${currentStudent?.name} - ${assignment.name}`}</View>
                )}

                {renderSubmissionStatus()}
              </View>
            </View>
            {/* TODO: fix text size */}
            <View as="span">{submitterPreviewText()}</View>

            <View as="div" className="grade">
              <TextInput display="inline-block" width="14rem" value={submission.grade} />
              <View as="span" margin="0 0 0 small">
                {outOfText()}
              </View>
            </View>
          </View>
        </View>
      </View>
    </>
  )
}

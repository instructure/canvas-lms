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

import $ from 'jquery'
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import type {
  AssignmentConnection,
  SubmissionConnection,
  SubmissionGradeChange,
} from '../../../types'
import {
  mapToSubmissionGradeChange,
  isInPastGradingPeriodAndNotAdmin,
} from '../../../utils/gradebookUtils'
import type {Submission} from '../../../../../api.d'

async function loadCurveGradesDialog() {
  return (await import('@canvas/grading/jquery/CurveGradesDialog')).default
}

const I18n = useI18nScope('enhanced_individual_gradebook')

type StudentAssignmentMap = {
  [userId: string]: {
    [assignmentId: string]: SubmissionConnection
  }
}
type Props = {
  assignment: AssignmentConnection
  submissions: SubmissionConnection[]
  contextUrl?: string | null
  handleGradeChange: (updatedSubmissions: SubmissionGradeChange[]) => void
}
export function CurveGradesModal({assignment, contextUrl, submissions, handleGradeChange}: Props) {
  const studentAssignmentMap = submissions.reduce((studentMap, submission) => {
    const {userId, assignmentId} = submission
    studentMap[userId] = {
      [`assignment_${assignmentId}`]: submission,
    }
    return studentMap
  }, {} as StudentAssignmentMap)

  const assignmentDetails = {
    id: assignment.id,
    points_possible: assignment.pointsPossible,
    grading_type: assignment.gradingType,
    name: assignment.name,
  }

  if (!contextUrl) {
    return null
  }

  const showDialog = async () => {
    const CurveGradesDialog = await loadCurveGradesDialog()
    const dialogProps = {
      assignment: assignmentDetails,
      students: studentAssignmentMap,
      context_url: contextUrl,
    }
    const dialog = new CurveGradesDialog(dialogProps)
    dialog.show(() => {})
  }

  $.subscribe('submissions_updated', submissions => {
    const mappedSubmissions: SubmissionGradeChange[] = submissions.map((submission: Submission) =>
      mapToSubmissionGradeChange(submission)
    )
    handleGradeChange(mappedSubmissions)
  })

  return (
    <Button
      disabled={isInPastGradingPeriodAndNotAdmin(assignment)}
      color="secondary"
      onClick={showDialog}
      data-testid="curve-grades-button"
    >
      {I18n.t('Curve Grades')}
    </Button>
  )
}

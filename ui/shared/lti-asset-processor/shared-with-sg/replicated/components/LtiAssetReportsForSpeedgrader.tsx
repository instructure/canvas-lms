/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {LtiAssetReports} from './LtiAssetReports'
import {useLtiAssetProcessorsAndReportsForSpeedgrader} from '../hooks/useLtiAssetProcessorsAndReportsForSpeedgrader'
import {
  extractStudentUserIdOrAnonymousId,
  type StudentUserIdOrAnonymousId,
} from '../queries/getLtiAssetReports'

/**
 * LtiAssetReports component is also used for Student View / Gradebook page.
 * This component is specifically for Asset Reports shown in Speedgrader .
 */
export type LtiAssetReportsForSpeedgraderProps = {
  assignmentId: string

  attempt: number
  submissionType: string
  attachments: {_id: string; displayName: string}[]
} & StudentUserIdOrAnonymousId

// If we ever need to use this outside of speedgrader, we should probably change
// ResubmitLtiAssetReportsParams to take userId + anonymousId and move this
// function next to resubmitPath()
function studentIdForResubmission(student: StudentUserIdOrAnonymousId): string | null {
  if (student.studentAnonymousId !== null) {
    return `anonymous:${student.studentAnonymousId}`
  }
  return student.studentUserId
}

export function LtiAssetReportsForSpeedgrader(
  props: LtiAssetReportsForSpeedgraderProps,
): JSX.Element | null {
  const {assignmentId, submissionType} = props
  const processorsAndReports = useLtiAssetProcessorsAndReportsForSpeedgrader({
    assignmentId,
    submissionType,
    ...extractStudentUserIdOrAnonymousId(props),
  })
  if (!processorsAndReports) {
    return null
  }
  const {assetProcessors, assetReports, compatibleSubmissionType} = processorsAndReports

  return (
    <LtiAssetReports
      attachments={props.attachments}
      reports={assetReports}
      assetProcessors={assetProcessors}
      attempt={props.attempt.toString()}
      submissionType={compatibleSubmissionType}
      studentIdForResubmission={studentIdForResubmission(props) ?? undefined}
      showDocumentDisplayName={true}
    />
  )
}

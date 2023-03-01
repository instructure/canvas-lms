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

import {AssignedAssessments} from '../../../../api.d'

export const getRedirectUrlToFirstPeerReview = (
  assignedAssessments: AssignedAssessments[] = []
) => {
  const assessment = assignedAssessments.find(assignedAssessment =>
    isAvailableToReview(assignedAssessment)
  )
  if (!assessment) {
    return
  }
  let url = `/courses/${ENV.COURSE_ID}/assignments/${ENV.ASSIGNMENT_ID}`
  if (assessment.anonymizedUser) {
    url += `?reviewee_id=${assessment.anonymizedUser._id}`
  } else {
    url += `?anonymous_asset_id=${assessment.anonymousId}`
  }
  return url
}

export const availableReviewCount = (assignedAssessments: AssignedAssessments[] = []): number => {
  return assignedAssessments.filter(isAvailableToReview).length
}

export const assignedAssessmentsCount = (
  assignedAssessments: AssignedAssessments[] = []
): number => {
  return assignedAssessments.filter(assessment => assessment.workflowState === 'assigned').length
}

type AvailableAndUnavailableCounts = {
  availableCount: number
  unavailableCount: number
}

export const availableAndUnavailableCounts = (
  assignedAssessments: AssignedAssessments[] = []
): AvailableAndUnavailableCounts => {
  return assignedAssessments.reduce(
    (prev, curr) => {
      if (curr.workflowState !== 'assigned') return prev

      if (curr.assetSubmissionType == null) {
        prev.unavailableCount++
      } else {
        prev.availableCount++
      }

      return prev
    },
    {availableCount: 0, unavailableCount: 0}
  )
}

export const isAvailableToReview = (assessment: AssignedAssessments): boolean => {
  return assessment.assetSubmissionType !== null && assessment.workflowState === 'assigned'
}

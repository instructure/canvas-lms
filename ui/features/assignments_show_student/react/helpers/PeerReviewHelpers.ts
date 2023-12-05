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

import type {AssignedAssessments} from '../../../../api.d'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {PeerReviewSubheader} from '../components/PeerReviewPromptModal'

const I18n = useI18nScope('assignments_2_peer_review')

export const getRedirectUrlToFirstPeerReview = (
  assignedAssessments: AssignedAssessments[] = []
) => {
  const assessment = assignedAssessments.find(assignedAssessment =>
    isAvailableToReview(assignedAssessment)
  )
  if (!assessment) {
    return
  }
  return getPeerReviewUrl(assessment)
}

export const getPeerReviewUrl = (assessment: AssignedAssessments) => {
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

export const COMPLETED_PEER_REVIEW_TEXT = I18n.t('You have completed your Peer Reviews!')

export const getPeerReviewHeaderText = (
  availableCount: number,
  unavailableCount: number
): string[] => {
  const headerText =
    availableCount > 0
      ? headerTextTemplate(availableCount)
      : unavailableCount > 0
      ? headerTextTemplate(unavailableCount)
      : COMPLETED_PEER_REVIEW_TEXT
  return [headerText]
}

const headerTextTemplate = (count: number): string => {
  return I18n.t(
    {
      one: 'You have 1 more Peer Review to complete.',
      other: 'You have %{count} more Peer Reviews to complete.',
    },
    {count}
  )
}

export const getPeerReviewSubHeaderText = (
  availableCount: number,
  unavailableCount: number
): PeerReviewSubheader[] => {
  if (!availableCount && unavailableCount) {
    return [
      {
        props: {size: 'medium'},
        text: I18n.t('The submission is not available just yet.'),
      },
      {
        props: {size: 'medium'},
        text: I18n.t('Please check back soon.'),
      },
    ]
  }

  return []
}

export const getPeerReviewButtonText = (
  availableCount: number,
  unavailableCount: number
): string | null => {
  return availableCount || unavailableCount ? I18n.t('Next Peer Review') : null
}

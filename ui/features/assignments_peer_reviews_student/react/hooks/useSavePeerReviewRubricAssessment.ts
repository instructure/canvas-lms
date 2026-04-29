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

import {useMutation} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {RubricAssessmentData} from '@canvas/rubrics/react/types/rubric'
import qs from 'qs'

interface SavePeerReviewRubricAssessmentParams {
  assessments: RubricAssessmentData[]
  courseId: string
  rubricAssociationId: string
  revieweeUserId?: string
  anonymousId?: string
}

const savePeerReviewRubricAssessment = async ({
  assessments,
  courseId,
  rubricAssociationId,
  revieweeUserId,
  anonymousId,
}: SavePeerReviewRubricAssessmentParams) => {
  const rubricAssessment: Record<string, any> = {
    assessment_type: 'peer_review',
  }

  if (anonymousId) {
    rubricAssessment.anonymous_id = anonymousId
  } else if (revieweeUserId) {
    rubricAssessment.user_id = revieweeUserId
  }

  assessments.forEach(assessment => {
    const criterionKey = `criterion_${assessment.criterionId}`
    rubricAssessment[criterionKey] = {
      points: assessment.points,
      comments: assessment.comments || '',
      save_comment: assessment.saveCommentsForLater ? 1 : 0,
      description: assessment.description || '',
    }
    if (assessment.id) {
      rubricAssessment[criterionKey].rating_id = assessment.id
    }
  })

  const params = {
    rubric_assessment: rubricAssessment,
    _method: 'POST',
  }

  return doFetchApi({
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    path: `/courses/${courseId}/rubric_associations/${rubricAssociationId}/assessments`,
    body: qs.stringify(params),
  })
}

export const useSavePeerReviewRubricAssessment = () => {
  return useMutation({
    mutationFn: savePeerReviewRubricAssessment,
  })
}

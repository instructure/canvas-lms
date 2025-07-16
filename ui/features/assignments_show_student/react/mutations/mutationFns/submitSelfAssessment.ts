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

import qs from 'qs'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {RubricSelfAssessmentData, Rubric} from '@canvas/rubrics/react/types/rubric'
import {parseCriterion} from '../../helpers/RubricHelpers'

type SubmitSelfAssessmentParams = {
  assessment: RubricSelfAssessmentData
  rubric: Rubric
  rubricAssociationId: string
}
export const submitSelfAssessment = async ({
  assessment,
  rubric,
  rubricAssociationId,
}: SubmitSelfAssessmentParams) => {
  const assessmentParams = assessment.data.reduce(
    (result: any, item: any) => {
      return {...result, ...parseCriterion(item, rubric)}
    },
    {
      assessment_type: 'self_assessment',
      user_id: ENV.current_user.id,
    },
  )
  const body = {
    rubric_assessment: assessmentParams,
    _method: 'POST',
  }

  await doFetchApi({
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    path: `/courses/${ENV.COURSE_ID}/rubric_associations/${rubricAssociationId}/assessments`,
    body: qs.stringify(body),
  })
}

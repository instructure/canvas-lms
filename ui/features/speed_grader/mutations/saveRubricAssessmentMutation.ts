/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {RubricAssessmentData} from '@canvas/rubrics/react/types/rubric'

export default function saveRubricAssessementMutation(
  assessments: RubricAssessmentData[],
  userId: string
) {
  // @ts-expect-error
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const {assessment_user_id, anonymous_id, assessment_type} = ENV.RUBRIC_ASSESSMENT ?? {}

  // TODO: anonymous grading stuff here, see convertSubmittedAssessmentin RubricAssessmentContainerWrapper
  // if (assessment_user_id) {
  //   data['rubric_assessment[user_id]'] = assessment_user_id
  // } else {
  //   data['rubric_assessment[anonymous_id]'] = anonymous_id
  // }
  const rubric_assessment: Record<string, any> = {}
  rubric_assessment.user_id = userId
  rubric_assessment.assessment_type = assessment_type

  assessments.forEach(assessment => {
    const pre = `criterion_${assessment.criterionId}`
    rubric_assessment[pre] = {}
    rubric_assessment[pre].points = assessment.points
    rubric_assessment[pre].comments = assessment.comments
    rubric_assessment[pre].save_comment = assessment.saveCommentsForLater ? '1' : '0'
    rubric_assessment[pre].description = assessment.description
    if (assessment.id) {
      rubric_assessment[pre].rating_id = assessment.id
    }
  })
  const data: any = {rubric_assessment}
  // TODO: moderated grading support here, see saveRubricAssessment in speed_grader.tsx
  // TODO: anonymous grading support, see saveRubricAssessment in speed_grader.tsx

  data.graded_anonymously = false
  // @ts-expect-error
  const url = window.ENV.update_rubric_assessment_url!
  const method = 'POST'
  return doFetchApi({
    path: url,
    method,
    body: data,
  })
}

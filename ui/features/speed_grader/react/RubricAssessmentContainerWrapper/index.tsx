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

import React from 'react'
import {RubricAssessmentContainer} from '@canvas/rubrics/react/RubricAssessment'
import useStore from '../../stores'
import type {RubricAssessmentData} from '@canvas/rubrics/react/types/rubric'
import {
  mapRubricAssessmentDataUnderscoredKeysToCamelCase,
  mapRubricUnderscoredKeysToCamelCase,
  type RubricOutcomeUnderscore,
  type RubricUnderscoreType,
} from '@canvas/rubrics/react/utils'
import {Transition} from '@instructure/ui-motion'
import {View} from '@instructure/ui-view'

const convertSubmittedAssessment = (assessments: RubricAssessmentData[]): any => {
  const {assessment_user_id, anonymous_id, assessment_type} = ENV.RUBRIC_ASSESSMENT ?? {}

  const data: {[key: string]: string | undefined | number} = {}
  if (assessment_user_id) {
    data['rubric_assessment[user_id]'] = assessment_user_id
  } else {
    data['rubric_assessment[anonymous_id]'] = anonymous_id
  }

  data['rubric_assessment[assessment_type]'] = assessment_type

  assessments.forEach(assessment => {
    const pre = `rubric_assessment[criterion_${assessment.criterionId}]`
    data[pre + '[points]'] = assessment.points
    data[pre + '[comments]'] = assessment.comments
    data[pre + '[save_comment]'] = assessment.saveCommentsForLater ? '1' : '0'
    data[pre + '[description]'] = assessment.description
    if (assessment.id) {
      data[pre + '[rating_id]'] = assessment.id
    }
  })

  return data
}

type RubricAssessmentContainerWrapperProps = {
  rubric: RubricUnderscoreType
  rubricOutcomeData?: RubricOutcomeUnderscore[]
  onDismiss: () => void
  onSave: (assessmentData: any) => void
}
export default ({
  rubric,
  rubricOutcomeData,
  onDismiss,
  onSave,
}: RubricAssessmentContainerWrapperProps) => {
  const {
    currentStudentAvatarPath,
    currentStudentName,
    rubricAssessmentTrayOpen,
    rubricHidePoints,
    rubricSavedComments = {},
    selfAssessment,
    studentAssessment,
  } = useStore()

  const handleSubmit = (assessmentData: RubricAssessmentData[]) => {
    const data = convertSubmittedAssessment(assessmentData)
    onSave(data)
  }

  const mappedRubric = mapRubricUnderscoredKeysToCamelCase(rubric, rubricOutcomeData)
  const mappedAssessmentData = mapRubricAssessmentDataUnderscoredKeysToCamelCase(
    studentAssessment?.data ?? [],
  )

  const mappedSelfAssessment = selfAssessment
    ? mapRubricAssessmentDataUnderscoredKeysToCamelCase(selfAssessment.data)
    : undefined

  const isPeerReview = studentAssessment?.assessment_type === 'peer_review'
  const rubricAssessmentData = isPeerReview ? [] : mappedAssessmentData

  return (
    <Transition
      unmountOnExit={true}
      transitionOnMount={false}
      in={rubricAssessmentTrayOpen}
      type="fade"
    >
      <View as="div">
        <RubricAssessmentContainer
          criteria={mappedRubric?.criteria ?? []}
          hidePoints={rubricHidePoints}
          isPreviewMode={false}
          isPeerReview={false}
          isFreeFormCriterionComments={mappedRubric?.freeFormCriterionComments ?? false}
          isStandaloneContainer={true}
          ratingOrder={mappedRubric?.ratingOrder ?? 'descending'}
          rubricTitle={rubric.title}
          rubricAssessmentData={rubricAssessmentData}
          rubricSavedComments={rubricSavedComments}
          selfAssessment={mappedSelfAssessment}
          selfAssessmentDate={selfAssessment?.updated_at}
          submissionUser={{name: currentStudentName, avatarUrl: currentStudentAvatarPath}}
          onDismiss={onDismiss}
          onSubmit={handleSubmit}
        />
      </View>
    </Transition>
  )
}

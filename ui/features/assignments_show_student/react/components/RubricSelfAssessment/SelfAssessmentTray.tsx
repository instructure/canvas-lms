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

import {showFlashSuccess, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {RubricAssessmentTray, isRubricComplete} from '@canvas/rubrics/react/RubricAssessment'
import {
  RubricAssessmentData,
  Rubric,
  RubricSelfAssessmentData,
} from '@canvas/rubrics/react/types/rubric'
import {useSubmitSelfAssessment} from '../../mutations/useSubmitSelfAssessment'
import useStore from '../stores/index'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useContext} from 'react'

const I18n = createI18nScope('assignments_2_student_content_rubric_self_assessment')

type SelfAssessmentTrayProps = {
  hidePoints: boolean
  isOpen: boolean
  isPreviewMode: boolean
  onDismiss: () => void
  rubric: Rubric
  rubricAssociationId: string
  selfAssessmentData: RubricAssessmentData[]
  handleOnSubmitting: (isSubmitting: boolean, assessment?: RubricSelfAssessmentData) => void
  handleOnSuccess: () => void
}
export const SelfAssessmentTray = ({
  hidePoints,
  isOpen,
  isPreviewMode,
  onDismiss,
  rubric,
  rubricAssociationId,
  selfAssessmentData,
  handleOnSubmitting,
  handleOnSuccess,
}: SelfAssessmentTrayProps) => {
  const {setOnFailure} = useContext(AlertManagerContext)
  const {mutateAsync: submitSelfAssessment} = useSubmitSelfAssessment()

  const formatAssessmentForSubmission = (assessment: RubricAssessmentData[]) => {
    const assessmentFormatted: RubricSelfAssessmentData = {
      score: assessment.reduce((prev, curr) => prev + (curr.points ?? 0), 0),
      data: assessment.map(criterionAssessment => {
        const {points} = criterionAssessment
        const valid = !Number.isNaN(points)
        return {
          ...criterionAssessment,
          criterion_id: criterionAssessment.criterionId,
          points: {
            text: points?.toString(),
            valid,
            value: points,
          },
        }
      }),
    }
    return assessmentFormatted
  }

  const validateAndSubmitSelfAssessment = async (rubricAssessment: RubricAssessmentData[]) => {
    if (
      !isRubricComplete({
        criteria: rubric.criteria ?? [],
        hidePoints,
        isFreeFormCriterionComments: !!rubric.freeFormCriterionComments,
        rubricAssessment,
      })
    ) {
      setOnFailure(I18n.t('Incomplete Self Assessment'))
      return
    }

    const assessmentFormatted = formatAssessmentForSubmission(rubricAssessment)
    await handleSubmitSelfAssessment(assessmentFormatted)
  }

  const handleSubmitSelfAssessment = async (assessment: RubricSelfAssessmentData) => {
    try {
      handleOnSubmitting(true, assessment)
      await submitSelfAssessment({assessment, rubricAssociationId, rubric})
      showFlashSuccess(I18n.t('Self Assessment was successfully submitted'))()
      handleOnSuccess()
    } catch (_error) {
      useStore.setState({selfAssessment: null})
      const errorMessage = I18n.t('Error submitting self assessment')
      showFlashError(errorMessage)()
    }
    handleOnSubmitting(false)
  }

  return (
    <RubricAssessmentTray
      currentUserId={ENV.current_user_id ?? ''}
      hidePoints={hidePoints}
      isOpen={isOpen}
      isPreviewMode={isPreviewMode}
      isSelfAssessment={true}
      isPeerReview={false}
      onDismiss={onDismiss}
      rubricAssessmentData={selfAssessmentData}
      rubric={rubric}
      viewModeOverride="horizontal"
      onSubmit={validateAndSubmitSelfAssessment}
    />
  )
}

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

import {useMemo} from 'react'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'
import {SelfAssessmentTray} from './SelfAssessmentTray'
import {RubricUnderscoreType} from '@canvas/rubrics/react/utils'
import useStore from '../stores/index'
import {getPointsValue} from '../../helpers/SubmissionHelpers'

type SelfAssessmentTrayClientProps = {
  hidePoints: boolean
  isOpen: boolean
  isPreviewMode: boolean
  onDismiss: () => void
  rubric: RubricUnderscoreType
  rubricAssociationId: string
  handleOnSubmitting: (assessment: any) => void
  handleOnSuccess: () => void
}
export const SelfAssessmentTrayClient = ({
  hidePoints,
  isOpen,
  isPreviewMode,
  onDismiss,
  rubric,
  rubricAssociationId,
  handleOnSubmitting,
  handleOnSuccess,
}: SelfAssessmentTrayClientProps) => {
  const selfAssessment = useStore(state => state.selfAssessment)

  const rubricTrayData = useMemo(() => {
    if (!rubric) {
      return null
    }

    return {
      id: rubric.id,
      criteriaCount: rubric.criteria?.length ?? 0,
      title: rubric.title,
      ratingOrder: rubric.rating_order,
      buttonDisplay: rubric.button_display,
      freeFormCriterionComments: rubric.free_form_criterion_comments,
      pointsPossible: rubric.points_possible,
      criteria: (rubric.criteria || []).map(criterion => {
        return {
          ...criterion,
          longDescription: criterion.long_description,
          criterionUseRange: criterion.criterion_use_range,
          learningOutcomeId: criterion.learning_outcome_id,
          ignoreForScoring: criterion.ignore_for_scoring,
          masteryPoints: criterion.mastery_points,
          ratings: criterion.ratings.map(rating => {
            return {
              ...rating,
              longDescription: rating.long_description,
              points: rating.points,
              criterionId: criterion.id,
            }
          }),
        }
      }),
    }
  }, [rubric])

  const selfAssessmentData = useMemo(
    () =>
      (selfAssessment?.data ?? []).map(data => {
        return {
          ...data,
          criterionId: data.criterion_id,
          points: getPointsValue(data.points),
        }
      }),
    [selfAssessment],
  )

  if (!rubricTrayData) {
    return null
  }

  return (
    <QueryClientProvider client={queryClient}>
      <SelfAssessmentTray
        hidePoints={hidePoints}
        isOpen={isOpen}
        isPreviewMode={isPreviewMode}
        onDismiss={onDismiss}
        rubric={rubricTrayData}
        selfAssessmentData={selfAssessmentData}
        rubricAssociationId={rubricAssociationId}
        handleOnSubmitting={handleOnSubmitting}
        handleOnSuccess={handleOnSuccess}
      />
    </QueryClientProvider>
  )
}

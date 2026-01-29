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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import {RubricAssessmentContainerWrapper} from '@canvas/rubrics/react/RubricAssessment'
import type {RubricAssessmentData} from '@canvas/rubrics/react/types/rubric'
import type {ViewMode} from '@canvas/rubrics/react/RubricAssessment/ViewModeSelect'
import type {
  Assignment,
  RubricCriterion,
  RubricRating,
} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

const I18n = createI18nScope('peer_reviews_student')

interface RubricPanelProps {
  assignment: Assignment
  rubricAssessmentData: RubricAssessmentData[]
  rubricViewMode: ViewMode
  isPeerReviewCompleted: boolean
  rubricAssessmentCompleted: boolean
  onClose: () => void
  onSubmit: (assessment: RubricAssessmentData[]) => void
  onViewModeChange: (mode: ViewMode) => void
  isReadOnly?: boolean
}

export const RubricPanel: React.FC<RubricPanelProps> = ({
  assignment,
  rubricAssessmentData,
  rubricViewMode,
  isPeerReviewCompleted,
  rubricAssessmentCompleted,
  onClose,
  onSubmit,
  onViewModeChange,
  isReadOnly = false,
}) => {
  if (!assignment.rubric) {
    return null
  }

  return (
    <Flex.Item
      as="div"
      direction="column"
      size="327px"
      height="100%"
      padding="small"
      overflowY="auto"
    >
      <Flex as="div" direction="column" justifyItems="space-between" height="100%">
        <Flex.Item>
          <Flex as="div" direction="row" justifyItems="space-between">
            <Flex.Item>
              <Heading variant="titleModule" level="h2">
                {I18n.t('Peer Review Rubric')}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                screenReaderLabel={I18n.t('Close Rubric')}
                size="small"
                onClick={onClose}
                data-testid="close-rubric-button"
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          <RubricAssessmentContainerWrapper
            buttonDisplay={assignment.rubric.button_display ?? 'level'}
            criteria={assignment.rubric.criteria.map((criterion: RubricCriterion) => ({
              id: criterion._id,
              description: criterion.description,
              longDescription: criterion.long_description ?? '',
              points: criterion.points,
              criterionUseRange: criterion.criterion_use_range ?? false,
              learningOutcomeId: criterion.learning_outcome_id ?? undefined,
              ignoreForScoring: criterion.ignore_for_scoring ?? false,
              masteryPoints: criterion.mastery_points ?? undefined,
              ratings: criterion.ratings.map((rating: RubricRating) => ({
                id: rating._id,
                description: rating.description,
                longDescription: rating.long_description ?? '',
                points: rating.points,
                criterionId: criterion._id,
              })),
            }))}
            currentUserId={ENV.current_user_id?.toString() ?? ''}
            hidePoints={assignment.rubricAssociation?.hide_points ?? false}
            isPreviewMode={isPeerReviewCompleted || rubricAssessmentCompleted || isReadOnly}
            isPeerReview={true}
            isFreeFormCriterionComments={assignment.rubric.free_form_criterion_comments ?? false}
            ratingOrder={assignment.rubric.ratingOrder ?? 'descending'}
            rubricTitle={assignment.rubric.title}
            pointsPossible={assignment.rubric.points_possible}
            rubricAssessmentData={rubricAssessmentData}
            viewModeOverride={rubricViewMode}
            onDismiss={onClose}
            onSubmit={onSubmit}
            onViewModeChange={onViewModeChange}
          />
        </Flex.Item>
      </Flex>
    </Flex.Item>
  )
}

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

import React, {useRef, useEffect, forwardRef, useImperativeHandle} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import {
  RubricAssessmentContainerWrapper,
  RubricAssessmentTray,
} from '@canvas/rubrics/react/RubricAssessment'
import type {RubricAssessmentData} from '@canvas/rubrics/react/types/rubric'
import type {ViewMode} from '@canvas/rubrics/react/RubricAssessment/ViewModeSelect'
import type {
  Assignment,
  RubricCriterion,
  RubricRating,
} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

const I18n = createI18nScope('peer_reviews_student')

export interface RubricPanelHandle {
  focusCloseButton: () => void
}

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
  autoFocusCloseButton?: boolean
  isMobile?: boolean
}

export const RubricPanel = forwardRef<RubricPanelHandle, RubricPanelProps>(
  (
    {
      assignment,
      rubricAssessmentData,
      rubricViewMode,
      isPeerReviewCompleted,
      rubricAssessmentCompleted,
      onClose,
      onSubmit,
      onViewModeChange,
      isReadOnly = false,
      autoFocusCloseButton = false,
      isMobile = false,
    },
    ref,
  ) => {
    const closeButtonRef = useRef<HTMLButtonElement | null>(null)

    useImperativeHandle(
      ref,
      () => ({
        focusCloseButton: () => closeButtonRef.current?.focus(),
      }),
      [],
    )

    useEffect(() => {
      if (autoFocusCloseButton) {
        closeButtonRef.current?.focus()
      }
    }, [autoFocusCloseButton])

    if (!assignment.rubric) {
      return null
    }

    const hidePoints = assignment.rubricAssociation?.hidePoints ?? false
    const isFreeFormCriterionComments = assignment.rubric.freeFormCriterionComments ?? false

    const mappedCriteria = assignment.rubric.criteria.map((criterion: RubricCriterion) => ({
      id: criterion._id,
      description: criterion.description,
      longDescription: criterion.longDescription ?? '',
      points: criterion.points,
      criterionUseRange: criterion.criterionUseRange ?? false,
      learningOutcomeId: criterion.learningOutcomeId ?? undefined,
      ignoreForScoring: criterion.ignoreForScoring ?? false,
      masteryPoints: criterion.masteryPoints ?? undefined,
      ratings: criterion.ratings.map((rating: RubricRating) => ({
        id: rating._id,
        description: rating.description,
        longDescription: rating.longDescription ?? '',
        points: rating.points,
        criterionId: criterion._id,
      })),
    }))

    if (isMobile) {
      return (
        <RubricAssessmentTray
          isOpen={true}
          currentUserId={ENV.current_user_id?.toString() ?? ''}
          hidePoints={hidePoints}
          isPreviewMode={isPeerReviewCompleted || rubricAssessmentCompleted || isReadOnly}
          isPeerReview={true}
          rubric={{
            title: assignment.rubric.title,
            criteria: mappedCriteria,
            ratingOrder: assignment.rubric.ratingOrder ?? 'descending',
            freeFormCriterionComments: isFreeFormCriterionComments,
            pointsPossible: assignment.rubric.pointsPossible,
            buttonDisplay: assignment.rubric.buttonDisplay ?? 'level',
          }}
          rubricAssessmentData={rubricAssessmentData}
          viewModeOverride={rubricViewMode}
          onDismiss={onClose}
          onSubmit={onSubmit}
        />
      )
    }

    return (
      <Flex.Item
        as="div"
        direction="column"
        size="327px"
        height="100%"
        padding="small"
        overflowY="auto"
        id="rubric-panel"
      >
        <Flex as="div" direction="column">
          <Flex.Item>
            <Flex as="div" direction="row" justifyItems="space-between">
              <Flex.Item>
                <Heading variant="titleModule" level="h2">
                  {I18n.t('Peer Review Rubric')}
                </Heading>
              </Flex.Item>
              <Flex.Item padding="xx-small">
                <CloseButton
                  elementRef={(el: Element | null) => {
                    closeButtonRef.current = el as HTMLButtonElement
                  }}
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
              isStandaloneContainer={true}
              buttonDisplay={assignment.rubric.buttonDisplay ?? 'level'}
              criteria={mappedCriteria}
              currentUserId={ENV.current_user_id?.toString() ?? ''}
              hidePoints={hidePoints}
              isPreviewMode={isPeerReviewCompleted || rubricAssessmentCompleted || isReadOnly}
              isPeerReview={true}
              isFreeFormCriterionComments={isFreeFormCriterionComments}
              ratingOrder={assignment.rubric.ratingOrder ?? 'descending'}
              rubricTitle={assignment.rubric.title}
              pointsPossible={assignment.rubric.pointsPossible}
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
  },
)

RubricPanel.displayName = 'RubricPanel'

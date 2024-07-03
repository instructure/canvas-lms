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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import {Tray} from '@instructure/ui-tray'
import {RubricAssessmentContainer, type ViewMode} from './RubricAssessmentContainer'
import type {
  Rubric,
  RubricAssessmentData,
  RubricAssessmentSelect,
  UpdateAssessmentData,
} from '../types/rubric'
import {findCriterionMatchingRatingIndex} from './utils/rubricUtils'

const I18n = useI18nScope('rubrics-assessment-tray')

export type RubricAssessmentTrayProps = {
  hidePoints?: boolean
  isLoading?: boolean
  isOpen: boolean
  isPreviewMode: boolean
  isPeerReview?: boolean
  rubric?: Pick<Rubric, 'title' | 'criteria' | 'ratingOrder' | 'freeFormCriterionComments'>
  rubricAssessmentData: RubricAssessmentData[]
  rubricAssessmentId?: string
  rubricAssessors?: RubricAssessmentSelect
  rubricSavedComments?: Record<string, string[]>
  onAccessorChange?: (assessorId: string) => void
  onDismiss: () => void
  onSubmit?: (rubricAssessmentDraftData: RubricAssessmentData[]) => void
}
export const RubricAssessmentTray = ({
  hidePoints = false,
  isOpen,
  isLoading = false,
  isPreviewMode,
  isPeerReview = false,
  rubric,
  rubricAssessmentData,
  rubricAssessmentId = '',
  rubricAssessors = [],
  rubricSavedComments = {},
  onAccessorChange = () => {},
  onDismiss,
  onSubmit,
}: RubricAssessmentTrayProps) => {
  const [viewMode, setViewMode] = useState<ViewMode>('traditional')
  const [rubricAssessmentDraftData, setRubricAssessmentDraftData] = useState<
    RubricAssessmentData[]
  >([])

  useEffect(() => {
    if (isOpen) {
      setRubricAssessmentDraftData(rubricAssessmentData)
    }
  }, [rubricAssessmentData, isOpen])

  const onUpdateAssessmentData = (params: UpdateAssessmentData) => {
    const {criterionId, points, description, comments = '', saveCommentsForLater} = params

    const existingAssessmentIndex = rubricAssessmentDraftData.findIndex(
      a => a.criterionId === criterionId
    )

    const ratingDescription = description ?? ''

    const matchingCriteria = rubric?.criteria?.find(c => c.id === criterionId)
    const matchingRatingIndex = findCriterionMatchingRatingIndex(
      matchingCriteria?.ratings ?? [],
      points,
      matchingCriteria?.criterionUseRange
    )
    const matchingRating = matchingCriteria?.ratings?.[matchingRatingIndex]

    const matchingRatingId = matchingRating?.id ?? ''

    if (existingAssessmentIndex === -1) {
      setRubricAssessmentDraftData([
        ...rubricAssessmentDraftData,
        {
          criterionId,
          points,
          comments,
          id: matchingRatingId,
          commentsEnabled: true,
          description: ratingDescription,
          saveCommentsForLater,
        },
      ])
    } else {
      setRubricAssessmentDraftData(
        rubricAssessmentDraftData.map(a =>
          a.criterionId === criterionId
            ? {
                ...a,
                comments,
                id: matchingRatingId,
                points,
                description: ratingDescription,
                saveCommentsForLater,
              }
            : a
        )
      )
    }
  }

  return (
    <Tray
      label={I18n.t('Rubric Assessment Tray')}
      open={isOpen}
      onDismiss={onDismiss}
      placement="end"
      shouldCloseOnDocumentClick={false}
      size={viewMode === 'traditional' ? 'large' : 'small'}
      id="enhanced-rubric-assessment-tray"
      data-testid="enhanced-rubric-assessment-tray"
    >
      {isLoading || !rubric ? (
        <LoadingIndicator />
      ) : (
        <RubricAssessmentContainer
          criteria={rubric.criteria ?? []}
          hidePoints={hidePoints}
          isPreviewMode={isPreviewMode}
          isPeerReview={isPeerReview}
          isFreeFormCriterionComments={rubric.freeFormCriterionComments ?? false}
          ratingOrder={rubric.ratingOrder ?? 'descending'}
          rubricTitle={rubric.title}
          rubricAssessmentData={rubricAssessmentDraftData}
          rubricAssessmentId={rubricAssessmentId}
          rubricAssessors={rubricAssessors}
          rubricSavedComments={rubricSavedComments}
          selectedViewMode={viewMode}
          onAccessorChange={onAccessorChange}
          onDismiss={onDismiss}
          onSubmit={onSubmit ? () => onSubmit?.(rubricAssessmentDraftData) : undefined}
          onViewModeChange={mode => setViewMode(mode)}
          onUpdateAssessmentData={onUpdateAssessmentData}
        />
      )}
    </Tray>
  )
}

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
import type {Rubric, RubricAssessmentData, UpdateAssessmentData} from '../types/rubric'

const I18n = useI18nScope('rubrics-assessment-tray')

export type RubricAssessmentTrayProps = {
  isLoading?: boolean
  isOpen: boolean
  isPreviewMode: boolean
  rubric?: Pick<Rubric, 'title' | 'criteria' | 'ratingOrder'>
  rubricAssessmentData: RubricAssessmentData[]
  onDismiss: () => void
  onSubmit?: (rubricAssessmentDraftData: RubricAssessmentData[]) => void
}
export const RubricAssessmentTray = ({
  isOpen,
  isLoading = false,
  isPreviewMode,
  rubric,
  rubricAssessmentData,
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
    const {criterionId, points, description, comments = ''} = params

    const existingAssessmentIndex = rubricAssessmentDraftData.findIndex(
      a => a.criterionId === criterionId
    )

    const ratingDescription = description ?? ''

    const matchingRating = rubric?.criteria
      ?.find(c => c.id === criterionId)
      ?.ratings.find(r => r.points === points)

    const matchingRatingId = matchingRating?.id ?? '-1'

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
    >
      {isLoading || !rubric ? (
        <LoadingIndicator />
      ) : (
        <RubricAssessmentContainer
          criteria={rubric.criteria ?? []}
          isPreviewMode={isPreviewMode}
          ratingOrder={rubric.ratingOrder ?? 'descending'}
          rubricTitle={rubric.title}
          rubricAssessmentData={rubricAssessmentDraftData}
          selectedViewMode={viewMode}
          onDismiss={onDismiss}
          onSubmit={() => onSubmit?.(rubricAssessmentDraftData)}
          onViewModeChange={mode => setViewMode(mode)}
          onUpdateAssessmentData={onUpdateAssessmentData}
        />
      )}
    </Tray>
  )
}

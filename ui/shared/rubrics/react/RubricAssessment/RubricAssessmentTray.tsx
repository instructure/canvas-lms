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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import {Tray} from '@instructure/ui-tray'
import {type ViewMode} from './ViewModeSelect'
import type {Rubric, RubricAssessmentData} from '../types/rubric'
import {View} from '@instructure/ui-view'
import useLocalStorage from '@canvas/local-storage'
import * as CONSTANTS from './constants'
import {RubricAssessmentContainerWrapper} from './RubricAssessmentContainerWrapper'

const I18n = createI18nScope('rubrics-assessment-tray')

export type RubricAssessmentTrayProps = {
  currentUserId: string
  hidePoints?: boolean
  isLoading?: boolean
  isOpen: boolean
  isPreviewMode: boolean
  isPeerReview?: boolean
  isSelfAssessment?: boolean
  rubric?: Pick<
    Rubric,
    | 'title'
    | 'criteria'
    | 'ratingOrder'
    | 'freeFormCriterionComments'
    | 'pointsPossible'
    | 'buttonDisplay'
  >
  rubricAssessmentData: RubricAssessmentData[]
  rubricSavedComments?: Record<string, string[]>
  shouldCloseOnDocumentClick?: boolean
  viewModeOverride?: ViewMode
  onDismiss: () => void
  onSubmit?: (rubricAssessmentDraftData: RubricAssessmentData[]) => void
}
export const RubricAssessmentTray = ({
  hidePoints = false,
  isOpen,
  isLoading = false,
  isPreviewMode,
  isPeerReview = false,
  isSelfAssessment = false,
  rubric,
  rubricAssessmentData,
  rubricSavedComments = {},
  shouldCloseOnDocumentClick,
  viewModeOverride,
  onDismiss,
  onSubmit,
}: RubricAssessmentTrayProps) => {
  // Temporarily comment out this code for the release
  // const [viewMode, setViewMode] = useLocalStorage<ViewMode>(
  //   CONSTANTS.RUBRIC_VIEW_MODE_LOCALSTORAGE_KEY(currentUserId),
  //   viewModeOverride ?? CONSTANTS.RUBRIC_VIEW_MODE_DEFAULT,
  // )
  const [viewMode, setViewMode] = useState<ViewMode>(viewModeOverride ?? 'traditional')

  return (
    <Tray
      label={I18n.t('Rubric Assessment Tray')}
      open={isOpen}
      onDismiss={onDismiss}
      placement="end"
      shouldCloseOnDocumentClick={shouldCloseOnDocumentClick}
      size={viewMode === 'traditional' ? 'large' : 'small'}
      id="enhanced-rubric-assessment-tray"
      data-testid="enhanced-rubric-assessment-tray"
    >
      {isLoading || !rubric ? (
        <LoadingIndicator />
      ) : (
        <View as="div" padding="medium medium 0 medium" themeOverride={{paddingMedium: '1rem'}}>
          <RubricAssessmentContainerWrapper
            buttonDisplay={rubric.buttonDisplay ?? 'level'}
            criteria={rubric.criteria ?? []}
            currentUserId={ENV.current_user_id ?? ''}
            hidePoints={hidePoints}
            isPreviewMode={isPreviewMode}
            isPeerReview={isPeerReview}
            isFreeFormCriterionComments={rubric.freeFormCriterionComments ?? false}
            ratingOrder={rubric.ratingOrder ?? 'descending'}
            rubricTitle={rubric.title}
            pointsPossible={rubric.pointsPossible}
            isSelfAssessment={isSelfAssessment}
            rubricAssessmentData={rubricAssessmentData}
            rubricSavedComments={rubricSavedComments}
            viewModeOverride={viewMode}
            onDismiss={onDismiss}
            onSubmit={onSubmit}
            onViewModeChange={mode => setViewMode(mode)}
          />
        </View>
      )}
    </Tray>
  )
}

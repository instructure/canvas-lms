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
import {Tray} from '@instructure/ui-tray'
import {RubricAssessmentContainer, type ViewMode} from './RubricAssessmentContainer'
import type {Rubric, RubricAssessmentData} from '../types/rubric'

const I18n = useI18nScope('rubrics-assessment-tray')

export type RubricAssessmentTrayProps = {
  isOpen: boolean
  isPreviewMode: boolean
  rubric: Pick<Rubric, 'title' | 'criteria' | 'ratingOrder'>
  rubricAssessmentData: RubricAssessmentData[]
  onDismiss: () => void
}
export const RubricAssessmentTray = ({
  isOpen,
  isPreviewMode,
  rubric,
  rubricAssessmentData,
  onDismiss,
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

  const onUpdateAssessmentData = (criterionId: string, points?: number) => {
    if (points === undefined) {
      setRubricAssessmentDraftData(
        rubricAssessmentDraftData.filter(a => a.criterionId !== criterionId)
      )
      return
    }

    const existingAssessment = rubricAssessmentDraftData.find(a => a.criterionId === criterionId)

    if (!existingAssessment) {
      setRubricAssessmentDraftData([
        ...rubricAssessmentDraftData,
        {criterionId, points, comments: '', id: '', commentsEnabled: true},
      ])
    } else {
      setRubricAssessmentDraftData(
        rubricAssessmentDraftData.map(a => (a.criterionId === criterionId ? {...a, points} : a))
      )
    }
  }

  return (
    <Tray
      label={I18n.t('Rubric Assessment')}
      open={isOpen}
      onDismiss={onDismiss}
      placement="end"
      shouldCloseOnDocumentClick={false}
      size={viewMode === 'traditional' ? 'large' : 'small'}
    >
      <RubricAssessmentContainer
        criteria={rubric.criteria ?? []}
        isPreviewMode={isPreviewMode}
        ratingOrder={rubric.ratingOrder ?? 'descending'}
        rubricTitle={rubric.title}
        rubricAssessmentData={rubricAssessmentDraftData}
        selectedViewMode={viewMode}
        onDismiss={onDismiss}
        onViewModeChange={mode => setViewMode(mode)}
        onUpdateAssessmentData={onUpdateAssessmentData}
      />
    </Tray>
  )
}

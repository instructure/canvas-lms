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
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {IconChatLine} from '@instructure/ui-icons'
import {HorizontalButtonDisplay} from './HorizontalButtonDisplay'
import {VerticalButtonDisplay} from './VerticalButtonDisplay'
import type {RubricAssessmentData, RubricCriterion} from '../types/rubric'

const I18n = useI18nScope('rubrics-assessment-tray')

type ModernViewModes = 'horizontal' | 'vertical'

type ModernViewProps = {
  criteria: RubricCriterion[]
  isPreviewMode: boolean
  ratingOrder: string
  rubricAssessmentData: RubricAssessmentData[]
  selectedViewMode: ModernViewModes
  onUpdateAssessmentData: (criteriaId: string, points?: number) => void
}
export const ModernView = ({
  criteria,
  isPreviewMode,
  ratingOrder,
  rubricAssessmentData,
  selectedViewMode,
  onUpdateAssessmentData,
}: ModernViewProps) => {
  return (
    <View as="div" margin="0">
      {criteria.map((criterion, index) => {
        const criterionAssessment = rubricAssessmentData.find(
          data => data.criterionId === criterion.id
        )

        return (
          <CriterionRow
            key={criterion.id}
            criterion={criterion}
            displayHr={index < criteria.length - 1}
            isPreviewMode={isPreviewMode}
            ratingOrder={ratingOrder}
            criterionAssessment={criterionAssessment}
            selectedViewMode={selectedViewMode}
            onUpdateAssessmentData={onUpdateAssessmentData}
          />
        )
      })}
    </View>
  )
}

type CriterionRowProps = {
  criterion: RubricCriterion
  displayHr: boolean
  isPreviewMode: boolean
  ratingOrder: string
  criterionAssessment?: RubricAssessmentData
  selectedViewMode: ModernViewModes
  onUpdateAssessmentData: (criteriaId: string, points?: number) => void
}
export const CriterionRow = ({
  criterion,
  displayHr,
  isPreviewMode,
  ratingOrder,
  criterionAssessment,
  selectedViewMode,
  onUpdateAssessmentData,
}: CriterionRowProps) => {
  const {ratings} = criterion
  const selectedRatingIndex = criterion.ratings.findIndex(
    rating => rating.points === criterionAssessment?.points
  )

  const defaultPoints = criterionAssessment?.points ?? ''

  const [pointsInput, setPointsInput] = useState<string>(defaultPoints.toString())

  const selectRating = (index: number) => {
    if (selectedRatingIndex === index) {
      onUpdateAssessmentData(criterion.id, undefined)
      setPoints('')
      return
    }

    setPoints(ratings[index]?.points.toString() ?? '')
  }

  const setPoints = (value: string) => {
    const points = Number(value)

    if (!value.trim().length || Number.isNaN(points)) {
      onUpdateAssessmentData(criterion.id, undefined)
      setPointsInput('')
      return
    }

    onUpdateAssessmentData(criterion.id, points)
    setPointsInput(points.toString())
  }

  const renderButtonDisplay = () => {
    if (selectedViewMode === 'horizontal' && ratings.length <= 5) {
      return (
        <HorizontalButtonDisplay
          ratings={ratings}
          ratingOrder={ratingOrder}
          selectedRatingIndex={selectedRatingIndex}
          onSelectRating={selectRating}
        />
      )
    }

    return (
      <VerticalButtonDisplay
        ratings={ratings}
        ratingOrder={ratingOrder}
        selectedRatingIndex={selectedRatingIndex}
        onSelectRating={selectRating}
      />
    )
  }

  return (
    <View as="div" margin="0 0 small 0">
      <Flex direction="row-reverse">
        <Flex.Item margin="0 0 0 x-small">
          <Text size="small" weight="bold">
            /{criterion.points}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <TextInput
            renderLabel={<ScreenReaderContent>{I18n.t('Instructor Points')}</ScreenReaderContent>}
            placeholder="--"
            width="2.688rem"
            height="2.375rem"
            value={pointsInput?.toString() ?? ''}
            onChange={(_e, value) => {
              setPoints(value)
            }}
          />
        </Flex.Item>
      </Flex>
      <View as="div">
        <Text size="medium" weight="bold">
          {criterion.description}
        </Text>
      </View>
      <View as="div" margin="xx-small 0 0 0" themeOverride={{marginXxSmall: '.25rem'}}>
        <Text size="small" weight="normal" themeOverride={{fontSizeXSmall: '0.875rem'}}>
          {criterion.longDescription}
        </Text>
      </View>
      <View as="div" margin="small 0 0 0">
        {renderButtonDisplay()}
      </View>
      <View as="div" margin="small 0 0 0">
        <Flex>
          <Flex.Item>
            <IconChatLine />
          </Flex.Item>
          <Flex.Item shouldGrow={true} margin="0 0 0 xx-small">
            <TextInput
              renderLabel={
                <ScreenReaderContent>{I18n.t('Leave criterion comment')}</ScreenReaderContent>
              }
              readOnly={isPreviewMode}
              display="block"
              size="small"
              placeholder={I18n.t('Leave a comment')}
            />
          </Flex.Item>
        </Flex>
      </View>
      {displayHr && <View as="hr" margin="medium 0" />}
    </View>
  )
}

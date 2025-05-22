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

import {useEffect, useState, useRef, FC, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import type {RubricAssessmentData, RubricCriterion, UpdateAssessmentData} from '../types/rubric'
import {rangingFrom, findCriterionMatchingRatingId} from './utils/rubricUtils'
import {TraditionalViewCriterionRating} from './TraditionalViewCriterionRating'

const I18n = createI18nScope('rubrics-assessment-tray')

type TraditionalViewCriterionRatingsProps = {
  criterion: RubricCriterion
  criterionAssessment?: RubricAssessmentData
  criterionSelfAssessment?: RubricAssessmentData
  hasValidationError?: boolean
  hidePoints: boolean
  isPreviewMode: boolean
  ratingOrder: string
  ratingsColumnMinWidth: number
  shouldFocusFirstRating: boolean
  updateAssessmentData: (params: Partial<UpdateAssessmentData>) => void
}

export const TraditionalViewCriterionRatings: FC<TraditionalViewCriterionRatingsProps> = ({
  criterion,
  criterionAssessment,
  criterionSelfAssessment,
  hasValidationError,
  hidePoints,
  isPreviewMode,
  ratingOrder,
  ratingsColumnMinWidth,
  shouldFocusFirstRating,
  updateAssessmentData,
}) => {
  const firstRatingRef = useRef<HTMLElement | null>(null)

  const [hoveredRatingIndex, setHoveredRatingIndex] = useState<number>()

  const criterionRatings = useMemo(() => {
    return ratingOrder === 'ascending' ? [...criterion.ratings].reverse() : criterion.ratings
  }, [criterion.ratings, ratingOrder])

  const selectedRatingId = findCriterionMatchingRatingId(
    criterion.ratings,
    criterion.criterionUseRange,
    criterionAssessment,
  )
  const selectedSelfAssessmentRatingId = findCriterionMatchingRatingId(
    criterion.ratings,
    criterion.criterionUseRange,
    criterionSelfAssessment,
  )

  useEffect(() => {
    if (shouldFocusFirstRating && firstRatingRef.current) {
      firstRatingRef.current.focus()
    }
  }, [shouldFocusFirstRating])

  return (
    <View
      as="td"
      padding="0"
      borderWidth={`0 ${hidePoints ? '0' : 'small'} 0 small`}
      borderColor="primary"
      borderRadius="small"
    >
      <View
        as="div"
        padding="0"
        margin="0"
        height="100%"
        borderWidth={hasValidationError ? 'medium' : 'none'}
        borderColor={hasValidationError ? 'danger' : 'transparent'}
        borderRadius="medium"
      >
        <Flex as="div" direction="row" alignItems="stretch" height="100%">
          {criterionRatings.map((rating, index) => {
            const isHovered = hoveredRatingIndex === index
            const isSelected = !!rating.id && selectedRatingId === rating.id
            const isSelfAssessmentSelected =
              !!rating.id && selectedSelfAssessmentRatingId === rating.id
            const isLastRatingIndex = criterionRatings.length - 1 === index

            const onClickRating = (ratingId: string) => {
              if (selectedRatingId === ratingId) {
                updateAssessmentData({
                  points: undefined,
                  ratingId: undefined,
                })
              } else {
                updateAssessmentData({
                  points: rating.points,
                  ratingId,
                })
              }
            }

            const min = criterion.criterionUseRange
              ? rangingFrom(criterionRatings, index, ratingOrder)
              : undefined

            const ratingCellMinWidth = `${ratingsColumnMinWidth / criterionRatings.length}rem`

            return (
              <TraditionalViewCriterionRating
                // we use the array index because rating may not have an id
                key={`traditional-criterion-${criterion.id}-ratings-${index}`}
                criterionId={criterion.id}
                hidePoints={hidePoints}
                index={index}
                isHovered={isHovered}
                isLastRating={isLastRatingIndex}
                isPreviewMode={isPreviewMode}
                isSelected={isSelected}
                isSelfAssessmentSelected={isSelfAssessmentSelected}
                min={min}
                rating={rating}
                ratingCellMinWidth={ratingCellMinWidth}
                onClickRating={onClickRating}
                setHoveredRatingIndex={setHoveredRatingIndex}
                elementRef={element => {
                  if (index === 0) {
                    firstRatingRef.current = element as HTMLElement
                  }
                }}
              />
            )
          })}
        </Flex>
      </View>
      {hasValidationError && (
        <View as="div" padding="small">
          <Text size="small" color="danger">
            {I18n.t('Select a rating')}
          </Text>
        </View>
      )}
    </View>
  )
}

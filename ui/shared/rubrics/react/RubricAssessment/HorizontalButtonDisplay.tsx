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

import React, {useEffect, useRef} from 'react'
import type {RubricRating} from '../types/rubric'
import {colors} from '@instructure/canvas-theme'
import {Flex} from '@instructure/ui-flex'
import {RatingButton} from './RatingButton'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {escapeNewLineText, rangingFrom} from './utils/rubricUtils'
import {possibleString, possibleStringRange} from '../Points'
import {SelfAssessmentRatingButton} from '@canvas/rubrics/react/RubricAssessment/SelfAssessmentRatingButton'

type HorizontalButtonDisplayProps = {
  isPreviewMode: boolean
  isSelfAssessment: boolean
  ratings: RubricRating[]
  ratingOrder: string
  selectedRatingId?: string
  selectedSelfAssessmentRatingId?: string
  onSelectRating: (rating: RubricRating) => void
  criterionUseRange: boolean
  shouldFocusFirstRating?: boolean
}
export const HorizontalButtonDisplay = ({
  isPreviewMode,
  ratings,
  isSelfAssessment,
  ratingOrder,
  selectedRatingId,
  selectedSelfAssessmentRatingId,
  onSelectRating,
  criterionUseRange,
  shouldFocusFirstRating = false,
}: HorizontalButtonDisplayProps) => {
  const firstRatingRef = useRef<Element | null>(null)
  const selectedRating = ratings.find(rating => rating.id && rating.id === selectedRatingId)
  const selectedRatingIndex = selectedRating ? ratings.indexOf(selectedRating) : -1
  const selectedSelfAssessmentRating = ratings.find(
    rating => rating.id && rating.id === selectedSelfAssessmentRatingId,
  )
  const selectedSelfAssessmentRatingIndex = selectedSelfAssessmentRating
    ? ratings.indexOf(selectedSelfAssessmentRating)
    : -1
  const min = criterionUseRange ? rangingFrom(ratings, selectedRatingIndex) : undefined

  useEffect(() => {
    if (shouldFocusFirstRating && firstRatingRef.current) {
      const button = firstRatingRef.current.getElementsByTagName('button')[0]
      button?.focus()
    }
  }, [shouldFocusFirstRating])

  const getPossibleText = (points?: number) => {
    return min != null ? possibleStringRange(min, points) : possibleString(points)
  }

  const ratingDescriptionIndex =
    selectedRatingIndex >= 0 ? selectedRatingIndex : selectedSelfAssessmentRatingIndex

  const selectedRatingDescription = selectedRating ?? selectedSelfAssessmentRating

  return (
    <View as="div" data-testid="rubric-assessment-horizontal-display">
      {ratingDescriptionIndex >= 0 && (
        <View
          as="div"
          borderColor="brand"
          borderWidth={isSelfAssessment ? 'small' : 'medium'}
          borderRadius="medium"
          padding="xx-small"
          margin="0 xx-small small xx-small"
          data-testid={`rating-details-${selectedRatingDescription?.id}`}
          themeOverride={{borderColorBrand: colors.contrasts.green4570, borderWidthMedium: '0.188rem'}}
        >
          <View as="div">
            <Text size="x-small" weight="bold">
              {selectedRatingDescription?.description}
            </Text>
          </View>
          <View as="div" display="block">
            <Text
              size="x-small"
              themeOverride={{paragraphMargin: 0}}
              dangerouslySetInnerHTML={escapeNewLineText(
                selectedRatingDescription?.longDescription,
              )}
            />
          </View>
          <View as="div" textAlign="end">
            <Text size="x-small" weight="bold">
              {getPossibleText(selectedRatingDescription?.points)}
            </Text>
          </View>
        </View>
      )}
      <Flex direction={ratingOrder === 'ascending' ? 'row-reverse' : 'row'}>
        {ratings.map((rating, index) => {
          const buttonDisplay = (ratings.length - (index + 1)).toString()
          const buttonAriaLabel = `${rating.description} ${
            rating.longDescription
          } ${getPossibleText(rating.points)}`

          return (
            <Flex.Item
              key={`${rating.id}-${buttonDisplay}`}
              data-testid={`rating-button-${rating.id}-${index}`}
              aria-label={buttonAriaLabel}
              elementRef={ref => {
                if (index === 0) {
                  firstRatingRef.current = ref
                }
              }}
            >
              {isSelfAssessment ? (
                <SelfAssessmentRatingButton
                  buttonDisplay={buttonDisplay}
                  isSelected={selectedRatingIndex === index}
                  isPreviewMode={isPreviewMode}
                  onClick={() => onSelectRating(rating)}
                />
              ) : (
                <RatingButton
                  buttonDisplay={buttonDisplay}
                  isSelected={selectedRatingIndex === index}
                  isSelfAssessmentSelected={selectedSelfAssessmentRatingIndex === index}
                  isPreviewMode={isPreviewMode}
                  selectedArrowDirection="up"
                  onClick={() => onSelectRating(rating)}
                />
              )}
            </Flex.Item>
          )
        })}
      </Flex>
    </View>
  )
}

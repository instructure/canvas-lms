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
import {possibleString, possibleStringRange} from '../Points'
import {escapeNewLineText, rangingFrom} from './utils/rubricUtils'
import {SelfAssessmentRatingButton} from '@canvas/rubrics/react/RubricAssessment/SelfAssessmentRatingButton'

type VerticalButtonDisplayProps = {
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
export const VerticalButtonDisplay = ({
  isPreviewMode,
  isSelfAssessment,
  ratings,
  ratingOrder,
  selectedRatingId,
  selectedSelfAssessmentRatingId,
  onSelectRating,
  criterionUseRange,
  shouldFocusFirstRating = false,
}: VerticalButtonDisplayProps) => {
  const firstRatingRef = useRef<Element | null>(null)

  useEffect(() => {
    if (shouldFocusFirstRating && firstRatingRef.current) {
      const button = firstRatingRef.current.getElementsByTagName('button')[0]
      button?.focus()
    }
  }, [shouldFocusFirstRating])

  return (
    <Flex
      as="div"
      direction={ratingOrder === 'ascending' ? 'column-reverse' : 'column'}
      data-testid="rubric-assessment-vertical-display"
    >
      {ratings.map((rating, index) => {
        const buttonDisplay = (ratings.length - (index + 1)).toString()
        const isSelected = rating.id != null && rating.id === selectedRatingId
        const isSelfAssessmentSelected =
          rating.id != null && rating.id === selectedSelfAssessmentRatingId

        const min = criterionUseRange ? rangingFrom(ratings, index) : undefined

        const getPossibleText = (points?: number) => {
          return min != null ? possibleStringRange(min, points) : possibleString(points)
        }

        const buttonAriaLabel = `${rating.description} ${rating.longDescription} ${getPossibleText(
          rating.points,
        )}`

        return (
          <Flex.Item key={`${rating.id}-${buttonDisplay}`} padding="xx-small 0 0 0">
            <Flex>
              <Flex.Item
                align={isSelected ? 'start' : 'center'}
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
                    isPreviewMode={isPreviewMode}
                    isSelected={isSelected}
                    onClick={() => onSelectRating(rating)}
                  />
                ) : (
                  <RatingButton
                    buttonDisplay={buttonDisplay}
                    isPreviewMode={isPreviewMode}
                    isSelected={isSelected}
                    isSelfAssessmentSelected={isSelfAssessmentSelected}
                    selectedArrowDirection="right"
                    onClick={() => onSelectRating(rating)}
                  />
                )}
              </Flex.Item>
              <Flex.Item
                margin={isSelected ? '0' : '0 0 x-small x-small'}
                align={isSelected ? 'start' : 'center'}
                shouldGrow={true}
                shouldShrink={true}
              >
                {isSelected || (!selectedRatingId && isSelfAssessmentSelected) ? (
                  <View
                    as="div"
                    borderColor="brand"
                    borderWidth="medium"
                    borderRadius="medium"
                    padding="xx-small"
                    margin="0 0 x-small xx-small"
                    data-testid={`rating-details-${rating.id}`}
                    themeOverride={{borderColorBrand: colors.contrasts.green4570, borderWidthMedium: '0.188rem'}}
                  >
                    <View as="div">
                      <Text size="x-small" weight="bold">
                        {rating.description}
                      </Text>
                    </View>
                    <View as="div" display="block">
                      <Text
                        size="x-small"
                        themeOverride={{paragraphMargin: 0}}
                        dangerouslySetInnerHTML={escapeNewLineText(rating.longDescription)}
                      />
                    </View>
                    <View as="div" textAlign="end">
                      <Text size="x-small" weight="bold">
                        {getPossibleText(rating.points)}
                      </Text>
                    </View>
                  </View>
                ) : (
                  <Text size="x-small" weight="bold">
                    {rating.description}
                  </Text>
                )}
              </Flex.Item>
            </Flex>
          </Flex.Item>
        )
      })}
    </Flex>
  )
}

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

import React from 'react'
import type {RubricRating} from '../types/rubric'
import {colors} from '@instructure/canvas-theme'
import {Flex} from '@instructure/ui-flex'
import {RatingButton} from './RatingButton'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {escapeNewLineText, rangingFrom} from './utils/rubricUtils'
import {possibleString, possibleStringRange} from '../Points'

const {licorice} = colors

type HorizontalButtonDisplayProps = {
  isPreviewMode: boolean
  ratings: RubricRating[]
  ratingOrder: string
  selectedRatingIndex?: number
  onSelectRating: (index: number) => void
  criterionUseRange: boolean
}
export const HorizontalButtonDisplay = ({
  isPreviewMode,
  ratings,
  ratingOrder,
  selectedRatingIndex = -1,
  onSelectRating,
  criterionUseRange,
}: HorizontalButtonDisplayProps) => {
  const selectedRating = ratings[selectedRatingIndex]
  const min = criterionUseRange ? rangingFrom(ratings, selectedRatingIndex) : undefined

  const getPossibleText = (points?: number) => {
    return min != null ? possibleStringRange(min, points) : possibleString(points)
  }

  return (
    <View as="div" data-testid="rubric-assessment-horizontal-display">
      {selectedRatingIndex >= 0 && (
        <View
          as="div"
          borderColor="brand"
          borderWidth="medium"
          borderRadius="medium"
          padding="xx-small"
          margin="0 xx-small small xx-small"
          data-testid={`rating-details-${selectedRating?.id}`}
          themeOverride={{borderColorBrand: licorice, borderWidthMedium: '0.188rem'}}
        >
          <View as="div">
            <Text size="x-small" weight="bold">
              {selectedRating?.description}
            </Text>
          </View>
          <View as="div" display="block">
            <Text
              size="x-small"
              themeOverride={{paragraphMargin: 0}}
              dangerouslySetInnerHTML={escapeNewLineText(selectedRating?.longDescription)}
            />
          </View>
          <View as="div" textAlign="end">
            <Text size="x-small" weight="bold">
              {getPossibleText(selectedRating?.points)}
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
            >
              <RatingButton
                buttonDisplay={buttonDisplay}
                isSelected={selectedRatingIndex === index}
                isPreviewMode={isPreviewMode}
                selectedArrowDirection="up"
                onClick={() => onSelectRating(index)}
              />
            </Flex.Item>
          )
        })}
      </Flex>
    </View>
  )
}

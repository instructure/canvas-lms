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
import {Flex} from '@instructure/ui-flex'
import {RatingButton} from './RatingButton'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

type HorizontalButtonDisplayProps = {
  ratings: RubricRating[]
  ratingOrder: string
  selectedRatingIndex?: number
  onSelectRating: (index: number) => void
}
export const HorizontalButtonDisplay = ({
  ratings,
  ratingOrder,
  selectedRatingIndex = -1,
  onSelectRating,
}: HorizontalButtonDisplayProps) => {
  return (
    <View as="div" data-testid="rubric-assessment-horizontal-display">
      {selectedRatingIndex >= 0 && (
        <View
          as="div"
          borderColor="success"
          borderWidth="small"
          borderRadius="medium"
          padding="xx-small"
          margin="0 xx-small small xx-small"
          data-testid={`rating-details-${ratings[selectedRatingIndex]?.id}`}
        >
          <View as="div">
            <Text size="x-small" weight="bold">
              {ratings[selectedRatingIndex]?.description}
            </Text>
          </View>
          <View as="div" display="block">
            <Text size="x-small">{ratings[selectedRatingIndex]?.longDescription}</Text>
          </View>
        </View>
      )}
      <Flex direction={ratingOrder === 'ascending' ? 'row-reverse' : 'row'}>
        {ratings.map((rating, index) => {
          const buttonDisplay = (ratings.length - (index + 1)).toString()

          return (
            <Flex.Item
              key={`${rating.id}-${buttonDisplay}`}
              data-testid={`rating-button-${rating.id}-${index}`}
            >
              <RatingButton
                buttonDisplay={buttonDisplay}
                isSelected={selectedRatingIndex === index}
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

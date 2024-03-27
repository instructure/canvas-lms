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

type VerticalButtonDisplayProps = {
  ratings: RubricRating[]
  ratingOrder: string
  selectedRatingIndex?: number
  onSelectRating: (index: number) => void
}
export const VerticalButtonDisplay = ({
  ratings,
  ratingOrder,
  selectedRatingIndex,
  onSelectRating,
}: VerticalButtonDisplayProps) => {
  return (
    <Flex
      as="div"
      direction={ratingOrder === 'ascending' ? 'column-reverse' : 'column'}
      data-testid="rubric-assessment-vertical-display"
    >
      {ratings.map((rating, index) => {
        const buttonDisplay = (ratings.length - (index + 1)).toString()
        const isSelected = selectedRatingIndex === index

        return (
          <Flex.Item key={`${rating.id}-${buttonDisplay}`} padding="xx-small 0 0 0">
            <Flex>
              <Flex.Item
                align={isSelected ? 'start' : 'center'}
                data-testid={`rating-button-${rating.id}-${index}`}
              >
                <RatingButton
                  buttonDisplay={buttonDisplay}
                  isSelected={isSelected}
                  selectedArrowDirection="right"
                  onClick={() => onSelectRating(index)}
                />
              </Flex.Item>
              <Flex.Item
                margin={isSelected ? '0' : '0 0 x-small x-small'}
                align={isSelected ? 'start' : 'center'}
                shouldGrow={true}
                shouldShrink={true}
              >
                {isSelected ? (
                  <View
                    as="div"
                    borderColor="success"
                    borderWidth="small"
                    borderRadius="medium"
                    padding="xx-small"
                    margin="0 0 x-small xx-small"
                    data-testid={`rating-details-${rating.id}`}
                  >
                    <View as="div">
                      <Text size="x-small" weight="bold">
                        {rating.description}
                      </Text>
                    </View>
                    <View as="div" display="block">
                      <Text size="x-small">{rating.longDescription}</Text>
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

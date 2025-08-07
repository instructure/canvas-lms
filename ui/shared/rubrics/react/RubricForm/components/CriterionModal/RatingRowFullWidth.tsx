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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {IconDragHandleLine, IconTrashLine} from '@instructure/ui-icons'
import {RatingPointsInput} from './RatingPointsInput'
import {Draggable} from 'react-beautiful-dnd'
import {RatingRowProps} from '../../types/RubricForm'
import {RatingDescription} from './RatingDescription'
import {RatingLongDescription} from './RatingLongDescription'

const I18n = createI18nScope('rubrics-criterion-modal')

export const RatingRowFullWidth = ({
  criterionUseRange,
  errorMessage,
  hidePoints,
  index,
  rating,
  scale,
  rangeStart,
  ratingInputRefs,
  pointsInputText,
  onPointsBlur,
  setRatingForm,
  setPointsInputText,
  showRemoveButton,
  onRemove,
}: RatingRowProps) => {
  return (
    <Flex>
      <Flex.Item align="start">
        <Flex>
          <Flex.Item align="start">
            <View as="div" width="4.125rem" margin="x-small 0 0 0">
              <View margin="0 0 0 medium">
                <Text aria-label={I18n.t('Rating Display')} data-testid="rating-scale">
                  {scale.toString()}
                </Text>
              </View>
            </View>
          </Flex.Item>
          {!hidePoints && (
            <Flex.Item align="start">
              <View as="div" width={criterionUseRange ? '11.375rem' : '6.938rem'}>
                <Flex alignItems="end" height="2.375rem">
                  {criterionUseRange && (
                    <Flex.Item width="4.5rem" textAlign="end" margin="0 0 x-small 0">
                      <View as="span" margin="0 small 0 0" data-testid="range-start">
                        {rangeStart ? I18n.t('%{rangeStart} to ', {rangeStart}) : `--`}
                      </View>
                    </Flex.Item>
                  )}
                  <Flex.Item>
                    <RatingPointsInput
                      index={index}
                      isRange={criterionUseRange}
                      pointsInputText={pointsInputText}
                      rating={rating}
                      ratingInputRefs={ratingInputRefs}
                      onPointsBlur={onPointsBlur}
                      setNewRating={(newNumber, textValue) => {
                        setRatingForm('points', newNumber)
                        setPointsInputText(textValue)
                      }}
                      shouldRenderLabel={false}
                    />
                  </Flex.Item>
                </Flex>
              </View>
            </Flex.Item>
          )}
        </Flex>
      </Flex.Item>

      <div style={{width: '100%'}}>
        <Draggable draggableId={rating.id || Date.now().toString()} index={index}>
          {provided => {
            return (
              <div ref={provided.innerRef} {...provided.draggableProps}>
                <Flex>
                  <Flex.Item align="start" draggable data-testid="rating-drag-handle">
                    <View
                      as="div"
                      width="3rem"
                      textAlign="center"
                      cursor="pointer"
                      margin="xx-small 0 0 0"
                    >
                      <div className="drag-handle" {...provided.dragHandleProps}>
                        <IconDragHandleLine />
                      </div>
                    </View>
                  </Flex.Item>
                  <Flex.Item align="start">
                    <View as="div" width="8.875rem">
                      <RatingDescription
                        description={rating.description}
                        errorMessage={errorMessage}
                        setRatingForm={setRatingForm}
                        shouldRenderLabel={false}
                      />
                    </View>
                  </Flex.Item>
                  <Flex.Item shouldGrow={true} shouldShrink={true} align="start">
                    <View as="div" margin="0 small" themeOverride={{marginSmall: '1rem'}}>
                      <RatingLongDescription
                        limitHeight={true}
                        longDescription={rating.longDescription}
                        setRatingForm={setRatingForm}
                        shouldRenderLabel={false}
                      />
                    </View>
                  </Flex.Item>
                  <Flex.Item align="start">
                    <View as="div" width="2.375rem">
                      {showRemoveButton && (
                        <IconButton
                          screenReaderLabel={I18n.t('Remove %{ratingName} Rating', {
                            ratingName: rating.description,
                          })}
                          onClick={onRemove}
                          data-testid="remove-rating"
                        >
                          <IconTrashLine />
                        </IconButton>
                      )}
                    </View>
                  </Flex.Item>
                </Flex>
              </div>
            )
          }}
        </Draggable>
      </div>
    </Flex>
  )
}

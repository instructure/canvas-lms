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

import {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {FormMessage} from '@instructure/ui-form-field'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Draggable} from 'react-beautiful-dnd'
import {IconDragHandleLine, IconTrashLine} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {IconButton} from '@instructure/ui-buttons'
import {RubricRating} from '../../../types/rubric'

const I18n = createI18nScope('rubrics-criterion-modal')

type RatingRowProps = {
  checkValidation: boolean
  criterionUseRange: boolean
  hidePoints: boolean
  index: number
  rangeStart?: number
  rating: RubricRating
  scale: number
  showRemoveButton: boolean
  unassessed: boolean
  onChange: (rating: RubricRating) => void
  onRemove: () => void
  onPointsBlur: () => void
}
export const RatingRow = ({
  checkValidation,
  criterionUseRange,
  rangeStart,
  hidePoints,
  index,
  rating,
  scale,
  showRemoveButton,
  unassessed,
  onChange,
  onRemove,
  onPointsBlur,
}: RatingRowProps) => {
  const [pointsInputText, setPointsInputText] = useState<string | number>(0)

  useEffect(() => {
    setPointsInputText(rating.points)
  }, [rating.points])

  function setRatingForm<K extends keyof RubricRating>(key: K, value: RubricRating[K]) {
    onChange({...rating, [key]: value})
  }

  const setNumber = (value: number) => {
    if (Number.isNaN(value)) return 0

    return value < 0 ? 0 : value
  }

  const errorMessage: FormMessage[] =
    !rating.description.trim().length && checkValidation
      ? [{text: 'Rating Name Required', type: 'error'}]
      : []

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
                      <View as="span" margin="0 small 0 0">
                        {rangeStart ? I18n.t('%{rangeStart} to ', {rangeStart}) : `--`}
                      </View>
                    </Flex.Item>
                  )}
                  {unassessed ? (
                    <Flex.Item>
                      <NumberInput
                        allowStringValue={true}
                        renderLabel={
                          <ScreenReaderContent>{I18n.t('Rating Points')}</ScreenReaderContent>
                        }
                        value={pointsInputText}
                        onIncrement={() => {
                          const newNumber = setNumber(Math.floor(rating.points) + 1)

                          setPointsInputText(newNumber)
                          setRatingForm('points', newNumber)
                        }}
                        onDecrement={() => {
                          const newNumber = setNumber(Math.floor(rating.points) - 1)

                          setPointsInputText(newNumber)
                          setRatingForm('points', newNumber)
                        }}
                        onChange={(_e, value) => {
                          if (!/^\d*[.,]?\d{0,2}$/.test(value)) return

                          const newNumber = setNumber(Number(value.replace(',', '.')))
                          setRatingForm('points', newNumber)
                          setPointsInputText(value.toString())
                        }}
                        data-testid="rating-points"
                        width="6.25rem"
                        onBlur={() => {
                          onPointsBlur()
                        }}
                      />
                    </Flex.Item>
                  ) : (
                    <Flex.Item margin="0 0 x-small 0">
                      <View as="span" data-testid="rating-points-assessed">
                        {rating.points}
                      </View>
                    </Flex.Item>
                  )}
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
                  <Flex.Item align="start" draggable={unassessed} data-testid="rating-drag-handle">
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
                      <TextInput
                        renderLabel={
                          <ScreenReaderContent>{I18n.t('Rating Name')}</ScreenReaderContent>
                        }
                        display="inline-block"
                        value={rating.description ?? ''}
                        onChange={(_e, value) => setRatingForm('description', value)}
                        data-testid="rating-name"
                        messages={errorMessage}
                      />
                    </View>
                  </Flex.Item>
                  <Flex.Item shouldGrow={true} shouldShrink={true} align="start">
                    <View as="div" margin="0 small" themeOverride={{marginSmall: '1rem'}}>
                      <TextArea
                        label={
                          <ScreenReaderContent>{I18n.t('Rating Description')}</ScreenReaderContent>
                        }
                        value={rating.longDescription ?? ''}
                        width="100%"
                        height="2.25rem"
                        maxHeight="6.75rem"
                        onChange={e => setRatingForm('longDescription', e.target.value)}
                        data-testid="rating-description"
                      />
                    </View>
                  </Flex.Item>
                  {unassessed && (
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
                  )}
                </Flex>
              </div>
            )
          }}
        </Draggable>
      </div>
    </Flex>
  )
}

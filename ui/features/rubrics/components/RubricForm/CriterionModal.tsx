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
import type {RubricCriterion, RubricRating} from '@canvas/rubrics/react/types/rubric'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconDragHandleLine, IconPlusLine, IconTrashLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {NumberInput} from '@instructure/ui-number-input'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {FormMessage} from '@instructure/ui-form-field'
import {TextArea} from '@instructure/ui-text-area'
import {DragDropContext as DragAndDrop, Droppable, Draggable} from 'react-beautiful-dnd'
import type {DropResult} from 'react-beautiful-dnd'

const I18n = useI18nScope('rubrics-criterion-modal')

export const DEFAULT_RUBRIC_RATINGS: RubricRating[] = [
  {
    id: '1',
    points: 4,
    description: I18n.t('Exceeds'),
    longDescription: '',
  },
  {
    id: '2',
    points: 3,
    description: I18n.t('Mastery'),
    longDescription: '',
  },
  {
    id: '3',
    points: 2,
    description: I18n.t('Near'),
    longDescription: '',
  },
  {
    id: '4',
    points: 1,
    description: I18n.t('Below'),
    longDescription: '',
  },
  {
    id: '5',
    points: 0,
    description: I18n.t('No Evidence'),
    longDescription: '',
  },
]

type ReorderProps = {
  list: RubricRating[]
  startIndex: number
  endIndex: number
}

export const reorder = ({list, startIndex, endIndex}: ReorderProps) => {
  const result = Array.from(list)
  const resultCopy = JSON.parse(JSON.stringify(list))

  const [removed] = result.splice(startIndex, 1)
  result.splice(endIndex, 0, removed)

  result.forEach((item, index) => {
    item.points = resultCopy[index].points
  })

  return result
}

export type CriterionModalProps = {
  criterion?: RubricCriterion
  isOpen: boolean
  unassessed: boolean
  onSave: (criterion: RubricCriterion) => void
  onDismiss: () => void
}
export const CriterionModal = ({
  criterion,
  isOpen,
  unassessed,
  onDismiss,
  onSave,
}: CriterionModalProps) => {
  const [ratings, setRatings] = useState<RubricRating[]>([])
  const [criterionDescription, setCriterionDescription] = useState('')
  const [criterionLongDescription, setCriterionLongDescription] = useState('')
  const [criterionUseRange, setCriterionUseRange] = useState(false)
  const [savingCriterion, setSavingCriterion] = useState(false)
  const [dragging, setDragging] = useState(false)
  const [checkValidation, setCheckValidation] = useState(false)

  const addRating = (index: number) => {
    const isFirstIndex = index === 0
    const isLastIndex = index === ratings.length
    const points = isFirstIndex
      ? ratings[0].points + 1
      : isLastIndex
      ? Math.max(ratings[index - 1].points - 1, 0)
      : Math.round((ratings[index].points + ratings[index - 1].points) / 2)

    const newRating = {
      id: Date.now().toString(),
      points,
      description: '',
      longDescription: '',
    }
    const newRatings = [...ratings]
    newRatings.splice(index, 0, newRating)
    setRatings(newRatings)
  }

  const removeRating = (index: number) => {
    const newRatings = [...ratings]
    newRatings.splice(index, 1)
    setRatings(newRatings)
  }

  const {
    description: existingDescription,
    longDescription: existingLongDescription,
    ratings: existingRatings,
    criterionUseRange: existingCriterionUseRange,
  } = criterion ?? {}

  const modalTitle = existingDescription ? I18n.t('Edit Criterion') : I18n.t('Create New Criterion')

  useEffect(() => {
    if (isOpen) {
      setCriterionDescription(existingDescription ?? '')
      setCriterionLongDescription(existingLongDescription ?? '')
      setCriterionUseRange(existingCriterionUseRange ?? false)
      const defaultRatings = JSON.parse(JSON.stringify(DEFAULT_RUBRIC_RATINGS))
      setRatings(existingRatings ?? defaultRatings)
      setSavingCriterion(false)
      setCheckValidation(false)
    }
  }, [
    existingCriterionUseRange,
    existingDescription,
    existingLongDescription,
    existingRatings,
    isOpen,
  ])

  const updateRating = (index: number, rating: RubricRating) => {
    const newRatings = [...ratings]
    newRatings[index] = rating

    setRatings(newRatings)
  }

  const reorderRatings = () => {
    const newRatings = [...ratings]

    const ratingPoints = newRatings.map(r => ({points: r.points, id: r.id}))
    const ratingNameAndDescription = newRatings.map(r => ({
      description: r.description,
      longDescription: r.longDescription,
    }))

    const ratingPointsReordered = ratingPoints.sort((a, b) => b.points - a.points)

    const finalRatings: RubricRating[] = ratingPointsReordered.map((r, index) => {
      return {
        id: r.id,
        points: r.points,
        description: ratingNameAndDescription[index].description,
        longDescription: ratingNameAndDescription[index].longDescription,
      }
    })

    setRatings(finalRatings)
  }

  const handleDragStart = () => {
    setDragging(true)
  }

  const handleDragEnd = (result: DropResult) => {
    const {source, destination} = result
    if (!destination) {
      return
    }

    const reorderedItems = reorder({
      list: ratings,
      startIndex: source.index,
      endIndex: destination.index,
    })
    setRatings(reorderedItems)
    setDragging(false)
  }

  const saveChanges = async () => {
    setCheckValidation(true)

    if (savingCriterion || !isValid()) {
      return
    }

    setSavingCriterion(true)
    const newCriterion: RubricCriterion = {
      id: criterion?.id ?? Date.now().toString(),
      description: criterionDescription,
      longDescription: criterionLongDescription,
      ratings,
      points: Math.max(...ratings.map(r => r.points), 0),
      criterionUseRange: criterionUseRange ?? false,
      ignoreForScoring: criterion?.ignoreForScoring ?? false,
      masteryPoints: criterion?.masteryPoints ?? 0,
      learningOutcomeId: criterion?.learningOutcomeId ?? undefined,
    }

    onSave(newCriterion)
  }

  const isValid = () => {
    return (
      criterionDescription.trim().length > 0 && ratings.every(r => r.description.trim().length > 0)
    )
  }

  const criterionDescriptionErrorMessage: FormMessage[] =
    !criterionDescription.trim().length && checkValidation
      ? [{text: 'Criteria Name Required', type: 'error'}]
      : []

  const maxRatingPoints = ratings.length ? Math.max(...ratings.map(r => r.points), 0) : '--'

  return (
    <Modal
      open={isOpen}
      onDismiss={onDismiss}
      width="66.5rem"
      height="45.125rem"
      label={I18n.t('Rubric Criterion Modal')}
      shouldCloseOnDocumentClick={false}
      data-testid="rubric-criterion-modal"
    >
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
        <Heading>{modalTitle}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="0">
          <Flex alignItems="start">
            <View as="span" margin="0 small 0 0" themeOverride={{marginSmall: '1rem'}}>
              <TextInput
                renderLabel={I18n.t('Criterion Name')}
                placeholder={I18n.t('Enter the name')}
                display="inline-block"
                width="20.75rem"
                value={criterionDescription ?? ''}
                messages={criterionDescriptionErrorMessage}
                onChange={(e, value) => setCriterionDescription(value)}
                data-testid="rubric-criterion-name-input"
              />
            </View>
            <View as="span">
              <TextInput
                renderLabel={I18n.t('Criterion Description')}
                placeholder={I18n.t('Enter the description')}
                display="inline-block"
                width="41.75rem"
                value={criterionLongDescription ?? ''}
                onChange={(e, value) => setCriterionLongDescription(value)}
                data-testid="rubric-criterion-description-input"
              />
            </View>
          </Flex>
        </View>

        <View as="div" margin="medium 0 0 0" themeOverride={{marginMedium: '1.25rem'}}>
          <Flex>
            <Flex.Item shouldGrow={true}>
              {unassessed && (
                <Checkbox
                  label="Enable Range"
                  checked={criterionUseRange}
                  onChange={e => setCriterionUseRange(e.target.checked)}
                  data-testid="enable-range-checkbox"
                />
              )}
            </Flex.Item>
            <Flex.Item>
              <Heading
                level="h2"
                as="h2"
                themeOverride={{h2FontWeight: 700, h2FontSize: '22px', lineHeight: '1.75rem'}}
              >
                {maxRatingPoints} {I18n.t('Points Possible')}
              </Heading>
            </Flex.Item>
          </Flex>
        </View>

        <View as="div" margin="medium 0 0 0" themeOverride={{marginMedium: '1.25rem'}}>
          <Flex>
            <Flex.Item>
              <View as="div" width="4.125rem">
                {I18n.t('Display')}
              </View>
            </Flex.Item>
            <Flex.Item>
              <View as="div" width={criterionUseRange ? '12.375rem' : '8.875rem'}>
                {criterionUseRange ? I18n.t('Point Range') : I18n.t('Points')}
              </View>
            </Flex.Item>
            <Flex.Item>
              <View as="div" width="8.875rem">
                {I18n.t('Rating Name')}
              </View>
            </Flex.Item>
            <Flex.Item>
              <View as="div" margin="0 0 0 small" themeOverride={{marginSmall: '1rem'}}>
                {I18n.t('Rating Description')}
              </View>
            </Flex.Item>
          </Flex>
        </View>

        <View as="div" position="relative">
          <DragVerticalLineBreak criterionUseRange={criterionUseRange} />
          <DragAndDrop onDragStart={handleDragStart} onDragEnd={handleDragEnd}>
            <Droppable droppableId="droppable-id">
              {provided => {
                return (
                  <div ref={provided.innerRef} {...provided.droppableProps}>
                    {ratings.map((rating, index) => {
                      const scale = ratings.length - (index + 1)
                      const nextRating = ratings[index + 1]
                      const rangeStart = nextRating ? nextRating.points + 0.1 : undefined

                      return (
                        // eslint-disable-next-line react/no-array-index-key
                        <View as="div" key={`rating-row-${rating.id}-${index}`}>
                          <AddRatingRow
                            onClick={() => addRating(index)}
                            unassessed={unassessed}
                            isDragging={dragging}
                          />
                          <RatingRow
                            index={index}
                            checkValidation={checkValidation}
                            rating={rating}
                            scale={scale}
                            showRemoveButton={ratings.length > 1}
                            criterionUseRange={criterionUseRange}
                            rangeStart={rangeStart}
                            unassessed={unassessed}
                            onRemove={() => removeRating(index)}
                            onChange={updatedRating => updateRating(index, updatedRating)}
                            onPointsBlur={reorderRatings}
                          />
                        </View>
                      )
                    })}
                    <AddRatingRow
                      onClick={() => addRating(ratings.length)}
                      unassessed={unassessed}
                      isDragging={dragging}
                    />
                    {provided.placeholder}
                  </div>
                )
              }}
            </Droppable>
          </DragAndDrop>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Flex width="100%">
          <Flex.Item shouldShrink={true} shouldGrow={true}>
            {/* <Checkbox label={I18n.t('Save this rating scale as default')} value="medium" /> */}
          </Flex.Item>
          <Flex.Item>
            <Button
              margin="0 x-small 0 0"
              onClick={onDismiss}
              data-testid="rubric-criterion-cancel"
            >
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button
              color="primary"
              type="submit"
              disabled={savingCriterion}
              onClick={() => saveChanges()}
              data-testid="rubric-criterion-save"
            >
              {I18n.t('Save Criterion')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

type RatingRowProps = {
  checkValidation: boolean
  criterionUseRange: boolean
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
const RatingRow = ({
  checkValidation,
  criterionUseRange,
  rangeStart,
  index,
  rating,
  scale,
  showRemoveButton,
  unassessed,
  onChange,
  onRemove,
  onPointsBlur,
}: RatingRowProps) => {
  function setRatingForm<K extends keyof RubricRating>(key: K, value: RubricRating[K]) {
    onChange({...rating, [key]: value})
  }

  const setNumber = (value: number) => {
    if (Number.isNaN(value)) return 0

    return value < 0 ? 0 : value > 100 ? 100 : value
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
          <Flex.Item align="start">
            <View as="div" width={criterionUseRange ? '9.375rem' : '5.938rem'}>
              <Flex alignItems="end" height="2.375rem">
                {criterionUseRange && (
                  <Flex.Item width="3.438rem" textAlign="end" margin="0 0 x-small 0">
                    <View as="span" margin="0 small 0 0">
                      {rangeStart ? `${rangeStart} to ` : `--`}
                    </View>
                  </Flex.Item>
                )}
                {unassessed ? (
                  <Flex.Item>
                    <NumberInput
                      renderLabel={
                        <ScreenReaderContent>{I18n.t('Rating Points')}</ScreenReaderContent>
                      }
                      value={rating.points}
                      onIncrement={() => setRatingForm('points', setNumber(rating.points + 1))}
                      onDecrement={() => setRatingForm('points', setNumber(rating.points - 1))}
                      onChange={(e, value) =>
                        setRatingForm('points', setNumber(Number(value ?? 0)))
                      }
                      data-testid="rating-points"
                      width="4.938rem"
                      onBlur={onPointsBlur}
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
                        onChange={(e, value) => setRatingForm('description', value)}
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

type AddRatingRowProps = {
  unassessed: boolean
  onClick: () => void
  isDragging: boolean
}
const AddRatingRow = ({unassessed, onClick, isDragging}: AddRatingRowProps) => {
  const [isHovered, setIsHovered] = useState(false)

  return (
    <View
      as="div"
      data-testid="add-rating-row"
      textAlign="center"
      margin="0"
      height="1.688rem"
      width="100%"
      tabIndex={0}
      position="relative"
      onKeyDown={e => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          onClick()
        }
      }}
      label="Add New Rating"
      onFocus={() => setIsHovered(true)}
      onMouseOver={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {isHovered && unassessed && !isDragging && (
        <View as="div" cursor="pointer" onClick={onClick} onBlur={() => setIsHovered(false)}>
          <IconButton
            screenReaderLabel={I18n.t('Add new rating')}
            shape="circle"
            size="small"
            color="primary"
            themeOverride={{smallHeight: '1.5rem'}}
          >
            <IconPlusLine />
          </IconButton>
          <div
            style={{
              border: 'none',
              borderTop: '0.125rem solid var(--ic-brand-primary)',
              width: '100%',
              height: '0.063rem',
              margin: '-0.75rem 0 0 0',
            }}
          />
        </View>
      )}
    </View>
  )
}

type DragVerticalLineBreakProps = {
  criterionUseRange: boolean
}
const DragVerticalLineBreak = ({criterionUseRange}: DragVerticalLineBreakProps) => {
  return (
    <div
      style={{
        position: 'absolute',
        width: '1px',
        height: 'auto',
        backgroundColor: '#C7CDD1',
        left: criterionUseRange ? '13.75rem' : '10.313rem',
        top: '1.688rem',
        bottom: '1.688rem',
      }}
    />
  )
}

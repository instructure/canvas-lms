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
import {View} from '@instructure/ui-view'
import type {FormMessage} from '@instructure/ui-form-field'
import {TextArea} from '@instructure/ui-text-area'

const I18n = useI18nScope('rubrics-criterion-modal')

export const DEFAULT_RUBRIC_RATINGS: RubricRating[] = [
  {
    id: '',
    points: 4,
    description: I18n.t('Exceeds'),
    longDescription: '',
  },
  {
    id: '',
    points: 3,
    description: I18n.t('Mastery'),
    longDescription: '',
  },
  {
    id: '',
    points: 2,
    description: I18n.t('Near'),
    longDescription: '',
  },
  {
    id: '',
    points: 1,
    description: I18n.t('Below'),
    longDescription: '',
  },
  {
    id: '',
    points: 0,
    description: I18n.t('No Evidence'),
    longDescription: '',
  },
]

export type CriterionModalProps = {
  criterion?: RubricCriterion
  isOpen: boolean
  onSave: (criterion: RubricCriterion) => void
  onDismiss: () => void
}
export const CriterionModal = ({criterion, isOpen, onDismiss, onSave}: CriterionModalProps) => {
  const [ratings, setRatings] = useState<RubricRating[]>([])
  const [criterionDescription, setCriterionDescription] = useState('')
  const [criterionLongDescription, setCriterionLongDescription] = useState('')
  const [draggedRatingIndex, setDraggedRatingIndex] = useState<number>()
  const [draggedOverIndex, setDraggedOverIndex] = useState<number>()

  const addRating = (index: number) => {
    const newRating = {
      id: '-1',
      points: 0,
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
  } = criterion ?? {}

  useEffect(() => {
    if (isOpen) {
      setCriterionDescription(existingDescription ?? '')
      setCriterionLongDescription(existingLongDescription ?? '')
      setRatings(existingRatings ?? DEFAULT_RUBRIC_RATINGS)
    }
  }, [existingDescription, existingLongDescription, existingRatings, isOpen])

  const updateRating = (index: number, rating: RubricRating) => {
    const newRatings = [...ratings]
    newRatings[index] = rating
    setRatings(newRatings)
  }

  const saveChanges = () => {
    const newCriterion: RubricCriterion = {
      id: criterion?.id ?? '',
      description: criterionDescription,
      longDescription: criterionLongDescription,
      ratings,
      points: Math.max(...ratings.map(r => r.points), 0),
      criterionUseRange: criterion?.criterionUseRange ?? false,
      ignoreForScoring: criterion?.ignoreForScoring ?? false,
      masteryPoints: criterion?.masteryPoints ?? 0,
      learningOutcomeId: criterion?.learningOutcomeId ?? undefined,
    }

    onSave(newCriterion)
  }

  const handleDragOver = (event: React.DragEvent, index: number) => {
    event.preventDefault()
    setDraggedOverIndex(index)
  }

  const handleDragLeave = (event: React.DragEvent) => {
    const target = event.target as Node
    const relatedTarget = event.relatedTarget as Node | null

    // Check if the drag actually left area and its descendants
    if (target !== relatedTarget && !target.contains(relatedTarget)) {
      setDraggedOverIndex(undefined)
    }
  }

  const handleDragDrop = (event: React.DragEvent, index: number) => {
    event.preventDefault()
    const fromIndex = Number(draggedRatingIndex)
    const toIndex = index

    if (fromIndex === toIndex) return

    const ratingFieldsToMove = ratings.map(r => {
      return {
        description: r.description,
        longDescription: r.longDescription,
      }
    })

    const movedRating = ratingFieldsToMove.splice(fromIndex, 1)[0]
    ratingFieldsToMove.splice(toIndex, 0, movedRating)

    const newRatings = ratings.map((r, i) => {
      return {
        ...r,
        description: ratingFieldsToMove[i].description,
        longDescription: ratingFieldsToMove[i].longDescription,
      }
    })

    setRatings(newRatings)
  }

  const handleDragEnd = () => {
    setDraggedRatingIndex(undefined)
    setDraggedOverIndex(undefined)
  }

  const isValid = () => {
    return (
      criterionDescription.trim().length > 0 && ratings.every(r => r.description.trim().length > 0)
    )
  }

  const criterionDescriptionErrorMessage: FormMessage[] = criterionDescription.trim().length
    ? []
    : [{text: 'Criteria Name Required', type: 'error'}]

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
        <Heading>{I18n.t('Create New Criterion')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="0">
          <View as="span" margin="0 small 0 0" themeOverride={{marginSmall: '1rem'}}>
            <TextInput
              renderLabel={I18n.t('Criterion Name')}
              placeholder={I18n.t('Enter the name')}
              display="inline-block"
              width="20.75rem"
              value={criterionDescription}
              messages={criterionDescriptionErrorMessage}
              onChange={(e, value) => setCriterionDescription(value)}
              data-testid="rubric-criterion-description"
            />
          </View>
          <View as="span">
            <TextInput
              renderLabel={I18n.t('Criterion Description')}
              placeholder={I18n.t('Enter the description')}
              display="inline-block"
              width="41.75rem"
              value={criterionLongDescription}
              onChange={(e, value) => setCriterionLongDescription(value)}
            />
          </View>
        </View>

        <View as="div" margin="medium 0 0 0">
          <Flex>
            <Flex.Item>
              <View as="div" width="3.938rem">
                {I18n.t('Scale')}
              </View>
            </Flex.Item>
            <Flex.Item>
              <View as="div" width="7.938rem">
                {I18n.t('Points')}
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

        <View as="div">
          {ratings.map((rating, index) => {
            const scale = ratings.length - (index + 1)

            return (
              // eslint-disable-next-line react/no-array-index-key
              <View as="div" key={`rating-row-${rating.id}-${index}`}>
                <AddRatingRow onClick={() => addRating(index)} />
                <RatingRow
                  index={index}
                  isDragging={draggedRatingIndex === index}
                  isDraggedOver={draggedOverIndex === index && draggedRatingIndex !== index}
                  rating={rating}
                  scale={scale}
                  onRemove={() => removeRating(index)}
                  onChange={updatedRating => updateRating(index, updatedRating)}
                  onDragDrop={handleDragDrop}
                  onDragOver={handleDragOver}
                  onDragStart={() => setDraggedRatingIndex(index)}
                  onDragEnd={handleDragEnd}
                  onDragLeave={handleDragLeave}
                />
              </View>
            )
          })}

          <AddRatingRow onClick={() => addRating(ratings.length)} />
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Flex width="100%">
          <Flex.Item shouldShrink={true} shouldGrow={true}>
            <Checkbox label={I18n.t('Save this rating scale as default')} value="medium" />
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
              disabled={!isValid()}
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
  index: number
  isDragging: boolean
  isDraggedOver: boolean
  rating: RubricRating
  scale: number
  onChange: (rating: RubricRating) => void
  onRemove: () => void
  onDragStart: (e: React.DragEvent, index: number) => void
  onDragOver: (e: React.DragEvent, index: number) => void
  onDragDrop: (e: React.DragEvent, index: number) => void
  onDragLeave: (e: React.DragEvent) => void
  onDragEnd: () => void
}
const RatingRow = ({
  index,
  isDragging,
  isDraggedOver,
  rating,
  scale,
  onChange,
  onRemove,
  onDragOver,
  onDragStart,
  onDragDrop,
  onDragEnd,
  onDragLeave,
}: RatingRowProps) => {
  const setRatingForm = <K extends keyof RubricRating>(key: K, value: RubricRating[K]) => {
    onChange({...rating, [key]: value})
  }

  const setNumber = (value: number) => {
    if (Number.isNaN(value)) return 0

    return value < 0 ? 0 : value > 100 ? 100 : value
  }

  const errorMessage: FormMessage[] = rating.description.trim().length
    ? []
    : [{text: 'Rating Name Required', type: 'error'}]

  return (
    <Flex
      onDragStart={(e: React.DragEvent) => onDragStart(e, index)}
      onDragOver={(e: React.DragEvent) => onDragOver(e, index)}
      onDrop={(e: React.DragEvent) => onDragDrop(e, index)}
      onDragEnd={onDragEnd}
      onDragLeave={onDragLeave}
    >
      <Flex.Item align="start">
        <View as="div" width="3.938rem">
          <TextInput
            renderLabel={<ScreenReaderContent>{I18n.t('Rating Scale')}</ScreenReaderContent>}
            display="inline-block"
            width="3.125rem"
            disabled={true}
            textAlign="center"
            value={scale.toString()}
            onChange={() => {}}
            data-testid="rating-scale"
          />
        </View>
      </Flex.Item>
      <Flex.Item align="start">
        <View as="div" width="4.938rem">
          <NumberInput
            renderLabel={<ScreenReaderContent>{I18n.t('Rating Points')}</ScreenReaderContent>}
            value={rating.points}
            onIncrement={() => setRatingForm('points', setNumber(rating.points + 1))}
            onDecrement={() => setRatingForm('points', setNumber(rating.points - 1))}
            onChange={(e, value) => setRatingForm('points', setNumber(Number(value ?? 0)))}
            data-testid="rating-points"
          />
        </View>
      </Flex.Item>
      <Flex.Item align="start" draggable={true} data-testid="rating-drag-handle">
        <View as="div" width="3rem" textAlign="center" cursor="pointer" margin="xx-small 0 0 0">
          <IconDragHandleLine />
        </View>
      </Flex.Item>
      <Flex.Item align="start">
        <View
          as="div"
          width="8.875rem"
          borderWidth={isDragging || isDraggedOver ? 'medium' : 'none'}
          borderColor={isDragging ? 'brand' : 'success'}
        >
          <TextInput
            renderLabel={<ScreenReaderContent>{I18n.t('Rating Name')}</ScreenReaderContent>}
            display="inline-block"
            value={rating.description}
            onChange={(e, value) => setRatingForm('description', value)}
            data-testid="rating-name"
            messages={errorMessage}
          />
        </View>
      </Flex.Item>
      <Flex.Item shouldGrow={true} shouldShrink={true} align="start">
        <View
          as="div"
          margin="0 small"
          themeOverride={{marginSmall: '1rem'}}
          borderWidth={isDragging || isDraggedOver ? 'medium' : 'none'}
          borderColor={isDragging ? 'brand' : 'success'}
        >
          <TextArea
            label={<ScreenReaderContent>{I18n.t('Rating Description')}</ScreenReaderContent>}
            value={rating.longDescription}
            width="100%"
            height="2.25rem"
            maxHeight="6.75rem"
            onChange={e => setRatingForm('longDescription', e.target.value)}
            data-testid="rating-description"
          />
        </View>
      </Flex.Item>
      <Flex.Item align="start">
        <View as="div">
          <IconButton
            screenReaderLabel={I18n.t('Remove Rating')}
            onClick={onRemove}
            data-testid="remove-rating"
          >
            <IconTrashLine />
          </IconButton>
        </View>
      </Flex.Item>
    </Flex>
  )
}

type AddRatingRowProps = {
  onClick: () => void
}
const AddRatingRow = ({onClick}: AddRatingRowProps) => {
  const [isHovered, setIsHovered] = useState(false)

  return (
    <View
      as="div"
      data-testid="add-rating-row"
      textAlign="center"
      margin="0"
      height="1.688rem"
      onMouseOver={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {isHovered && (
        <View as="div" cursor="pointer" onClick={onClick}>
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

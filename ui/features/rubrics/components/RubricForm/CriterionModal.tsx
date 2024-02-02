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
import type {RubricRating} from '@canvas/rubrics/react/types/rubric'
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

const I18n = useI18nScope('rubrics-criterion-modal')

export const DEFAULT_RUBRIC_RATINGS: RubricRating[] = [
  {
    id: '-1',
    points: 4,
    description: I18n.t('Exceeds'),
    longDescription: '',
  },
  {
    id: '-1',
    points: 3,
    description: I18n.t('Mastery'),
    longDescription: '',
  },
  {
    id: '-1',
    points: 2,
    description: I18n.t('Near'),
    longDescription: '',
  },
  {
    id: '-1',
    points: 1,
    description: I18n.t('Below'),
    longDescription: '',
  },
  {
    id: '-1',
    points: 0,
    description: I18n.t('No Evidence'),
    longDescription: '',
  },
]

type CriterionModalProps = {
  isOpen: boolean
  onDismiss: () => void
}
export const CriterionModal = ({isOpen, onDismiss}: CriterionModalProps) => {
  const [ratings, setRatings] = useState<RubricRating[]>(DEFAULT_RUBRIC_RATINGS)

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

  useEffect(() => {
    if (!isOpen) {
      setRatings(DEFAULT_RUBRIC_RATINGS)
    }
  }, [isOpen])

  return (
    <Modal
      open={isOpen}
      onDismiss={onDismiss}
      width="66.5rem"
      height="45.125rem"
      label={I18n.t('Rubric Criterion Modal')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
        <Heading>{I18n.t('Create New Criterion')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="x-small 0">
          <View as="span" margin="0 small 0 0">
            <TextInput
              renderLabel={I18n.t('Criterion Name')}
              placeholder={I18n.t('Enter the name')}
              display="inline-block"
              width="20.75rem"
              onChange={() => {}}
            />
          </View>
          <View as="span">
            <TextInput
              renderLabel={I18n.t('Criterion Description')}
              placeholder={I18n.t('Enter the description')}
              display="inline-block"
              width="41.75rem"
              onChange={() => {}}
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
            <Flex.Item margin="0 0 0 small">
              <View as="div">{I18n.t('Rating Description')}</View>
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
                <RatingRow rating={rating} scale={scale} onRemove={() => removeRating(index)} />
              </View>
            )
          })}

          <AddRatingRow onClick={() => addRating(ratings.length)} />
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Flex width="100%">
          <Flex.Item shouldShrink={true} shouldGrow={true}>
            <Checkbox label="Save this rating scale as default" value="medium" />
          </Flex.Item>
          <Flex.Item>
            <Button margin="0 x-small 0 0" onClick={onDismiss}>
              Cancel
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button color="primary" type="submit">
              {I18n.t('Save Criterion')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

type RatingRowProps = {
  rating: RubricRating
  scale: number
  onRemove: () => void
}
const RatingRow = ({rating, scale, onRemove}: RatingRowProps) => {
  return (
    <Flex>
      <Flex.Item>
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
      <Flex.Item>
        <View as="div" width="4.938rem">
          <NumberInput
            renderLabel={<ScreenReaderContent>{I18n.t('Rating Points')}</ScreenReaderContent>}
            value={rating.points}
            data-testid="rating-points"
          />
        </View>
      </Flex.Item>
      <Flex.Item>
        <View as="div" width="3rem" textAlign="center" cursor="pointer">
          <IconDragHandleLine />
        </View>
      </Flex.Item>
      <Flex.Item>
        <View as="div" width="8.875rem">
          <TextInput
            renderLabel={<ScreenReaderContent>{I18n.t('Rating Name')}</ScreenReaderContent>}
            display="inline-block"
            value={rating.description}
            onChange={() => {}}
            data-testid="rating-name"
          />
        </View>
      </Flex.Item>
      <Flex.Item shouldGrow={true} shouldShrink={true}>
        <View as="div" margin="0 small">
          <TextInput
            renderLabel={<ScreenReaderContent>{I18n.t('Rating Description')}</ScreenReaderContent>}
            display="inline-block"
            value={rating.longDescription}
            width="100%"
            onChange={() => {}}
            data-testid="rating-description"
          />
        </View>
      </Flex.Item>
      <Flex.Item>
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

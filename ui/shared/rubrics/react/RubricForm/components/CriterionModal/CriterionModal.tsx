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
import {useScope as createI18nScope} from '@canvas/i18n'
import type {RubricCriterion, RubricRating} from '@canvas/rubrics/react/types/rubric'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {CloseButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconCommentLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {FormMessage} from '@instructure/ui-form-field'
import type {DropResult} from 'react-beautiful-dnd'
import {WarningModal} from '../WarningModal'
import {autoGeneratePoints} from '../../utils'
import {CriterionModalFooter} from './CriterionModalFooter'
import {RatingsHeader} from './RatingsHeader'
import {reorderRatingsAtIndex} from '../../../utils'
import {DEFAULT_RUBRIC_RATINGS} from '../../constants'
import {RatingRows} from './RatingRows'

const I18n = createI18nScope('rubrics-criterion-modal')

export type CriterionModalProps = {
  criterion?: RubricCriterion
  criterionUseRangeEnabled: boolean
  hidePoints: boolean
  isOpen: boolean
  unassessed: boolean
  freeFormCriterionComments: boolean
  onSave: (criterion: RubricCriterion) => void
  onDismiss: () => void
}
export const CriterionModal = ({
  criterion,
  criterionUseRangeEnabled,
  hidePoints,
  isOpen,
  unassessed,
  freeFormCriterionComments,
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
  const [showWarningModal, setShowWarningModal] = useState(false)

  const [maxPoints, setMaxPoints] = useState<string | number>(0)

  useEffect(() => {
    const maxRatingPoints = ratings.length ? Math.max(...ratings.map(r => r.points), 0) : 0
    setMaxPoints(maxRatingPoints)
  }, [ratings])

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

  const handleDismiss = () => {
    const hasRatingsChanged = JSON.stringify(existingRatings) !== JSON.stringify(ratings)
    const hasDescriptionChanged = existingDescription !== criterionDescription
    const hasLongDescriptionChanged = existingLongDescription !== criterionLongDescription
    const hasCriterionUseRangeChanged = existingCriterionUseRange !== criterionUseRange
    const hasDataChanged =
      hasRatingsChanged ||
      hasDescriptionChanged ||
      hasLongDescriptionChanged ||
      hasCriterionUseRangeChanged

    if (hasDataChanged) {
      setShowWarningModal(true)
    } else {
      onDismiss()
    }
  }

  const handleDragStart = () => {
    setDragging(true)
  }

  const handleDragEnd = (result: DropResult) => {
    const {source, destination} = result
    if (!destination) {
      return
    }

    const reorderedItems = reorderRatingsAtIndex({
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

  return (
    <>
      <WarningModal
        isOpen={showWarningModal}
        onDismiss={() => setShowWarningModal(false)}
        onCancel={onDismiss}
      />

      <Modal
        open={isOpen}
        onDismiss={handleDismiss}
        width="66.5rem"
        height="45.125rem"
        label={I18n.t('Rubric Criterion Modal')}
        shouldCloseOnDocumentClick={false}
        data-testid="rubric-criterion-modal"
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={handleDismiss}
            screenReaderLabel="Close"
          />
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
                  onChange={(_e, value) => setCriterionDescription(value)}
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
                  onChange={(_e, value) => setCriterionLongDescription(value)}
                  data-testid="rubric-criterion-description-input"
                />
              </View>
            </Flex>
          </View>

          <View as="div" margin="medium 0 0 0" themeOverride={{marginMedium: '1.25rem'}}>
            <Flex>
              <Flex.Item shouldGrow={true}>
                {unassessed &&
                  criterionUseRangeEnabled &&
                  !hidePoints &&
                  !freeFormCriterionComments && (
                    <Checkbox
                      label={I18n.t('Enable Range')}
                      checked={criterionUseRange}
                      onChange={e => setCriterionUseRange(e.target.checked)}
                      data-testid="enable-range-checkbox"
                    />
                  )}
                {freeFormCriterionComments && (
                  <View
                    as="span"
                    margin="0 small 0 0"
                    data-testid="free-form-criterion-comments-label"
                  >
                    <IconCommentLine size="x-small" themeOverride={{sizeXSmall: '1.5rem'}} />{' '}
                    <Text weight="bold">{I18n.t('Written Feedback')}</Text>
                  </View>
                )}
              </Flex.Item>
              <Flex.Item>
                {!hidePoints && (
                  <>
                    <Flex gap="small">
                      <Flex.Item>
                        <TextInput
                          data-testid="max-points-input"
                          renderLabel={
                            <ScreenReaderContent>{I18n.t('Maximum Points')}</ScreenReaderContent>
                          }
                          display="inline-block"
                          width="4rem"
                          value={maxPoints.toString()}
                          onChange={(_e, value) => {
                            setMaxPoints(value)
                          }}
                          onBlur={e => {
                            let newMaxPoints = Number(e.target.value)
                            if (Number.isNaN(newMaxPoints) || newMaxPoints < 0) {
                              newMaxPoints = 5
                            }
                            setMaxPoints(newMaxPoints)
                            const updatedRatings = autoGeneratePoints(ratings, newMaxPoints)
                            setRatings(updatedRatings)
                          }}
                        />
                      </Flex.Item>
                      <Flex.Item>
                        <Heading
                          level="h2"
                          as="h2"
                          themeOverride={{
                            h2FontWeight: 700,
                            h2FontSize: '22px',
                            lineHeight: '1.75rem',
                          }}
                        >
                          {I18n.t(' Points Possible')}
                        </Heading>
                      </Flex.Item>
                    </Flex>
                  </>
                )}
              </Flex.Item>
            </Flex>
          </View>

          {!freeFormCriterionComments && (
            <>
              <RatingsHeader criterionUseRange={criterionUseRange} hidePoints={hidePoints} />

              <RatingRows
                ratings={ratings}
                handleDragStart={handleDragStart}
                handleDragEnd={handleDragEnd}
                addRating={addRating}
                removeRating={removeRating}
                updateRating={updateRating}
                reorderRatings={reorderRatings}
                checkValidation={checkValidation}
                criterionUseRange={criterionUseRange}
                dragging={dragging}
                hidePoints={hidePoints}
                unassessed={unassessed}
              />
            </>
          )}
        </Modal.Body>
        <Modal.Footer>
          <CriterionModalFooter
            savingCriterion={savingCriterion}
            handleDismiss={handleDismiss}
            saveChanges={saveChanges}
          />
        </Modal.Footer>
      </Modal>
    </>
  )
}

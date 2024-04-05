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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {NumberInput} from '@instructure/ui-number-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Table} from '@instructure/ui-table'

const I18n = useI18nScope('rubrics-criterion-modal')

export type OutcomeCriterionModalProps = {
  criterion?: RubricCriterion
  isOpen: boolean
  onSave: (criterion: RubricCriterion) => void
  onDismiss: () => void
}
export const OutcomeCriterionModal = ({
  criterion,
  isOpen,
  onDismiss,
  onSave,
}: OutcomeCriterionModalProps) => {
  const [ratings, setRatings] = useState<RubricRating[]>([])
  const [criterionDescription, setCriterionDescription] = useState('')
  const [criterionLongDescription, setCriterionLongDescription] = useState('')

  const {
    description: existingDescription,
    longDescription: existingLongDescription,
    ratings: existingRatings,
  } = criterion ?? {}

  useEffect(() => {
    if (isOpen) {
      setCriterionDescription(existingDescription ?? '')
      setCriterionLongDescription(existingLongDescription ?? '')
      if (existingRatings) {
        setRatings(existingRatings)
      }
    }
  }, [existingDescription, existingLongDescription, existingRatings, isOpen])

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

  const saveChanges = () => {
    const newCriterion: RubricCriterion = {
      id: criterion?.id ?? '',
      description: criterionDescription,
      longDescription: criterionLongDescription,
      ratings,
      outcome: {
        displayName: criterion?.outcome?.displayName ?? '',
        title: criterion?.outcome?.title ?? '',
      },
      points: Math.max(...ratings.map(r => r.points), 0),
      criterionUseRange: false,
      ignoreForScoring: criterion?.ignoreForScoring ?? false,
      masteryPoints: criterion?.masteryPoints ?? 0,
      learningOutcomeId: criterion?.learningOutcomeId ?? undefined,
    }

    onSave(newCriterion)
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={onDismiss}
      width="66.5rem"
      height="45.125rem"
      label={I18n.t('Rubric Outcome Criterion Modal')}
      shouldCloseOnDocumentClick={false}
      data-testid="outcome-rubric-criterion-modal"
    >
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
        <Heading>{I18n.t('Edit Criterion from Outcome')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="0" display="flex">
          <View as="span" margin="0 0 0 small" themeOverride={{marginSmall: '0.75rem'}}>
            <View as="div">
              <Text weight="bold">{I18n.t('Criterion Name')}</Text>
            </View>
            <View as="div">
              <Text data-testid="outcome-title">{criterion?.outcome?.title}</Text>
            </View>
          </View>
          <View as="span" margin="auto">
            <View as="div">
              <Text weight="bold">{I18n.t('Friendly Name')}</Text>
            </View>
            <View as="div">
              <Text data-testid="outcome-friendly-name">{criterion?.outcome?.displayName}</Text>
            </View>
          </View>
        </View>
        <View as="div" margin="small 0 0 0" display="flex">
          <View as="span" margin="0 0 0 small" themeOverride={{marginSmall: '0.75rem'}}>
            <View as="div">
              <Text weight="bold">{I18n.t('Description')}</Text>
            </View>
            <View as="div">
              <Text data-testid="outcome-description">{criterion?.description}</Text>
            </View>
          </View>
        </View>
        <View as="div" margin="medium 0 0 0" display="flex">
          <Table caption={I18n.t('Outcome Criterion Edit')}>
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="Display" textAlign="center">
                  Display
                </Table.ColHeader>
                <Table.ColHeader id="Title">Points</Table.ColHeader>
                <Table.ColHeader id="Year">Rating Name</Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {ratings.map((rating, index) => {
                const scale = ratings.length - (index + 1)
                return (
                  <Table.Row key={rating.id}>
                    <Table.RowHeader textAlign="center">{scale}</Table.RowHeader>
                    <Table.Cell>
                      <NumberInput
                        renderLabel={
                          <ScreenReaderContent>{I18n.t('Rating Points')}</ScreenReaderContent>
                        }
                        value={rating.points}
                        onIncrement={() =>
                          updateRating(index, {...rating, points: rating.points + 1})
                        }
                        onDecrement={() =>
                          updateRating(index, {...rating, points: rating.points - 1})
                        }
                        onChange={(e, value) =>
                          updateRating(index, {...rating, points: Number(value ?? 0)})
                        }
                        data-testid="rating-points"
                        width="4.938rem"
                        onBlur={reorderRatings}
                      />
                    </Table.Cell>
                    <Table.Cell data-testid="outcome-rating-description">
                      {rating.description}
                    </Table.Cell>
                  </Table.Row>
                )
              })}
            </Table.Body>
          </Table>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Flex width="100%">
          <Flex.Item>
            <Button
              margin="0 x-small 0 0"
              onClick={onDismiss}
              data-testid="outcome-rubric-criterion-cancel"
            >
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button
              color="primary"
              type="submit"
              onClick={() => saveChanges()}
              data-testid="outcome-rubric-criterion-save"
            >
              {I18n.t('Save Criterion')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

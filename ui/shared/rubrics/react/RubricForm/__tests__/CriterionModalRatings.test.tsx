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

import React from 'react'
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {CriterionModal, type CriterionModalProps} from '../components/CriterionModal/CriterionModal'
import {DEFAULT_RUBRIC_RATINGS} from '../constants'
import {reorderRatingsAtIndex} from '../../utils'

describe('CriterionModal Ratings', () => {
  const renderComponent = (props?: Partial<CriterionModalProps>) => {
    return render(
      <CriterionModal
        isOpen={true}
        criterionUseRangeEnabled={true}
        onDismiss={() => {}}
        onSave={() => {}}
        hidePoints={false}
        freeFormCriterionComments={false}
        isFullWidth={false}
        {...props}
      />,
    )
  }

  const DEFAULT_CRITERION: RubricCriterion = {
    id: '1',
    description: 'Test Criterion',
    points: 10,
    criterionUseRange: false,
    ignoreForScoring: false,
    longDescription: '',
    masteryPoints: 0,
    learningOutcomeId: '',
    ratings: [{id: '1', description: 'Test Rating', points: 0, longDescription: ''}],
  }

  const getCriterion = (props?: Partial<RubricCriterion>) => {
    return {
      ...DEFAULT_CRITERION,
      ...props,
    }
  }

  it('should render the default ratings', () => {
    const {queryAllByTestId} = renderComponent()

    for (let i = 0; i < DEFAULT_RUBRIC_RATINGS.length; i++) {
      const ratingName = queryAllByTestId(`rating-name`)[i] as HTMLInputElement
      const ratingPoints = queryAllByTestId(`rating-points`)[i] as HTMLInputElement
      const ratingScale = queryAllByTestId(`rating-scale`)[i] as HTMLInputElement
      const expectedRatingScale = DEFAULT_RUBRIC_RATINGS.length - (i + 1)
      expect(ratingPoints.value).toEqual(DEFAULT_RUBRIC_RATINGS[i].points.toString())
      expect(ratingName.value).toEqual(DEFAULT_RUBRIC_RATINGS[i].description.toString())
      expect(ratingScale.value).toEqual(expectedRatingScale.toString())
      expect(ratingScale).toBeDisabled()
    }
  })

  it('should add a new rating to the end of the list', () => {
    const {getByTestId, queryAllByTestId} = renderComponent()
    const addRatingRow = getByTestId('add-rating-button')

    fireEvent.mouseOver(addRatingRow)
    fireEvent.click(addRatingRow.firstChild as Element)

    const totalRatingNames = queryAllByTestId('rating-name')
    expect(totalRatingNames).toHaveLength(DEFAULT_RUBRIC_RATINGS.length + 1)

    const newLastIndex = totalRatingNames.length - 1
    const ratingName = totalRatingNames[newLastIndex] as HTMLInputElement
    const ratingPoints = queryAllByTestId(`rating-points`)[newLastIndex] as HTMLInputElement
    const ratingScale = queryAllByTestId(`rating-scale`)[newLastIndex] as HTMLInputElement
    expect(ratingPoints.value).toEqual('0')
    expect(ratingName.value).toEqual('')
    expect(ratingScale.value).toEqual('0')
  })

  it('should remove a rating at specified index', async () => {
    const {queryAllByTestId, getByTestId, queryByTestId} = renderComponent()
    const ratingPopover = queryAllByTestId('rating-options-popover')[2]
    fireEvent.click(ratingPopover)

    await waitFor(() => {
      expect(queryByTestId('delete-rating-menu-item')).not.toBeNull()
    })
    fireEvent.click(getByTestId('delete-rating-menu-item'))

    const totalRatingNames = queryAllByTestId('rating-name')
    expect(totalRatingNames).toHaveLength(DEFAULT_RUBRIC_RATINGS.length - 1)

    const removedRating = totalRatingNames.find(
      ratingName =>
        (ratingName as HTMLInputElement).value === DEFAULT_RUBRIC_RATINGS[2].description,
    )
    expect(removedRating).toBeUndefined()
  })

  it('should reorder ratings after drag and drop, but keep point values at the same index', () => {
    const ratings = [
      {id: '1', points: 4, description: 'Exceeds', longDescription: ''},
      {id: '2', points: 3, description: 'Mastery', longDescription: ''},
      {id: '3', points: 2, description: 'Near', longDescription: ''},
      {id: '4', points: 1, description: 'Below', longDescription: ''},
      {id: '5', points: 0, description: 'No Evidence', longDescription: ''},
    ]

    const startIndex = 0
    const endIndex = 3

    const reorderedRatings = reorderRatingsAtIndex({list: ratings, startIndex, endIndex})

    const expectedRatings = [
      {id: '2', points: 4, description: 'Mastery', longDescription: ''},
      {id: '3', points: 3, description: 'Near', longDescription: ''},
      {id: '4', points: 2, description: 'Below', longDescription: ''},
      {id: '1', points: 1, description: 'Exceeds', longDescription: ''},
      {id: '5', points: 0, description: 'No Evidence', longDescription: ''},
    ]

    expect(reorderedRatings).toEqual(expectedRatings)
  })

  it('should reorder ratings when a rating is changed to be higher than the top rating', () => {
    const ratings = [
      {id: '1', description: 'First Rating', points: 10, longDescription: ''},
      {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
      {id: '3', description: 'Third Rating', points: 6, longDescription: ''},
      {id: '4', description: 'Fourth Rating', points: 4, longDescription: ''},
    ]
    const criterion = getCriterion({ratings})
    const {queryAllByTestId} = renderComponent({criterion})
    const ratingPoints = queryAllByTestId(`rating-points`)[2] as HTMLInputElement

    fireEvent.change(ratingPoints, {target: {value: '20'}})
    fireEvent.focus(ratingPoints)
    fireEvent.blur(ratingPoints)

    const totalRatingNames = queryAllByTestId('rating-name') as HTMLInputElement[]
    expect(totalRatingNames[0].value).toEqual(ratings[0].description)
    expect(totalRatingNames[1].value).toEqual(ratings[1].description)
    expect(totalRatingNames[2].value).toEqual(ratings[2].description)
    expect(totalRatingNames[3].value).toEqual(ratings[3].description)

    const totalRatingPoints = queryAllByTestId('rating-points') as HTMLInputElement[]
    expect(totalRatingPoints[0].value).toEqual('20')
    expect(totalRatingPoints[1].value).toEqual('10')
    expect(totalRatingPoints[2].value).toEqual('8')
    expect(totalRatingPoints[3].value).toEqual('4')
  })

  it('should reorder ratings when a rating is changed to be lower than a previous rating', () => {
    const ratings = [
      {id: '1', description: 'First Rating', points: 10, longDescription: ''},
      {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
      {id: '3', description: 'Third Rating', points: 6, longDescription: ''},
      {id: '4', description: 'Fourth Rating', points: 4, longDescription: ''},
    ]
    const criterion = getCriterion({ratings})
    const {queryAllByTestId} = renderComponent({criterion})
    const ratingPoints = queryAllByTestId(`rating-points`)[0] as HTMLInputElement

    fireEvent.change(ratingPoints, {target: {value: '2'}})
    fireEvent.focus(ratingPoints)
    fireEvent.blur(ratingPoints)

    const totalRatingNames = queryAllByTestId('rating-name') as HTMLInputElement[]
    expect(totalRatingNames[0].value).toEqual(ratings[0].description)
    expect(totalRatingNames[1].value).toEqual(ratings[1].description)
    expect(totalRatingNames[2].value).toEqual(ratings[2].description)
    expect(totalRatingNames[3].value).toEqual(ratings[3].description)

    const totalRatingPoints = queryAllByTestId('rating-points') as HTMLInputElement[]
    expect(totalRatingPoints[0].value).toEqual('8')
    expect(totalRatingPoints[1].value).toEqual('6')
    expect(totalRatingPoints[2].value).toEqual('4')
    expect(totalRatingPoints[3].value).toEqual('2')
  })

  it('should not render range checkbox if FF is false', () => {
    const {queryByTestId} = renderComponent({criterionUseRangeEnabled: false})

    expect(queryByTestId('enable-range-checkbox')).toBeNull()
  })

  it('should allow for decimal ratings', () => {
    const ratings = [
      {id: '1', description: 'First Rating', points: 10, longDescription: ''},
      {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
      {id: '3', description: 'Third Rating', points: 6, longDescription: ''},
      {id: '4', description: 'Fourth Rating', points: 4, longDescription: ''},
    ]
    const criterion = getCriterion({ratings})
    const {queryAllByTestId} = renderComponent({criterion})

    const ratingToUpdate = queryAllByTestId(`rating-points`)[2] as HTMLInputElement

    const typeValue = (value: string) => {
      value.split('').forEach(char => {
        fireEvent.keyDown(ratingToUpdate, {
          key: char,
          code: `Key${char}`,
          charCode: char.charCodeAt(0),
        })
        fireEvent.keyPress(ratingToUpdate, {
          key: char,
          code: `Key${char}`,
          charCode: char.charCodeAt(0),
        })
        fireEvent.keyUp(ratingToUpdate, {
          key: char,
          code: `Key${char}`,
          charCode: char.charCodeAt(0),
        })

        // Update the input value manually because React Testing Library doesn't update the value automatically
        fireEvent.change(ratingToUpdate, {target: {value: ratingToUpdate.value + char}})
      })
    }
    fireEvent.change(ratingToUpdate, {target: {value: ''}})
    typeValue('10.5')
    fireEvent.blur(ratingToUpdate)

    const totalRatingPoints = queryAllByTestId('rating-points') as HTMLInputElement[]
    expect(totalRatingPoints[0].value).toEqual('10.5')
    expect(totalRatingPoints[1].value).toEqual('10')
    expect(totalRatingPoints[2].value).toEqual('8')
    expect(totalRatingPoints[3].value).toEqual('4')
  })

  it('should move a rating up', async () => {
    const ratings = [
      {id: '1', description: 'First Rating', points: 10, longDescription: ''},
      {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
      {id: '3', description: 'Third Rating', points: 6, longDescription: ''},
      {id: '4', description: 'Fourth Rating', points: 4, longDescription: ''},
    ]
    const criterion = getCriterion({ratings})
    const {queryAllByTestId, getByTestId, queryByTestId} = renderComponent({criterion})
    const ratingPopover = queryAllByTestId('rating-options-popover')[2]
    fireEvent.click(ratingPopover)

    await waitFor(() => {
      expect(queryByTestId('move-up-rating-menu-item')).not.toBeNull()
    })
    fireEvent.click(getByTestId('move-up-rating-menu-item'))

    const totalRatingNames = queryAllByTestId('rating-name') as HTMLInputElement[]
    expect(totalRatingNames[0].value).toEqual(ratings[0].description)
    expect(totalRatingNames[1].value).toEqual(ratings[2].description)
    expect(totalRatingNames[2].value).toEqual(ratings[1].description)
    expect(totalRatingNames[3].value).toEqual(ratings[3].description)

    const totalRatingPoints = queryAllByTestId('rating-points') as HTMLInputElement[]
    expect(totalRatingPoints[0].value).toEqual('10')
    expect(totalRatingPoints[1].value).toEqual('8')
    expect(totalRatingPoints[2].value).toEqual('6')
    expect(totalRatingPoints[3].value).toEqual('4')
  })

  it('should move a rating down', async () => {
    const ratings = [
      {id: '1', description: 'First Rating', points: 10, longDescription: ''},
      {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
      {id: '3', description: 'Third Rating', points: 6, longDescription: ''},
      {id: '4', description: 'Fourth Rating', points: 4, longDescription: ''},
    ]
    const criterion = getCriterion({ratings})
    const {queryAllByTestId, getByTestId, queryByTestId} = renderComponent({criterion})
    const ratingPopover = queryAllByTestId('rating-options-popover')[0]
    fireEvent.click(ratingPopover)

    await waitFor(() => {
      expect(queryByTestId('move-down-rating-menu-item')).not.toBeNull()
    })
    fireEvent.click(getByTestId('move-down-rating-menu-item'))

    const totalRatingNames = queryAllByTestId('rating-name') as HTMLInputElement[]
    expect(totalRatingNames[0].value).toEqual(ratings[1].description)
    expect(totalRatingNames[1].value).toEqual(ratings[0].description)
    expect(totalRatingNames[2].value).toEqual(ratings[2].description)
    expect(totalRatingNames[3].value).toEqual(ratings[3].description)

    const totalRatingPoints = queryAllByTestId('rating-points') as HTMLInputElement[]
    expect(totalRatingPoints[0].value).toEqual('10')
    expect(totalRatingPoints[1].value).toEqual('8')
    expect(totalRatingPoints[2].value).toEqual('6')
    expect(totalRatingPoints[3].value).toEqual('4')
  })

  it('should have the move up button disabled if the rating is the first rating', async () => {
    const ratings = [
      {id: '1', description: 'First Rating', points: 10, longDescription: ''},
      {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
      {id: '3', description: 'Third Rating', points: 6, longDescription: ''},
      {id: '4', description: 'Fourth Rating', points: 4, longDescription: ''},
    ]
    const criterion = getCriterion({ratings})
    const {queryAllByTestId, queryByTestId} = renderComponent({criterion})
    const ratingPopover = queryAllByTestId('rating-options-popover')[0]
    fireEvent.click(ratingPopover)

    await waitFor(() => {
      expect(queryByTestId('move-up-rating-menu-item')).not.toBeNull()
    })

    const moveUpButton = queryByTestId('move-up-rating-menu-item')
    expect(moveUpButton).toHaveAttribute('aria-disabled', 'true')

    fireEvent.click(moveUpButton!)

    const totalRatingNames = queryAllByTestId('rating-name') as HTMLInputElement[]
    expect(totalRatingNames[0].value).toEqual(ratings[0].description)
    expect(totalRatingNames[1].value).toEqual(ratings[1].description)
    expect(totalRatingNames[2].value).toEqual(ratings[2].description)
    expect(totalRatingNames[3].value).toEqual(ratings[3].description)
  })

  it('should have the move down button disabled if the rating is the last rating', async () => {
    const ratings = [
      {id: '1', description: 'First Rating', points: 10, longDescription: ''},
      {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
      {id: '3', description: 'Third Rating', points: 6, longDescription: ''},
      {id: '4', description: 'Fourth Rating', points: 4, longDescription: ''},
    ]
    const criterion = getCriterion({ratings})
    const {queryAllByTestId, queryByTestId} = renderComponent({criterion})
    const ratingPopover = queryAllByTestId('rating-options-popover')[3]
    fireEvent.click(ratingPopover)

    await waitFor(() => {
      expect(queryByTestId('move-down-rating-menu-item')).not.toBeNull()
    })

    const moveDownButton = queryByTestId('move-down-rating-menu-item')
    expect(moveDownButton).toHaveAttribute('aria-disabled', 'true')

    fireEvent.click(moveDownButton!)

    const totalRatingNames = queryAllByTestId('rating-name') as HTMLInputElement[]
    expect(totalRatingNames[0].value).toEqual(ratings[0].description)
    expect(totalRatingNames[1].value).toEqual(ratings[1].description)
    expect(totalRatingNames[2].value).toEqual(ratings[2].description)
    expect(totalRatingNames[3].value).toEqual(ratings[3].description)
  })
})

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
import {fireEvent, render} from '@testing-library/react'
import {CriterionModal, DEFAULT_RUBRIC_RATINGS, type CriterionModalProps} from '../CriterionModal'
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'

describe('CriterionModal tests', () => {
  const renderComponent = (props?: Partial<CriterionModalProps>) => {
    return render(
      <CriterionModal
        isOpen={true}
        unassessed={true}
        onDismiss={() => {}}
        onSave={() => {}}
        {...props}
      />
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

  describe('Ratings Tests', () => {
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
      }
    })

    it('should add a new rating at specified index', () => {
      const {queryAllByTestId} = renderComponent()
      const addRatingRow = queryAllByTestId('add-rating-row')[1]

      fireEvent.mouseOver(addRatingRow)
      fireEvent.click(addRatingRow.firstChild as Element)

      const totalRatingNames = queryAllByTestId('rating-name')
      expect(totalRatingNames.length).toEqual(DEFAULT_RUBRIC_RATINGS.length + 1)

      const ratingName = totalRatingNames[1] as HTMLInputElement
      const ratingPoints = queryAllByTestId(`rating-points`)[1] as HTMLInputElement
      const ratingScale = queryAllByTestId(`rating-scale`)[1] as HTMLInputElement
      expect(ratingPoints.value).toEqual(DEFAULT_RUBRIC_RATINGS[0].points.toString())
      expect(ratingName.value).toEqual('')
      expect(ratingScale.value).toEqual((DEFAULT_RUBRIC_RATINGS.length - 1).toString())
    })

    it('should add a new rating to the end of the list', () => {
      const {queryAllByTestId} = renderComponent()
      const addRatingRow = queryAllByTestId('add-rating-row')[DEFAULT_RUBRIC_RATINGS.length]

      fireEvent.mouseOver(addRatingRow)
      fireEvent.click(addRatingRow.firstChild as Element)

      const totalRatingNames = queryAllByTestId('rating-name')
      expect(totalRatingNames.length).toEqual(DEFAULT_RUBRIC_RATINGS.length + 1)

      const newLastIndex = totalRatingNames.length - 1
      const ratingName = totalRatingNames[newLastIndex] as HTMLInputElement
      const ratingPoints = queryAllByTestId(`rating-points`)[newLastIndex] as HTMLInputElement
      const ratingScale = queryAllByTestId(`rating-scale`)[newLastIndex] as HTMLInputElement
      expect(ratingPoints.value).toEqual('0')
      expect(ratingName.value).toEqual('')
      expect(ratingScale.value).toEqual('0')
    })

    it('should remove a rating at specified index', () => {
      const {queryAllByTestId} = renderComponent()
      const removeRating = queryAllByTestId('remove-rating')[2]

      fireEvent.click(removeRating)

      const totalRatingNames = queryAllByTestId('rating-name')
      expect(totalRatingNames.length).toEqual(DEFAULT_RUBRIC_RATINGS.length - 1)

      const removedRating = totalRatingNames.find(
        ratingName =>
          (ratingName as HTMLInputElement).value === DEFAULT_RUBRIC_RATINGS[2].description
      )
      expect(removedRating).toBeUndefined()
    })

    it('should drag and drop a rating to a new index', () => {
      const ratings = [
        {id: '1', description: 'Rating 1', points: 0, longDescription: ''},
        {id: '2', description: 'Rating 2', points: 0, longDescription: ''},
        {id: '3', description: 'Rating 3', points: 0, longDescription: ''},
      ]
      const {queryAllByTestId} = renderComponent({criterion: getCriterion({ratings})})
      const dragRating = queryAllByTestId('rating-drag-handle')[0]
      const dropRating = queryAllByTestId('rating-drag-handle')[2]

      fireEvent.dragStart(dragRating)
      fireEvent.dragOver(dropRating)
      fireEvent.drop(dropRating)

      const totalRatingNames = queryAllByTestId('rating-name').map(
        ratingName => (ratingName as HTMLInputElement).value
      )
      expect(totalRatingNames.length).toEqual(ratings.length)

      const newFirstIndex = totalRatingNames.findIndex(
        ratingName => ratingName === ratings[0].description
      )
      const newLastIndex = totalRatingNames.findIndex(
        ratingName => ratingName === ratings[2].description
      )

      expect(newFirstIndex).toEqual(2)
      expect(newLastIndex).toEqual(1)
    })

    it('should reorder ratings when a rating is changed to be higher than the top rating', () => {
      const ratings = [
        {id: '1', description: 'First Rating', points: 10, longDescription: ''},
        {id: '1', description: 'Second Rating', points: 8, longDescription: ''},
        {id: '1', description: 'Third Rating', points: 6, longDescription: ''},
        {id: '1', description: 'Fourth Rating', points: 4, longDescription: ''},
      ]
      const criterion = getCriterion({ratings})
      const {queryAllByTestId} = renderComponent({criterion})
      const ratingPoints = queryAllByTestId(`rating-points`)[2] as HTMLInputElement

      fireEvent.change(ratingPoints, {target: {value: '20'}})
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
        {id: '1', description: 'Second Rating', points: 8, longDescription: ''},
        {id: '1', description: 'Third Rating', points: 6, longDescription: ''},
        {id: '1', description: 'Fourth Rating', points: 4, longDescription: ''},
      ]
      const criterion = getCriterion({ratings})
      const {queryAllByTestId} = renderComponent({criterion})
      const ratingPoints = queryAllByTestId(`rating-points`)[0] as HTMLInputElement

      fireEvent.change(ratingPoints, {target: {value: '2'}})
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
  })

  describe('Save and Cancel Tests', () => {
    it('save button should not be disabled if there is a criterion name and rating name', () => {
      const criterion = getCriterion()
      const {getByTestId} = renderComponent({criterion})

      expect(getByTestId('rubric-criterion-save')).not.toBeDisabled()
    })

    it('save button should be disabled if there is no criterion name', () => {
      const criterion = getCriterion({description: ''})

      const {getByTestId} = renderComponent({criterion})

      expect(getByTestId('rubric-criterion-save')).toBeDisabled()
    })

    it('save button should be disabled if there is no rating name', () => {
      const criterion = getCriterion({
        ratings: [{id: '1', description: '', points: 0, longDescription: ''}],
      })

      const {getByTestId} = renderComponent({criterion})

      expect(getByTestId('rubric-criterion-save')).toBeDisabled()
    })

    it('save button should be disabled if there is only a single rating with no name', () => {
      const ratings = [
        {id: '1', description: 'Valid', points: 0, longDescription: ''},
        {id: '1', description: 'Valid', points: 0, longDescription: ''},
        {id: '1', description: '', points: 0, longDescription: ''},
        {id: '1', description: 'Valid', points: 0, longDescription: ''},
      ]
      const criterion = getCriterion({ratings})

      const {getByTestId} = renderComponent({criterion})

      expect(getByTestId('rubric-criterion-save')).toBeDisabled()
    })

    it('should call onSave when save button is clicked', () => {
      const onSave = jest.fn()
      const criterion = getCriterion()

      const {getByTestId} = renderComponent({onSave, criterion})

      fireEvent.click(getByTestId('rubric-criterion-save'))

      expect(onSave).toHaveBeenCalled()
    })

    it('should call onDismiss when cancel button is clicked', () => {
      const onDismiss = jest.fn()
      const {getByTestId} = renderComponent({onDismiss})

      fireEvent.click(getByTestId('rubric-criterion-cancel'))

      expect(onDismiss).toHaveBeenCalled()
    })
  })

  describe('Assessed rubric tests', () => {
    it('should not render editable inputs if the rubric is assessed', () => {
      const {queryByTestId, queryAllByTestId} = renderComponent({unassessed: false})

      expect(queryByTestId('enable-range-checkbox')).toBeNull()
      expect(queryAllByTestId('rating-points').length).toEqual(0)
      expect(queryAllByTestId('rating-points-assessed').length).toEqual(5)
    })

    it('should not add a new rating if the rubric is assessed', () => {
      const {queryAllByTestId} = renderComponent({unassessed: false})
      const addRatingRow = queryAllByTestId('add-rating-row')[1]

      fireEvent.mouseOver(addRatingRow)
      expect(addRatingRow).toBeEmptyDOMElement()
    })

    it('should not add a new rating if the rubric is assessed when hovering over the last add rating row', () => {
      const {queryAllByTestId} = renderComponent({unassessed: false})
      const addRatingRow = queryAllByTestId('add-rating-row')[DEFAULT_RUBRIC_RATINGS.length]

      fireEvent.mouseOver(addRatingRow)
      expect(addRatingRow).toBeEmptyDOMElement()
    })
  })
})

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
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import {fireEvent, render} from '@testing-library/react'
import {CriterionModal, type CriterionModalProps} from '../components/CriterionModal/CriterionModal'
import {DEFAULT_RUBRIC_RATINGS} from '../constants'
import {reorderRatingsAtIndex} from '../../utils'

describe('CriterionModal tests', () => {
  const renderComponent = (props?: Partial<CriterionModalProps>) => {
    return render(
      <CriterionModal
        isOpen={true}
        unassessed={true}
        criterionUseRangeEnabled={true}
        onDismiss={() => {}}
        onSave={() => {}}
        hidePoints={false}
        freeFormCriterionComments={false}
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

  describe('Ratings Tests', () => {
    it('should render the default ratings', () => {
      const {queryAllByTestId} = renderComponent()

      for (let i = 0; i < DEFAULT_RUBRIC_RATINGS.length; i++) {
        const ratingName = queryAllByTestId(`rating-name`)[i] as HTMLInputElement
        const ratingPoints = queryAllByTestId(`rating-points`)[i] as HTMLInputElement
        const ratingScale = queryAllByTestId(`rating-scale`)[i] as HTMLElement
        const expectedRatingScale = DEFAULT_RUBRIC_RATINGS.length - (i + 1)
        expect(ratingPoints.value).toEqual(DEFAULT_RUBRIC_RATINGS[i].points.toString())
        expect(ratingName.value).toEqual(DEFAULT_RUBRIC_RATINGS[i].description.toString())
        expect(ratingScale.textContent).toEqual(expectedRatingScale.toString())
      }
    })

    it('should add a new rating at specified index', () => {
      const {queryAllByTestId} = renderComponent()
      const addRatingRow = queryAllByTestId('add-rating-row')[1]

      fireEvent.mouseOver(addRatingRow)
      fireEvent.click(addRatingRow.firstChild as Element)

      const totalRatingNames = queryAllByTestId('rating-name')
      expect(totalRatingNames).toHaveLength(DEFAULT_RUBRIC_RATINGS.length + 1)

      const ratingName = totalRatingNames[1] as HTMLInputElement
      const ratingPoints = queryAllByTestId(`rating-points`)[1] as HTMLInputElement
      const ratingScale = queryAllByTestId(`rating-scale`)[1] as HTMLElement
      expect(ratingPoints.value).toEqual(DEFAULT_RUBRIC_RATINGS[0].points.toString())
      expect(ratingName.value).toEqual('')
      expect(ratingScale.textContent).toEqual((DEFAULT_RUBRIC_RATINGS.length - 1).toString())
    })

    it('should add a new rating to the end of the list', () => {
      const {queryAllByTestId} = renderComponent()
      const addRatingRow = queryAllByTestId('add-rating-row')[DEFAULT_RUBRIC_RATINGS.length]

      fireEvent.mouseOver(addRatingRow)
      fireEvent.click(addRatingRow.firstChild as Element)

      const totalRatingNames = queryAllByTestId('rating-name')
      expect(totalRatingNames).toHaveLength(DEFAULT_RUBRIC_RATINGS.length + 1)

      const newLastIndex = totalRatingNames.length - 1
      const ratingName = totalRatingNames[newLastIndex] as HTMLInputElement
      const ratingPoints = queryAllByTestId(`rating-points`)[newLastIndex] as HTMLInputElement
      const ratingScale = queryAllByTestId(`rating-scale`)[newLastIndex] as HTMLElement
      expect(ratingPoints.value).toEqual('0')
      expect(ratingName.value).toEqual('')
      expect(ratingScale.textContent).toEqual('0')
    })

    it('should remove a rating at specified index', () => {
      const {queryAllByTestId} = renderComponent()
      const removeRating = queryAllByTestId('remove-rating')[2]

      fireEvent.click(removeRating)

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
  })

  describe('Save and Cancel Tests', () => {
    it('save button should not be disabled if there is a criterion name and rating name', () => {
      const criterion = getCriterion()
      const {getByTestId} = renderComponent({criterion})

      expect(getByTestId('rubric-criterion-save')).not.toBeDisabled()
    })

    it('save button should display validation error if there is no criterion name', () => {
      const onSave = jest.fn()
      const criterion = getCriterion({description: ''})

      const {getByTestId, queryByText} = renderComponent({onSave, criterion})

      fireEvent.click(getByTestId('rubric-criterion-save'))

      expect(onSave).not.toHaveBeenCalled()
      expect(queryByText('Criteria Name Required')).not.toBeNull()
    })

    it('save button should display validation error if there is no rating name', () => {
      const onSave = jest.fn()
      const criterion = getCriterion({
        ratings: [{id: '1', description: '', points: 0, longDescription: ''}],
      })

      const {getByTestId, queryByText} = renderComponent({onSave, criterion})

      fireEvent.click(getByTestId('rubric-criterion-save'))

      expect(onSave).not.toHaveBeenCalled()
      expect(queryByText('Rating Name Required')).not.toBeNull()
    })

    it('save button should display validation error if there is only a single rating with no name', () => {
      const onSave = jest.fn()
      const ratings = [
        {id: '1', description: 'Valid', points: 0, longDescription: ''},
        {id: '1', description: 'Valid', points: 0, longDescription: ''},
        {id: '1', description: '', points: 0, longDescription: ''},
        {id: '1', description: 'Valid', points: 0, longDescription: ''},
      ]
      const criterion = getCriterion({ratings})

      const {getByTestId, queryByText} = renderComponent({onSave, criterion})

      fireEvent.click(getByTestId('rubric-criterion-save'))

      expect(onSave).not.toHaveBeenCalled()
      expect(queryByText('Rating Name Required')).not.toBeNull()
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

      const warningModal = getByTestId('rubric-assignment-exit-warning-modal')
      expect(warningModal).toBeInTheDocument()

      const exitWarningModalButton = getByTestId('exit-rubric-warning-button')
      expect(exitWarningModalButton).toBeInTheDocument()

      fireEvent.click(exitWarningModalButton)

      expect(onDismiss).toHaveBeenCalled()
    })
  })

  describe('Assessed rubric tests', () => {
    it('should not render editable inputs if the rubric is assessed', () => {
      const {queryByTestId, queryAllByTestId} = renderComponent({unassessed: false})

      expect(queryByTestId('enable-range-checkbox')).toBeNull()
      expect(queryAllByTestId('rating-points')).toHaveLength(0)
      expect(queryAllByTestId('rating-points-assessed')).toHaveLength(5)
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

  describe('Hide Points Tests', () => {
    it('does not render points input if hidePoints is true', () => {
      const {queryByTestId, queryAllByTestId} = renderComponent({hidePoints: true})

      expect(queryByTestId('enable-range-checkbox')).toBeNull()
      expect(queryAllByTestId('rating-points')).toHaveLength(0)
      expect(queryAllByTestId('rating-points-assessed')).toHaveLength(0)
    })

    it('does not render points read-only text if hidePoints is true', () => {
      const {queryByTestId, queryAllByTestId} = renderComponent({
        unassessed: false,
        hidePoints: true,
      })

      expect(queryByTestId('enable-range-checkbox')).toBeNull()
      expect(queryAllByTestId('rating-points')).toHaveLength(0)
      expect(queryAllByTestId('rating-points-assessed')).toHaveLength(0)
    })
  })

  describe('Warning Modal Tests', () => {
    it('should show call dismiss if nothing changed', () => {
      const onDismiss = jest.fn()
      const {getByTestId} = renderComponent({
        onDismiss,
        criterion: getCriterion(),
      })

      fireEvent.click(getByTestId('rubric-criterion-cancel'))
      expect(onDismiss).toHaveBeenCalled()
    })

    it('should show warning modal when criterion description has been changed', () => {
      const onDismiss = jest.fn()
      const {getByTestId} = renderComponent({
        onDismiss,
        criterion: getCriterion(),
      })

      const descriptionInput = getByTestId('rubric-criterion-name-input') as HTMLInputElement
      fireEvent.change(descriptionInput, {target: {value: 'Modified Criterion Description'}})

      fireEvent.click(getByTestId('rubric-criterion-cancel'))

      const warningModal = getByTestId('rubric-assignment-exit-warning-modal')
      expect(warningModal).toBeInTheDocument()

      const exitWarningModalButton = getByTestId('exit-rubric-warning-button')
      expect(exitWarningModalButton).toBeInTheDocument()

      fireEvent.click(exitWarningModalButton)
      expect(onDismiss).toHaveBeenCalled()
    })

    it('should show warning modal when criterion long description has been changed', () => {
      const onDismiss = jest.fn()
      const {getByTestId} = renderComponent({
        onDismiss,
        criterion: getCriterion(),
      })

      const longDescriptionInput = getByTestId(
        'rubric-criterion-description-input',
      ) as HTMLInputElement
      fireEvent.change(longDescriptionInput, {target: {value: 'Modified Long Description'}})

      fireEvent.click(getByTestId('rubric-criterion-cancel'))

      const warningModal = getByTestId('rubric-assignment-exit-warning-modal')
      expect(warningModal).toBeInTheDocument()

      const exitWarningModalButton = getByTestId('exit-rubric-warning-button')
      expect(exitWarningModalButton).toBeInTheDocument()

      fireEvent.click(exitWarningModalButton)
      expect(onDismiss).toHaveBeenCalled()
    })

    it('should show warning modal when criterion use range has been changed', () => {
      const onDismiss = jest.fn()
      const {getByTestId} = renderComponent({
        onDismiss,
        criterion: getCriterion({criterionUseRange: false}),
      })

      const useRangeCheckbox = getByTestId('enable-range-checkbox') as HTMLInputElement
      fireEvent.click(useRangeCheckbox)

      fireEvent.click(getByTestId('rubric-criterion-cancel'))

      const warningModal = getByTestId('rubric-assignment-exit-warning-modal')
      expect(warningModal).toBeInTheDocument()

      const exitWarningModalButton = getByTestId('exit-rubric-warning-button')
      expect(exitWarningModalButton).toBeInTheDocument()

      fireEvent.click(exitWarningModalButton)
      expect(onDismiss).toHaveBeenCalled()
    })

    it('should show warning modal when ratings have been changed', () => {
      const onDismiss = jest.fn()
      const {getByTestId, queryAllByTestId} = renderComponent({
        onDismiss,
        criterion: getCriterion(),
      })

      const ratingDescriptionInput = queryAllByTestId('rating-name')[0] as HTMLInputElement
      fireEvent.change(ratingDescriptionInput, {target: {value: 'Modified Rating'}})

      fireEvent.click(getByTestId('rubric-criterion-cancel'))

      const warningModal = getByTestId('rubric-assignment-exit-warning-modal')
      expect(warningModal).toBeInTheDocument()

      const exitWarningModalButton = getByTestId('exit-rubric-warning-button')
      expect(exitWarningModalButton).toBeInTheDocument()

      fireEvent.click(exitWarningModalButton)
      expect(onDismiss).toHaveBeenCalled()
    })
  })

  describe('Free Form Criterion Comments Tests', () => {
    it('should not render ratings if freeFormCriterionComments is true', () => {
      const {queryAllByTestId, getByTestId} = renderComponent({freeFormCriterionComments: true})

      expect(queryAllByTestId('rating-name')).toHaveLength(0)
      expect(queryAllByTestId('rating-points')).toHaveLength(0)
      expect(queryAllByTestId('rating-scale')).toHaveLength(0)
      expect(getByTestId('free-form-criterion-comments-label')).toHaveTextContent(
        'Written Feedback',
      )
    })
  })

  describe('Auto Generate Points Tests', () => {
    it('should auto-generate points for ratings when max points input is changed', () => {
      const ratings = [
        {id: '1', description: 'First Rating', points: 10, longDescription: ''},
        {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
        {id: '3', description: 'Third Rating', points: 6, longDescription: ''},
        {id: '4', description: 'Fourth Rating', points: 4, longDescription: ''},
      ]
      const criterion = getCriterion({ratings})
      const {queryAllByTestId} = renderComponent({criterion})

      const maxPointsInput = queryAllByTestId('max-points-input')[0] as HTMLInputElement
      fireEvent.change(maxPointsInput, {target: {value: '20'}})
      fireEvent.blur(maxPointsInput)

      const totalRatingPoints = queryAllByTestId('rating-points') as HTMLInputElement[]
      expect(totalRatingPoints[0].value).toEqual('20')
      expect(totalRatingPoints[1].value).toEqual('16')
      expect(totalRatingPoints[2].value).toEqual('12')
      expect(totalRatingPoints[3].value).toEqual('8')
    })

    it('should auto-generate points when the max points is changed to be lower than the current max', () => {
      const ratings = [
        {id: '1', description: 'First Rating', points: 10, longDescription: ''},
        {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
        {id: '3', description: 'Third Rating', points: 6, longDescription: ''},
        {id: '4', description: 'Fourth Rating', points: 4, longDescription: ''},
      ]
      const criterion = getCriterion({ratings})
      const {queryAllByTestId} = renderComponent({criterion})

      const maxPointsInput = queryAllByTestId('max-points-input')[0] as HTMLInputElement
      fireEvent.change(maxPointsInput, {target: {value: '8'}})
      fireEvent.blur(maxPointsInput)

      const totalRatingPoints = queryAllByTestId('rating-points') as HTMLInputElement[]
      expect(totalRatingPoints[0].value).toEqual('8')
      expect(totalRatingPoints[1].value).toEqual('6.4')
      expect(totalRatingPoints[2].value).toEqual('4.8')
      expect(totalRatingPoints[3].value).toEqual('3.2')
    })
  })
})

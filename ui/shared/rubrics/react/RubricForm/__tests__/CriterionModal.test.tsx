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

describe('CriterionModal tests', () => {
  const renderComponent = (props?: Partial<CriterionModalProps>) => {
    return render(
      <CriterionModal
        isOpen={true}
        criterionUseRangeEnabled={true}
        onDismiss={() => {}}
        onSave={() => {}}
        hidePoints={false}
        freeFormCriterionComments={false}
        isFullWidth={true}
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

  describe('Hide Points Tests', () => {
    it('does not render points input if hidePoints is true', () => {
      const {queryByTestId, queryAllByTestId} = renderComponent({hidePoints: true})

      expect(queryByTestId('enable-range-checkbox')).toBeNull()
      expect(queryAllByTestId('rating-points')).toHaveLength(0)
      expect(queryAllByTestId('rating-points-assessed')).toHaveLength(0)
    })

    it('does not render points read-only text if hidePoints is true', () => {
      const {queryByTestId, queryAllByTestId} = renderComponent({
        hidePoints: true,
      })

      expect(queryByTestId('enable-range-checkbox')).toBeNull()
      expect(queryAllByTestId('rating-points')).toHaveLength(0)
      expect(queryAllByTestId('rating-points-assessed')).toHaveLength(0)
    })
  })

  describe('Warning Modal Tests', () => {
    it('should show call dismiss if nothing changed', () => {
      const onDismiss = vi.fn()
      const {getByTestId} = renderComponent({
        onDismiss,
        criterion: getCriterion(),
      })

      fireEvent.click(getByTestId('rubric-criterion-cancel'))
      expect(onDismiss).toHaveBeenCalled()
    })

    it('should show warning modal when criterion description has been changed', () => {
      const onDismiss = vi.fn()
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
      const onDismiss = vi.fn()
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
      const onDismiss = vi.fn()
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
      const onDismiss = vi.fn()
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

  describe('Range Tests', () => {
    it('should render correct ranges for criterion use range', () => {
      const criterion = getCriterion({
        criterionUseRange: true,
        ratings: [
          {id: '1', description: 'First Rating', points: 10, longDescription: ''},
          {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
          {id: '2', description: 'Second Rating', points: 5, longDescription: ''},
          {id: '2', description: 'Second Rating', points: 3, longDescription: ''},
        ],
      })

      const {queryAllByTestId} = renderComponent({criterionUseRangeEnabled: true, criterion})

      const rangeStarts = queryAllByTestId('range-start') as HTMLInputElement[]

      expect(rangeStarts).toHaveLength(4)
      expect(rangeStarts[0].textContent).toEqual('8.1 to ')
      expect(rangeStarts[1].textContent).toEqual('5.1 to ')
      expect(rangeStarts[2].textContent).toEqual('3.1 to ')
      expect(rangeStarts[3].textContent).toEqual('--')
    })

    it('should render no range when the ratings of the previous rating are the same as the current rating', () => {
      const criterion = getCriterion({
        criterionUseRange: true,
        ratings: [
          {id: '1', description: 'First Rating', points: 10, longDescription: ''},
          {id: '2', description: 'Second Rating', points: 10, longDescription: ''},
          {id: '3', description: 'Third Rating', points: 8, longDescription: ''},
          {id: '3', description: 'Third Rating', points: 5, longDescription: ''},
        ],
      })

      const {queryAllByTestId} = renderComponent({criterionUseRangeEnabled: true, criterion})

      const rangeStarts = queryAllByTestId('range-start') as HTMLInputElement[]
      expect(rangeStarts).toHaveLength(4)
      expect(rangeStarts[0].textContent).toEqual('--')
      expect(rangeStarts[1].textContent).toEqual('8.1 to ')
      expect(rangeStarts[2].textContent).toEqual('5.1 to ')
      expect(rangeStarts[3].textContent).toEqual('--')
    })
  })
})

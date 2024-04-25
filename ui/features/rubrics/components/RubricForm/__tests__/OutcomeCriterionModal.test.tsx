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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {OutcomeCriterionModal, type OutcomeCriterionModalProps} from '../OutcomeCriterionModal'

describe('OutcomeCriterionModal', () => {
  const onSaveMock = jest.fn()
  const onDismissMock = jest.fn()

  const criterion = {
    id: '1',
    description: 'Sample Description',
    longDescription: '',
    outcome: {
      displayName: 'Sample Outcome Display Name',
      title: 'Sample Outcome Title',
    },
    points: 10,
    criterionUseRange: false,
    ignoreForScoring: false,
    masteryPoints: 8,
    learningOutcomeId: '12345',
    ratings: [
      {id: '1', description: 'First Rating', points: 10, longDescription: ''},
      {id: '2', description: 'Second Rating', points: 8, longDescription: ''},
      {id: '3', description: 'Third Rating', points: 6, longDescription: ''},
      {id: '4', description: 'Fourth Rating', points: 4, longDescription: ''},
    ],
  }

  const renderComponent = (props?: Partial<OutcomeCriterionModalProps>) => {
    return render(
      <OutcomeCriterionModal
        criterion={criterion}
        isOpen={true}
        onSave={onSaveMock}
        onDismiss={onDismissMock}
        {...props}
      />
    )
  }

  it('renders with correct props', () => {
    const {getByText, getByTestId} = renderComponent()

    expect(getByText('Edit Criterion from Outcome')).toBeInTheDocument()
    expect(getByTestId('outcome-rubric-criterion-modal')).toBeInTheDocument()
  })

  it('renders the outcome title, friendly name, and description', () => {
    const {getByTestId} = renderComponent()

    expect(getByTestId('outcome-title').textContent).toEqual(criterion.outcome.title)
    expect(getByTestId('outcome-friendly-name').textContent).toEqual(criterion.outcome.displayName)
    expect(getByTestId('outcome-description').textContent).toEqual(criterion.description)
  })

  it('should reorder ratings when a rating is changed to be higher than the top rating', () => {
    const {queryAllByTestId} = renderComponent()

    const ratingPoints = queryAllByTestId(`rating-points`)[2] as HTMLInputElement

    fireEvent.change(ratingPoints, {target: {value: '20'}})
    fireEvent.blur(ratingPoints)

    const outcomeDescriptions = queryAllByTestId('outcome-rating-description') as HTMLInputElement[]
    expect(outcomeDescriptions[0].textContent).toEqual(criterion.ratings[0].description)
    expect(outcomeDescriptions[1].textContent).toEqual(criterion.ratings[1].description)
    expect(outcomeDescriptions[2].textContent).toEqual(criterion.ratings[2].description)
    expect(outcomeDescriptions[3].textContent).toEqual(criterion.ratings[3].description)

    const totalRatingPoints = queryAllByTestId('rating-points') as HTMLInputElement[]
    expect(totalRatingPoints[0].value).toEqual('20')
    expect(totalRatingPoints[1].value).toEqual('10')
    expect(totalRatingPoints[2].value).toEqual('8')
    expect(totalRatingPoints[3].value).toEqual('4')
  })

  it('should reorder ratings when a rating is changed to be lower than a previous rating', () => {
    const {queryAllByTestId} = renderComponent()

    const ratingPoints = queryAllByTestId(`rating-points`)[0] as HTMLInputElement

    fireEvent.change(ratingPoints, {target: {value: '2'}})
    fireEvent.blur(ratingPoints)

    const outcomeDescriptions = queryAllByTestId('outcome-rating-description') as HTMLInputElement[]
    expect(outcomeDescriptions[0].textContent).toEqual(criterion.ratings[0].description)
    expect(outcomeDescriptions[1].textContent).toEqual(criterion.ratings[1].description)
    expect(outcomeDescriptions[2].textContent).toEqual(criterion.ratings[2].description)
    expect(outcomeDescriptions[3].textContent).toEqual(criterion.ratings[3].description)

    const totalRatingPoints = queryAllByTestId('rating-points') as HTMLInputElement[]
    expect(totalRatingPoints[0].value).toEqual('8')
    expect(totalRatingPoints[1].value).toEqual('6')
    expect(totalRatingPoints[2].value).toEqual('4')
    expect(totalRatingPoints[3].value).toEqual('2')
  })

  it('calls onSave when save button is clicked', async () => {
    const {getByTestId} = renderComponent()

    const saveButton = getByTestId('outcome-rubric-criterion-save')
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(onSaveMock).toHaveBeenCalledTimes(1)
    })
  })

  it('calls onDismiss when cancel button is clicked', () => {
    const {getByTestId} = renderComponent()

    const cancelButton = getByTestId('outcome-rubric-criterion-cancel')
    fireEvent.click(cancelButton)

    expect(onDismissMock).toHaveBeenCalledTimes(1)
  })
})

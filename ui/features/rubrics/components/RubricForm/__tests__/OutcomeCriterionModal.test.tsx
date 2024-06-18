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
import {render} from '@testing-library/react'
import {OutcomeCriterionModal, type OutcomeCriterionModalProps} from '../OutcomeCriterionModal'

describe('OutcomeCriterionModal', () => {
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
        onDismiss={onDismissMock}
        {...props}
      />
    )
  }

  it('renders with correct props', () => {
    const {getByText, getByTestId} = renderComponent()

    expect(getByText('View Outcome')).toBeInTheDocument()
    expect(getByTestId('outcome-rubric-criterion-modal')).toBeInTheDocument()
  })

  it('renders the outcome title, friendly name, and description', () => {
    const {getByTestId} = renderComponent()

    expect(getByTestId('outcome-title').textContent).toEqual(criterion.outcome.title)
    expect(getByTestId('outcome-friendly-name').textContent).toEqual(criterion.outcome.displayName)
    expect(getByTestId('outcome-description').textContent).toEqual(criterion.description)
  })

  it('displays points and description for outcome criteria', () => {
    const {queryAllByTestId} = renderComponent()

    expect(queryAllByTestId('outcome-rating-points')[0].textContent).toEqual(
      criterion.ratings[0].points.toString()
    )
    expect(queryAllByTestId('outcome-rating-points')[1].textContent).toEqual(
      criterion.ratings[1].points.toString()
    )
    expect(queryAllByTestId('outcome-rating-points')[2].textContent).toEqual(
      criterion.ratings[2].points.toString()
    )
    expect(queryAllByTestId('outcome-rating-points')[3].textContent).toEqual(
      criterion.ratings[3].points.toString()
    )

    expect(queryAllByTestId('outcome-rating-description')[0].textContent).toEqual(
      criterion.ratings[0].description
    )
    expect(queryAllByTestId('outcome-rating-description')[1].textContent).toEqual(
      criterion.ratings[1].description
    )
    expect(queryAllByTestId('outcome-rating-description')[2].textContent).toEqual(
      criterion.ratings[2].description
    )
    expect(queryAllByTestId('outcome-rating-description')[3].textContent).toEqual(
      criterion.ratings[3].description
    )
  })
})

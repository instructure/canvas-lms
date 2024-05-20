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
import Router from 'react-router'
import {BrowserRouter} from 'react-router-dom'
import {render, waitFor} from '@testing-library/react'
import {QueryProvider} from '@canvas/query'
import {DuplicateRubricModal} from '../DuplicateRubricModal'
import * as ViewRubricQueries from '../../../queries/ViewRubricQueries'

jest.mock('react-router', () => ({
  ...jest.requireActual('react-router'),
  useParams: jest.fn(),
}))
const onDismiss = jest.fn()
const setPopoverIsOpen = jest.fn()
const duplicateRubricMock = jest.fn()
jest.mock('../../../queries/ViewRubricQueries', () => ({
  ...jest.requireActual('../../../queries/ViewRubricQueries'),
  duplicateRubric: () => duplicateRubricMock,
}))

describe('RubricForm Tests', () => {
  beforeEach(() => {
    jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1', rubricId: '1'})
  })
  afterEach(() => {
    jest.resetAllMocks()
  })

  const renderComponent = (isOpen = true) => {
    return render(
      <QueryProvider>
        <BrowserRouter>
          <DuplicateRubricModal
            id="1"
            title="test rubric"
            isOpen={isOpen}
            onDismiss={onDismiss}
            setPopoverIsOpen={setPopoverIsOpen}
            hidePoints={false}
            accountId="1"
            courseId="1"
            criteria={[
              {
                id: '1',
                points: 5,
                description: 'Criterion 1',
                longDescription: 'Long description for criterion 1',
                ignoreForScoring: false,
                masteryPoints: 3,
                criterionUseRange: false,
                ratings: [
                  {
                    id: '1',
                    description: 'Rating 1',
                    longDescription: 'Long description for rating 1',
                    points: 5,
                  },
                  {
                    id: '2',
                    description: 'Rating 2',
                    longDescription: 'Long description for rating 2',
                    points: 0,
                  },
                ],
              },
              {
                id: '2',
                points: 5,
                description: 'Criterion 2',
                longDescription: 'Long description for criterion 2',
                ignoreForScoring: false,
                masteryPoints: 3,
                criterionUseRange: false,
                ratings: [
                  {
                    id: '3',
                    description: 'Rating 3',
                    longDescription: 'Long description for rating 1',
                    points: 5,
                  },
                  {
                    id: '4',
                    description: 'Rating 4',
                    longDescription: 'Long description for rating 2',
                    points: 0,
                  },
                ],
              },
            ]}
            pointsPossible={10}
            buttonDisplay="description"
            ratingOrder="ascending"
          />
        </BrowserRouter>
      </QueryProvider>
    )
  }

  const getSRAlert = () => document.querySelector('#flash_screenreader_holder')?.textContent

  it('renders the DuplicateRubricModal component', () => {
    const {getByText} = renderComponent()
    expect(getByText('Duplicate test rubric')).toBeInTheDocument()
  })

  it('closes the modal when the close button is clicked', async () => {
    const {getByTestId} = renderComponent()
    const closeButtonContainer = getByTestId('close-duplicate-rubric-modal-button')
    const closeButton = closeButtonContainer.querySelector('button')
    closeButton?.click()
    await waitFor(() => {
      expect(onDismiss).toHaveBeenCalled()
    })
  })

  it('closes the modal when the cancel button is clicked', async () => {
    const {getByTestId} = renderComponent()
    const cancelButton = getByTestId('cancel-duplicate-rubric-modal-button')
    cancelButton?.click()
    await waitFor(() => {
      expect(onDismiss).toHaveBeenCalled()
    })
  })

  it('duplicates the rubric when the duplicate button is clicked', async () => {
    jest
      .spyOn(ViewRubricQueries, 'duplicateRubric')
      .mockImplementation(() => Promise.resolve({id: '1', title: 'Rubric 1', pointsPossible: 10}))
    const {getByTestId} = renderComponent()
    const duplicateButton = getByTestId('duplicate-rubric-button')
    duplicateButton?.click()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(getSRAlert()).toEqual('Rubric duplicated successfully')
  })
})

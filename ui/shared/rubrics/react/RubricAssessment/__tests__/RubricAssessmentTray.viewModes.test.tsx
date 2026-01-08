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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {RubricAssessmentTray, type RubricAssessmentTrayProps} from '../RubricAssessmentTray'
import {RUBRIC_DATA} from './fixtures'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('RubricAssessmentTray View Mode Select Tests', () => {
  beforeEach(() => {
    fakeENV.setup({
      current_user_id: '1',
    })
    queryClient.setQueryData(['_1_eg_rubric_view_mode'], 'traditional')
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  const renderComponent = (props?: Partial<RubricAssessmentTrayProps>) => {
    return render(
      <MockedQueryProvider>
        <RubricAssessmentTray
          currentUserId={'1'}
          isOpen={true}
          isPreviewMode={false}
          rubric={RUBRIC_DATA}
          rubricAssessmentData={[]}
          onDismiss={vi.fn()}
          onSubmit={vi.fn()}
          {...props}
        />
      </MockedQueryProvider>,
    )
  }

  const getModernSelectedDiv = (element: HTMLElement) => {
    return element.querySelector('div[data-testid="rubric-rating-button-selected"]')
  }

  it('should render the traditional view option by default', () => {
    const {getByTestId} = renderComponent()
    const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

    expect(viewModeSelect.value).toBe('Traditional')
    expect(getByTestId('rubric-assessment-traditional-view')).toBeInTheDocument()
    expect(getByTestId('rubric-assessment-header')).toHaveTextContent('Rubric')
    expect(getByTestId('rubric-assessment-footer')).toBeInTheDocument()
  })

  it('should switch to the horizontal view when the horizontal option is selected', async () => {
    const {getByTestId, queryAllByTestId, queryByRole} = renderComponent()
    const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

    fireEvent.click(viewModeSelect)
    const roleOption = queryByRole('option', {name: 'Horizontal'}) as HTMLElement
    fireEvent.click(roleOption)

    await waitFor(() => {
      expect(viewModeSelect.value).toBe('Horizontal')
      expect(queryAllByTestId('rubric-assessment-horizontal-display')).toHaveLength(2)
    })
  })

  it('should switch to the vertical view when the vertical option is selected', async () => {
    const {getByTestId, queryAllByTestId, queryByRole} = renderComponent()
    const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

    fireEvent.click(viewModeSelect)
    const roleOption = queryByRole('option', {name: 'Vertical'}) as HTMLElement
    fireEvent.click(roleOption)

    await waitFor(() => {
      expect(viewModeSelect.value).toBe('Vertical')
      expect(queryAllByTestId('rubric-assessment-vertical-display')).toHaveLength(2)
    })
  })

  it('should keep the selected rating when switching between view modes', async () => {
    const {getByTestId, queryByTestId, queryByRole, queryAllByTestId} = renderComponent()
    const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

    const rating = getByTestId('traditional-criterion-1-ratings-0') as HTMLButtonElement
    fireEvent.click(rating)

    expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
    expect(getByTestId('traditional-criterion-1-ratings-0-selected')).toBeInTheDocument()

    fireEvent.click(viewModeSelect)
    const roleOption = queryByRole('option', {name: 'Horizontal'}) as HTMLElement
    fireEvent.click(roleOption)

    await waitFor(() => {
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(queryAllByTestId('rubric-assessment-horizontal-display')).toHaveLength(2)
      const horizontalRatingDiv = queryByTestId('rating-button-4-0') as HTMLElement
      expect(getModernSelectedDiv(horizontalRatingDiv)).toBeInTheDocument()
    })

    fireEvent.click(viewModeSelect)
    const verticalRoleOption = queryByRole('option', {name: 'Vertical'}) as HTMLElement
    fireEvent.click(verticalRoleOption)

    await waitFor(() => {
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(queryAllByTestId('rubric-assessment-vertical-display')).toHaveLength(2)
      const verticalRatingDiv = queryByTestId('rating-button-4-0') as HTMLElement
      expect(getModernSelectedDiv(verticalRatingDiv)).toBeInTheDocument()
    })
  })
})

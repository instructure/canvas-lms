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
import '@testing-library/jest-dom'
import userEvent from '@testing-library/user-event'
import GradingPeriodSet from '../GradingPeriodSet'
import gradingPeriodsApi from '@canvas/grading/jquery/gradingPeriodsApi'

jest.mock('@canvas/grading/jquery/gradingPeriodsApi')
jest.mock('axios')

describe('GradingPeriodSet', () => {
  let props

  beforeEach(() => {
    props = {
      set: {
        id: '1',
        title: 'Example Set',
        weighted: true,
        displayTotalsForAllGradingPeriods: false,
      },
      terms: [],
      onEdit: jest.fn(),
      onDelete: jest.fn(),
      onPeriodsChange: jest.fn(),
      onToggleBody: jest.fn(),
      gradingPeriods: [
        {
          id: '1',
          title: 'Period 1',
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-03-31'),
          closeDate: new Date('2024-03-31'),
          weight: 30,
        },
      ],
      expanded: true,
      actionsDisabled: false,
      readOnly: false,
      urls: {
        batchUpdateURL: '/api/v1/accounts/1/grading_period_sets',
        deleteGradingPeriodURL: '/api/v1/accounts/1/grading_periods/{{id}}',
        gradingPeriodSetsURL: '/api/v1/accounts/1/grading_period_sets',
      },
      permissions: {
        read: true,
        create: true,
        update: true,
        delete: true,
      },
    }
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const renderComponent = (overrideProps = {}) => {
    const {getByLabelText, getByRole, getByText} = render(
      <GradingPeriodSet {...props} {...overrideProps} />,
    )
    return {getByLabelText, getByRole, getByText}
  }

  describe('Edit Grading Period - validations', () => {
    beforeEach(() => {
      gradingPeriodsApi.batchUpdate.mockRejectedValue(new Error('FAIL'))
    })

    it('prevents saving a grading period without a title', async () => {
      const {getByRole, getByLabelText} = renderComponent()
      const user = userEvent.setup()

      await user.click(getByRole('button', {name: /edit period 1/i}))

      const titleInput = getByLabelText(/title/i)
      await user.clear(titleInput)

      await user.click(getByRole('button', {name: /save/i}))

      expect(gradingPeriodsApi.batchUpdate).not.toHaveBeenCalled()
      expect(getByLabelText(/title/i)).toBeInTheDocument()
    })

    it('prevents saving a grading period with only spaces as title', async () => {
      const {getByRole, getByLabelText} = renderComponent()
      const user = userEvent.setup()

      await user.click(getByRole('button', {name: /edit period 1/i}))

      const titleInput = getByLabelText(/title/i)
      await user.clear(titleInput)
      await user.type(titleInput, '    ')

      await user.click(getByRole('button', {name: /save/i}))

      expect(gradingPeriodsApi.batchUpdate).not.toHaveBeenCalled()
      expect(getByLabelText(/title/i)).toBeInTheDocument()
    })

    it('prevents saving a grading period with a negative weight', async () => {
      const {getByRole, getByLabelText} = renderComponent()
      const user = userEvent.setup()

      await user.click(getByRole('button', {name: /edit period 1/i}))

      const weightInput = getByLabelText(/weight/i)
      await user.clear(weightInput)
      await user.type(weightInput, '-50')

      await user.click(getByRole('button', {name: /save/i}))

      expect(gradingPeriodsApi.batchUpdate).not.toHaveBeenCalled()
      expect(getByLabelText(/weight/i)).toBeInTheDocument()
    })

    it('prevents saving a grading period without a valid startDate', async () => {
      const {getByRole, getByLabelText} = renderComponent()
      const user = userEvent.setup()

      await user.click(getByRole('button', {name: /edit period 1/i}))

      const startDateInput = getByLabelText(/start date/i)
      await user.clear(startDateInput)

      await user.click(getByRole('button', {name: /save/i}))

      expect(gradingPeriodsApi.batchUpdate).not.toHaveBeenCalled()
      expect(getByLabelText(/start date/i)).toBeInTheDocument()
    })

    it('prevents saving a grading period without a valid endDate', async () => {
      const {getByRole, getByLabelText} = renderComponent()
      const user = userEvent.setup()

      await user.click(getByRole('button', {name: /edit period 1/i}))

      const endDateInput = getByLabelText(/end date/i)
      await user.clear(endDateInput)

      await user.click(getByRole('button', {name: /save/i}))

      expect(gradingPeriodsApi.batchUpdate).not.toHaveBeenCalled()
      expect(getByLabelText(/end date/i)).toBeInTheDocument()
    })

    it('prevents saving a grading period without a valid closeDate', async () => {
      const {getByRole, getByLabelText} = renderComponent()
      const user = userEvent.setup()

      await user.click(getByRole('button', {name: /edit period 1/i}))

      const closeDateInput = getByLabelText(/close date/i)
      await user.clear(closeDateInput)

      await user.click(getByRole('button', {name: /save/i}))

      expect(gradingPeriodsApi.batchUpdate).not.toHaveBeenCalled()
      expect(getByLabelText(/close date/i)).toBeInTheDocument()
    })
  })
})

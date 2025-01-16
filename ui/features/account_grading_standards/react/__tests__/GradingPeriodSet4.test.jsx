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
import {render, screen, waitFor} from '@testing-library/react'
import '@testing-library/jest-dom'
import userEvent from '@testing-library/user-event'
import GradingPeriodSet from '../GradingPeriodSet'
import gradingPeriodsApi from '@canvas/grading/jquery/gradingPeriodsApi'
import axios from '@canvas/axios'

jest.mock('@canvas/grading/jquery/gradingPeriodsApi')
jest.mock('@canvas/axios')

// Mock jQuery functions
const $ = {
  flashMessage: jest.fn(),
  flashError: jest.fn(),
}
global.$ = $

describe('GradingPeriodSet - Form Validation and Accessibility', () => {
  let props
  let windowConfirmMock

  beforeEach(() => {
    windowConfirmMock = jest.spyOn(window, 'confirm').mockImplementation(() => true)
    gradingPeriodsApi.batchUpdate = jest.fn().mockResolvedValue([])
    axios.delete = jest.fn().mockResolvedValue({})
    $.flashMessage.mockReset()
    $.flashError.mockReset()

    // Clean up any existing flash message containers
    document.querySelectorAll('#flash_message_holder').forEach(el => el.remove())

    // Create a div for flash messages
    const flashMessageContainer = document.createElement('div')
    flashMessageContainer.setAttribute('role', 'alert')
    flashMessageContainer.setAttribute('aria-live', 'polite')
    flashMessageContainer.setAttribute('id', 'flash_message_holder')
    document.body.appendChild(flashMessageContainer)

    // Mock $.flashError to actually display messages
    $.flashError.mockImplementation(message => {
      const alertDiv = document.createElement('div')
      alertDiv.setAttribute('role', 'alert')
      alertDiv.setAttribute('aria-live', 'polite')
      alertDiv.textContent = message
      flashMessageContainer.appendChild(alertDiv)
    })

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
        },
      ],
      permissions: {
        read: true,
        create: true,
        update: true,
        delete: true,
      },
      readOnly: false,
      expanded: true,
      urls: {
        batchUpdateURL: '/api/v1/grading_period_sets/1/grading_periods/batch_update',
        deleteGradingPeriodURL: '/api/v1/grading_period_sets/1/grading_periods',
        gradingPeriodSetsURL: '/api/v1/grading_period_sets',
      },
    }
  })

  afterEach(() => {
    windowConfirmMock.mockRestore()
    $.flashMessage.mockReset()
    $.flashError.mockReset()
  })

  const renderComponent = (overrideProps = {}) => {
    const renderResult = render(<GradingPeriodSet {...props} {...overrideProps} />)
    return {
      ...renderResult,
      addPeriodButton: () => screen.getByRole('button', {name: /add grading period/i}),
      saveButton: () => screen.getByRole('button', {name: /save/i}),
      titleInput: () => screen.getByLabelText(/grading period title/i),
      startDateInput: () => screen.getByLabelText(/start date/i),
      endDateInput: () => screen.getByLabelText(/end date/i),
      weightInput: () => screen.getByLabelText(/grading period weight/i),
      deleteButton: periodId =>
        screen.getByRole('button', {name: new RegExp(`delete period ${periodId}`, 'i')}),
      periodList: () => screen.getByRole('list', {name: /grading periods/i}),
      editButton: periodId =>
        screen.getByRole('button', {name: new RegExp(`edit period ${periodId}`, 'i')}),
      toggleButton: () => screen.getByRole('button', {name: /toggle.*grading period visibility/i}),
    }
  }

  describe('Accessibility', () => {
    it('maintains focus management when navigating forms', async () => {
      const user = userEvent.setup()
      const {addPeriodButton, titleInput} = renderComponent()

      await user.click(addPeriodButton())

      // Verify focus moves to title input when form opens
      await waitFor(() => {
        expect(titleInput()).toHaveFocus()
      })
    })

    it('uses semantic HTML for form structure', async () => {
      const {addPeriodButton} = renderComponent()

      // Verify form uses proper HTML5 elements
      expect(screen.getByRole('button', {name: /add grading period/i})).toBeInTheDocument()
      expect(screen.getByRole('heading', {name: /example set/i})).toBeInTheDocument()
    })

    it('provides descriptive labels for all form fields', async () => {
      const user = userEvent.setup()
      const {addPeriodButton} = renderComponent()

      await user.click(addPeriodButton())

      // Verify all form fields have proper labels
      expect(screen.getByLabelText(/grading period title/i)).toBeInTheDocument()
      expect(screen.getByLabelText(/start date/i)).toBeInTheDocument()
      expect(screen.getByLabelText(/end date/i)).toBeInTheDocument()
      expect(screen.getByLabelText(/close date/i)).toBeInTheDocument()
    })
  })
})

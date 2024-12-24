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

import $ from 'jquery'
import React from 'react'
import {render, screen} from '@testing-library/react'
import '@testing-library/jest-dom'
import userEvent from '@testing-library/user-event'
import GradingPeriodSet from '../GradingPeriodSet'
import gradingPeriodsApi from '@canvas/grading/jquery/gradingPeriodsApi'
import axios from '@canvas/axios'

jest.mock('@canvas/grading/jquery/gradingPeriodsApi')
jest.mock('@canvas/axios')

describe('GradingPeriodSet', () => {
  let props
  let windowConfirmMock
  let flashMessageMock
  let flashErrorMock

  beforeEach(() => {
    windowConfirmMock = jest.spyOn(window, 'confirm').mockImplementation(() => true)
    flashMessageMock = jest.spyOn($, 'flashMessage').mockImplementation(() => {})
    flashErrorMock = jest.spyOn($, 'flashError').mockImplementation(() => {})
    gradingPeriodsApi.batchUpdate = jest.fn().mockResolvedValue([])
    axios.delete = jest.fn().mockResolvedValue({})

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
    flashMessageMock.mockRestore()
    flashErrorMock.mockRestore()
  })

  const renderComponent = (overrideProps = {}) => {
    const renderResult = render(<GradingPeriodSet {...props} {...overrideProps} />)
    return {
      ...renderResult,
      addPeriodButton: () => renderResult.getByRole('button', {name: /add grading period/i}),
      periodForm: () => renderResult.getByRole('form'),
      deleteButton: periodId =>
        renderResult.getByRole('button', {name: new RegExp(`delete period ${periodId}`, 'i')}),
      periodList: () => renderResult.getByRole('list', {name: /grading periods/i}),
      editButton: periodId =>
        renderResult.getByRole('button', {name: new RegExp(`edit period ${periodId}`, 'i')}),
    }
  }

  describe('Grading Period Set Management', () => {
    describe('when adding a new grading period', () => {
      it('hides form when cancel button is clicked', async () => {
        const user = userEvent.setup()
        const {addPeriodButton} = renderComponent()

        await user.click(addPeriodButton())
        await user.click(screen.getByRole('button', {name: /cancel/i}))
        expect(screen.queryByRole('form')).not.toBeInTheDocument()
      })
    })

    describe('when removing a grading period', () => {
      it('prompts for confirmation before deleting', async () => {
        const user = userEvent.setup()
        const {deleteButton} = renderComponent()

        await user.click(deleteButton('1'))
        expect(windowConfirmMock).toHaveBeenCalled()
      })

      it('does not call onDelete when canceled', async () => {
        windowConfirmMock.mockImplementationOnce(() => false)
        const user = userEvent.setup()
        const {deleteButton} = renderComponent()

        await user.click(deleteButton('1'))
        expect(props.onDelete).not.toHaveBeenCalled()
      })
    })

    describe('set expansion', () => {
      it('toggles set body when header is clicked', async () => {
        const user = userEvent.setup()
        const {getByRole} = renderComponent()

        await user.click(getByRole('button', {name: /toggle.*grading period visibility/i}))
        expect(props.onToggleBody).toHaveBeenCalled()
      })
    })

    describe('permissions and readonly mode', () => {
      it('hides add button when create permission is false', () => {
        const {queryByRole} = renderComponent({
          permissions: {...props.permissions, create: false},
        })
        expect(queryByRole('button', {name: /add grading period/i})).not.toBeInTheDocument()
      })

      it('hides edit button when update permission is false', () => {
        const {queryByRole} = renderComponent({
          permissions: {...props.permissions, update: false},
        })
        expect(queryByRole('button', {name: /edit period/i})).not.toBeInTheDocument()
      })

      it('hides delete button when delete permission is false', () => {
        const {queryByRole} = renderComponent({
          permissions: {...props.permissions, delete: false},
        })
        expect(queryByRole('button', {name: /delete period/i})).not.toBeInTheDocument()
      })

      it('disables all actions in readonly mode', () => {
        const {queryByRole} = renderComponent({readOnly: true})
        expect(queryByRole('button', {name: /add grading period/i})).not.toBeInTheDocument()
        expect(queryByRole('button', {name: /edit period/i})).not.toBeInTheDocument()
        expect(queryByRole('button', {name: /delete period/i})).not.toBeInTheDocument()
      })
    })
  })
})

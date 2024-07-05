/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import { render, fireEvent, screen } from '@testing-library/react'
import axios from '@canvas/axios'
import GradingPeriod from '../AccountGradingPeriod'
import DateHelper from '@canvas/datetime/dateHelper'

jest.mock('@canvas/datetime/dateHelper', () => ({
  formatDateForDisplay: jest.fn(date => {
    const options = { year: 'numeric', month: '2-digit', day: '2-digit' };
    return date.toLocaleDateString('en-US', options);
  })
}))

const allPermissions = {read: true, create: true, update: true, delete: true}
const noPermissions = {read: false, create: false, update: false, delete: false}

const defaultProps = {
  period: {
    id: '1',
    title: 'We did it! We did it! We did it! #dora #boots',
    weight: 30,
    startDate: new Date('2015-01-01T20:11:00+00:00'),
    endDate: new Date('2015-03-01T00:00:00+00:00'),
    closeDate: new Date('2015-03-08T00:00:00+00:00'),
  },
  weighted: true,
  readOnly: false,
  onEdit: jest.fn(),
  permissions: allPermissions,
  deleteGradingPeriodURL: 'api/v1/accounts/1/grading_periods/%7B%7B%20id%20%7D%7D',
  onDelete: jest.fn(),
}

describe('AccountGradingPeriod', () => {
  const renderComponent = (props = {}) => {
    return render(<GradingPeriod {...defaultProps} {...props} />)
  }

  it('shows the "edit grading period" button when "update" is permitted', () => {
    renderComponent()
    expect(screen.getByTitle(/Edit/)).toBeInTheDocument()
  })

  it('does not show the "edit grading period" button when "update" is not permitted', () => {
    renderComponent({permissions: noPermissions})
    expect(screen.queryByTitle(/Edit/)).not.toBeInTheDocument()
  })

  it('does not show the "edit grading period" button when "read only"', () => {
    renderComponent({permissions: allPermissions, readOnly: true})
    expect(screen.queryByTitle(/Edit/)).not.toBeInTheDocument()
  })

  it('disables the "edit grading period" button when "actionsDisabled" is true', () => {
    renderComponent({actionsDisabled: true})
    expect(screen.getByTitle(/Edit/)).toBeDisabled()
  })

  it('disables the "delete grading period" button when "actionsDisabled" is true', () => {
    renderComponent({actionsDisabled: true})
    expect(screen.getByTitle(/Delete/)).toBeDisabled()
  })

  it('displays the start date in a friendly format', () => {
    renderComponent()
    expect(screen.getByText(/Starts:/)).toBeInTheDocument()
    expect(DateHelper.formatDateForDisplay).toHaveBeenCalledWith(defaultProps.period.startDate)
  })

  it('displays the end date in a friendly format', () => {
    renderComponent()
    expect(screen.getByText(/Ends:/)).toBeInTheDocument()
    expect(DateHelper.formatDateForDisplay).toHaveBeenCalledWith(defaultProps.period.endDate)
  })

  it('displays the close date in a friendly format', () => {
    renderComponent()
    expect(screen.getByText(/Closes:/)).toBeInTheDocument()
    expect(DateHelper.formatDateForDisplay).toHaveBeenCalledWith(defaultProps.period.closeDate)
  })

  it('displays the weight in a friendly format', () => {
    renderComponent()
    expect(screen.getByText(/Weight: 30%/)).toBeInTheDocument()
  })

  it('does not display the weight if weighted grading periods are turned off', () => {
    renderComponent({weighted: false})
    expect(screen.queryByText(/Weight:/)).not.toBeInTheDocument()
  })

  it('calls the "onEdit" callback when the edit button is clicked', () => {
    renderComponent()
    fireEvent.click(screen.getByTitle(/Edit/))
    expect(defaultProps.onEdit).toHaveBeenCalledWith(defaultProps.period)
  })

  it('displays the delete button if the user has proper rights', () => {
    renderComponent()
    expect(screen.getByTitle(/Delete/)).toBeInTheDocument()
  })

  it('does not display the delete button if readOnly is true', () => {
    renderComponent({readOnly: true})
    expect(screen.queryByTitle(/Delete/)).not.toBeInTheDocument()
  })

  it('does not display the delete button if the user does not have delete permissions', () => {
    renderComponent({permissions: noPermissions})
    expect(screen.queryByTitle(/Delete/)).not.toBeInTheDocument()
  })

  it('does not delete the period if the user cancels the delete confirmation', () => {
    window.confirm = jest.fn(() => false)
    renderComponent()
    fireEvent.click(screen.getByTitle(/Delete/))
    expect(defaultProps.onDelete).not.toHaveBeenCalled()
  })

  it('calls onDelete if the user confirms deletion and the axios call succeeds', async () => {
    window.confirm = jest.fn(() => true)
    const flashMessageMock = jest.fn()
    $.flashMessage = flashMessageMock
    const axiosDeleteMock = jest.spyOn(axios, 'delete').mockResolvedValue({})

    renderComponent()
    fireEvent.click(screen.getByTitle(/Delete/))

    // Wait for any promises to resolve
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(axiosDeleteMock).toHaveBeenCalled()
    expect(defaultProps.onDelete).toHaveBeenCalledWith(defaultProps.period.id)
    expect(flashMessageMock).toHaveBeenCalled()

    axiosDeleteMock.mockRestore()
  })
})
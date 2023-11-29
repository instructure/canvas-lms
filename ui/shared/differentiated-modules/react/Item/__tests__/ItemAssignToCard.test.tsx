/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import ItemAssignToCard, {type ItemAssignToCardProps} from '../ItemAssignToCard'

const props: ItemAssignToCardProps = {
  courseId: '1',
  disabledOptionIds: [],
  selectedAssigneeIds: [],
  onCardAssignmentChange: () => {},
  cardId: 'assign-to-card-001',
  due_at: null,
  unlock_at: null,
  lock_at: null,
  onDelete: undefined,
  onValidityChange: () => {},
}

const renderComponent = (overrides: Partial<ItemAssignToCardProps> = {}) =>
  render(<ItemAssignToCard {...props} {...overrides} />)

describe('ItemAssignToCard', () => {
  it('renders', () => {
    const {getByLabelText, getAllByLabelText, getByTestId, queryByRole} = renderComponent()
    expect(getByTestId('item-assign-to-card')).toBeInTheDocument()
    expect(queryByRole('button', {name: 'Delete'})).not.toBeInTheDocument()
    expect(getByLabelText('Due Date')).toBeInTheDocument()
    expect(getAllByLabelText('Time').length).toBe(3)
    expect(getByLabelText('Available from')).toBeInTheDocument()
    expect(getByLabelText('Until')).toBeInTheDocument()
  })

  it('renders with the given dates', () => {
    const due_at = '2023-10-05T12:00:00Z'
    const unlock_at = '2023-10-03T12:00:00Z'
    const lock_at = '2023-10-10T12:00:00Z'
    const {getByLabelText} = renderComponent({due_at, unlock_at, lock_at})
    expect(getByLabelText('Due Date')).toHaveValue('Oct 5, 2023')
    expect(getByLabelText('Available from')).toHaveValue('Oct 3, 2023')
    expect(getByLabelText('Until')).toHaveValue('Oct 10, 2023')
  })

  it('renders the delete button when onDelete is provided', () => {
    const onDelete = jest.fn()
    const {getByRole} = renderComponent({onDelete})
    expect(getByRole('button', {name: 'Delete'})).toBeInTheDocument()
  })

  it('calls onDelete when delete button is clicked', () => {
    const onDelete = jest.fn()
    const {getByRole} = renderComponent({onDelete})
    getByRole('button', {name: 'Delete'}).click()
    expect(onDelete).toHaveBeenCalledWith('assign-to-card-001')
  })

  it('defaults to 11:59pm for due dates if has null due time', () => {
    window.ENV.DEFAULT_DUE_TIME = undefined
    const {getByLabelText, getByRole, getAllByText} = renderComponent()
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByText('Tuesday, November 10, 2020 11:59 PM').length).toBeGreaterThanOrEqual(1)
  })

  it('defaults to 11:59pm for due dates if has undefined due time', () => {
    window.ENV.DEFAULT_DUE_TIME = undefined
    const {getByLabelText, getByRole, getAllByText} = renderComponent({due_at: undefined})
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByText('Tuesday, November 10, 2020 11:59 PM').length).toBeGreaterThanOrEqual(1)
  })

  it('defaults to the default due time for due dates from ENV if has null due time', () => {
    window.ENV.DEFAULT_DUE_TIME = '08:00:00'
    const {getByLabelText, getByRole, getAllByText} = renderComponent()
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByText('Tuesday, November 10, 2020 8:00 AM').length).toBeGreaterThanOrEqual(1)
  })

  it('defaults to the default due time for due dates from ENV if has undefined due time', () => {
    window.ENV.DEFAULT_DUE_TIME = '08:00:00'
    const {getByLabelText, getByRole, getAllByText} = renderComponent({due_at: undefined})
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByText('Tuesday, November 10, 2020 8:00 AM').length).toBeGreaterThanOrEqual(1)
  })

  it('defaults to midnight for available from dates if it is null', () => {
    const {getByLabelText, getByRole, getAllByText} = renderComponent()
    const dateInput = getByLabelText('Available from')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByText('Tuesday, November 10, 2020 12:00 AM').length).toBeGreaterThanOrEqual(1)
  })

  it('defaults to midnight for available from dates if it is undefined', () => {
    const {getByLabelText, getByRole, getAllByText} = renderComponent({unlock_at: undefined})
    const dateInput = getByLabelText('Available from')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByText('Tuesday, November 10, 2020 12:00 AM').length).toBeGreaterThanOrEqual(1)
  })

  it('defaults to 11:59 PM for available until dates if it is null', () => {
    const {getByLabelText, getByRole, getAllByText} = renderComponent()
    const dateInput = getByLabelText('Until')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByText('Tuesday, November 10, 2020 11:59 PM').length).toBeGreaterThanOrEqual(1)
  })

  it('defaults to 11:59 PM for available until dates if it is undefined', () => {
    const {getByLabelText, getByRole, getAllByText} = renderComponent({lock_at: undefined})
    const dateInput = getByLabelText('Until')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByText('Tuesday, November 10, 2020 11:59 PM').length).toBeGreaterThanOrEqual(1)
  })
})

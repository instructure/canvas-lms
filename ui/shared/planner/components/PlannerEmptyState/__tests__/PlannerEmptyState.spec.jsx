/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import PlannerEmptyState from '../index'

function defaultProps(opts = {}) {
  return {
    changeDashboardView: () => {},
    onAddToDo: () => {},
    isCompletelyEmpty: true,
    isWeekly: false,
    ...opts,
  }
}

it('renders desert when completely empty', () => {
  const {container, getByText} = render(<PlannerEmptyState {...defaultProps()} />)
  expect(container.querySelector('.desert')).toBeInTheDocument()
  expect(container.querySelector('.balloons')).not.toBeInTheDocument()
  expect(getByText('No Due Dates Assigned')).toBeInTheDocument()
  expect(getByText("Looks like there isn't anything here")).toBeInTheDocument()
  expect(getByText('Go to Card View Dashboard')).toBeInTheDocument()
  expect(getByText('Add To-Do')).toBeInTheDocument()
})

it('renders balloons when not completely empty', () => {
  const {container, getByText} = render(
    <PlannerEmptyState {...defaultProps({isCompletelyEmpty: false})} />,
  )
  expect(container.querySelector('.balloons')).toBeInTheDocument()
  expect(container.querySelector('.desert')).not.toBeInTheDocument()
  expect(getByText('Nothing More To Do')).toBeInTheDocument()
  expect(getByText('Add To-Do')).toBeInTheDocument()
})

it('renders balloons and different text when weekly', () => {
  const {container, getByText, queryByText} = render(
    <PlannerEmptyState {...defaultProps({isCompletelyEmpty: false, isWeekly: true})} />,
  )
  expect(container.querySelector('.balloons')).toBeInTheDocument()
  expect(container.querySelector('.desert')).not.toBeInTheDocument()
  expect(getByText('Nothing Due This Week')).toBeInTheDocument()
  expect(queryByText('Add To-Do')).not.toBeInTheDocument()
})

it('does not changeDashboardView on mount', () => {
  const changeDashboardView = jest.fn()
  render(<PlannerEmptyState {...defaultProps({changeDashboardView})} />)
  expect(changeDashboardView).not.toHaveBeenCalled()
})

it('calls changeDashboardView on link click', async () => {
  const user = userEvent.setup()
  const changeDashboardView = jest.fn()
  const {getByText} = render(
    <PlannerEmptyState {...defaultProps({changeDashboardView, isCompletelyEmpty: true})} />,
  )
  const button = getByText('Go to Card View Dashboard')
  await user.click(button)
  expect(changeDashboardView).toHaveBeenCalledWith('cards')
})

it('does not call changeDashboardView on false prop', async () => {
  const user = userEvent.setup()
  const {getByText} = render(<PlannerEmptyState {...defaultProps({isCompletelyEmpty: true})} />)
  const button = getByText('Go to Card View Dashboard')
  await expect(async () => {
    await user.click(button)
  }).not.toThrow()
})

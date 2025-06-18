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
import moment from 'moment-timezone'
import {ToDoSidebar} from '../index'

const defaultProps = {
  sidebarLoadInitialItems: () => {},
  sidebarCompleteItem: () => {},
  loaded: true,
  items: [],
  courses: [],
  changeDashboardView: () => {},
}

it('displays a spinner when the loaded prop is false', () => {
  const {getByText} = render(<ToDoSidebar {...defaultProps} loaded={false} />)
  expect(getByText('To Do Items Loading')).toBeInTheDocument()
})

it('calls loadItems prop on mount', () => {
  const fakeLoadItems = jest.fn()
  render(<ToDoSidebar {...defaultProps} sidebarLoadInitialItems={fakeLoadItems} />)
  expect(fakeLoadItems).toHaveBeenCalled()
})

it('includes course_id in call loadItems prop on mount', () => {
  const fakeLoadItems = jest.fn()
  const course_id = '17'
  render(
    <ToDoSidebar {...defaultProps} sidebarLoadInitialItems={fakeLoadItems} forCourse={course_id} />,
  )
  expect(fakeLoadItems).toHaveBeenCalled()
  expect(fakeLoadItems.mock.calls[0][1]).toEqual(course_id)
})

it('renders out ToDoItems for each item', () => {
  const items = [
    {
      uniqueId: '1',
      type: 'Assignment',
      date: moment('2017-07-15T20:00:00Z'),
      title: 'Glory to Rome',
    },
    {
      uniqueId: '2',
      type: 'Quiz',
      date: moment('2017-07-15T20:00:00Z'),
      title: 'Glory to Rome',
    },
  ]
  const {container, getAllByText} = render(<ToDoSidebar {...defaultProps} items={items} />)
  expect(container.querySelectorAll('.ToDoSidebarItem')).toHaveLength(items.length)
  expect(getAllByText(items[0].title).length).toBeGreaterThan(0)
  expect(getAllByText(items[1].title).length).toBeGreaterThan(0)
})

it('initially renders out 7 ToDoItems', () => {
  const items = [
    {
      uniqueId: '1',
      type: 'Assignment',
      date: moment('2017-07-15T20:00:00Z'),
      title: 'Glory to Rome',
    },
    {
      uniqueId: '2',
      type: 'Quiz',
      date: moment('2017-07-16T20:00:00Z'),
      title: 'Glory to Orange County',
    },
    {
      uniqueId: '3',
      type: 'Assignment',
      date: moment('2017-07-17T20:00:00Z'),
      title: 'Glory to China',
    },
    {
      uniqueId: '4',
      type: 'Quiz',
      date: moment('2017-07-18T20:00:00Z'),
      title: 'Glory to Egypt',
    },
    {
      uniqueId: '5',
      type: 'Assignment',
      date: moment('2017-07-19T20:00:00Z'),
      title: 'Glory to Sacramento',
    },
    {
      uniqueId: '6',
      type: 'Quiz',
      date: moment('2017-07-20T20:00:00Z'),
      title: 'Glory to Atlantis',
    },
    {
      uniqueId: '7',
      type: 'Quiz',
      date: moment('2017-07-21T20:00:00Z'),
      title: 'Glory to Hoboville',
    },
    {
      uniqueId: '8',
      type: 'Quiz',
      date: moment('2017-07-22T20:00:00Z'),
      title: 'Glory to Big Cottonwood Canyon',
    },
    {
      uniqueId: '9',
      type: 'Quiz',
      date: moment('2017-07-23T20:00:00Z'),
      title: 'Glory to Small Cottonwood Canyon',
    },
  ]

  const {container} = render(<ToDoSidebar {...defaultProps} items={items} />)
  expect(container.querySelectorAll('.ToDoSidebarItem')).toHaveLength(7)
})

it('invokes change dashboard view when link is clicked', async () => {
  const changeDashboardView = jest.fn()
  // becasue the show all button is only rendered if there are items
  const items = [
    {
      uniqueId: '1',
      type: 'Assignment',
      date: moment('2017-07-15T20:00:00Z'),
      title: 'Glory to Rome',
    },
  ]
  const {getByText} = render(
    <ToDoSidebar {...defaultProps} items={items} changeDashboardView={changeDashboardView} />,
  )
  const link = getByText('Show All')
  await userEvent.click(link)

  expect(changeDashboardView).toHaveBeenCalledWith('planner')
})

it('does not render out items that are completed', () => {
  const items = [
    {
      uniqueId: '1',
      plannable_type: 'assignment',
      date: moment('2017-07-15T20:00:00Z'),
      completed: true,
      title: 'Glory to Rome',
    },
    {
      uniqueId: '2',
      plannable_type: 'quiz',
      date: moment('2017-07-15T20:00:00Z'),
      completed: true,
      title: 'Glory to Rome',
    },
  ]
  const wrapper = render(<ToDoSidebar {...defaultProps} items={items} />)
  expect(wrapper.container.querySelectorAll('.ToDoSidebarItem')).toHaveLength(0)
})

it('can handles no items', () => {
  // suppress Show All button and display "Nothing for now" instead of list
  const {getByTestId, getByText, queryByText} = render(
    <ToDoSidebar {...defaultProps} changeDashboardView={null} />,
  )

  // Should render the ToDoSidebar container
  expect(getByTestId('ToDoSidebar')).toBeInTheDocument()

  // Should render the To Do header
  expect(getByText('To Do')).toBeInTheDocument()

  // Should display "Nothing for now" when there are no items
  expect(getByText('Nothing for now')).toBeInTheDocument()

  // Should not display "Show All" button when changeDashboardView is null
  expect(queryByText('Show All')).not.toBeInTheDocument()
})

it('renders an error message when loading fails', () => {
  const error = 'Request failed with status code 404'
  const {getByText} = render(<ToDoSidebar {...defaultProps} loadingError={error} />)

  expect(getByText('Failure loading the To Do list')).toBeInTheDocument()
})

it('renders additional context title', () => {
  const {getByText} = render(<ToDoSidebar {...defaultProps} additionalTitleContext={true} />)

  expect(getByText('Student To Do')).toBeInTheDocument()
})

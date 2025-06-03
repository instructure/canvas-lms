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
import {fireEvent, render, waitFor} from '@testing-library/react'
import moment from 'moment-timezone'
import ToDoItem from '../ToDoItem'

const getDefaultProps = overrides => ({
  handleDismissClick() {},
  item: {
    type: overrides?.type || 'Assignment',
    title: 'Introduction to Board Games',
    course_id: null,
    date: moment('2017-07-15T20:00:00-0600'),
    ...overrides,
  },
  courses: [
    {
      id: '1',
      shortName: 'BGG 101',
    },
    {
      id: '2',
      shortName: 'BGG 201',
    },
  ],
})

it('renders assignment icon for assignments', () => {
  const {container} = render(<ToDoItem {...getDefaultProps({type: 'Assignment'})} />)
  expect(container.querySelector('svg[name="IconAssignment"]')).toBeInTheDocument()
})

it('renders quiz icon for quizzes', () => {
  const {container} = render(<ToDoItem {...getDefaultProps({type: 'Quiz'})} />)
  expect(container.querySelector('svg[name="IconQuiz"]')).toBeInTheDocument()
})

it('renders discussion icon for discussions', () => {
  const {container} = render(<ToDoItem {...getDefaultProps({type: 'Discussion'})} />)
  expect(container.querySelector('svg[name="IconDiscussion"]')).toBeInTheDocument()
})

it('renders discussion icon for discussion checkpoints', () => {
  const {container} = render(<ToDoItem {...getDefaultProps({type: 'Discussion Checkpoint'})} />)
  expect(container.querySelector('svg[name="IconDiscussion"]')).toBeInTheDocument()
})

it('renders announcement icon for announcements', () => {
  const {container} = render(<ToDoItem {...getDefaultProps({type: 'Announcement'})} />)
  expect(container.querySelector('svg[name="IconAnnouncement"]')).toBeInTheDocument()
})

it('renders calendar icon for calendar events', () => {
  const {container} = render(<ToDoItem {...getDefaultProps({type: 'Calendar Event'})} />)
  expect(container.querySelector('svg[name="IconCalendarMonth"]')).toBeInTheDocument()
})

it('renders page icon for pages', () => {
  const {container} = render(<ToDoItem {...getDefaultProps({type: 'Page'})} />)
  expect(container.querySelector('svg[name="IconDocument"]')).toBeInTheDocument()
})

it('renders peer review icon and title for peer reviews', () => {
  const {container, getByText} = render(<ToDoItem {...getDefaultProps({type: 'Peer Review'})} />)
  expect(container.querySelector('svg[name="IconPeerReview"]')).toBeInTheDocument()
  expect(getByText(/Peer Review for/)).toBeInTheDocument()
})

it('renders note icon for planner_notes', () => {
  const {container} = render(<ToDoItem {...getDefaultProps({type: ''})} />)
  expect(container.querySelector('svg[name="IconNote"]')).toBeInTheDocument()
})

it('renders the courses short name when the item has an associated course', () => {
  const wrapper = render(<ToDoItem {...getDefaultProps({course_id: '1'})} />)
  expect(wrapper.getByText('BGG 101')).toBeInTheDocument()
})

it('renders out points if the item has points', () => {
  const wrapper = render(<ToDoItem {...getDefaultProps({course_id: '1', points: 50})} />)
  expect(wrapper.getByText('50 points')).toBeInTheDocument()
})

// TODO: need to unskip this test when we figure out how to use canvas's locale formats
it.skip('renders out the due date in the proper format', () => {
  const wrapper = render(<ToDoItem {...getDefaultProps()} />)
  const info = wrapper.getByTestId('todo-sidebar-item-info')
  // The due date in was '2017-07-15T20:00:00-0600'
  // since this test is not running in canvas,
  // the user's profile TZ will default to UTC
  // and the output will be 6 hours later
  expect(info.text()).toMatch('Jul 16 at  2:00am')
})

it('renders the title as an a tag when given an href prop', () => {
  const wrapper = render(<ToDoItem {...getDefaultProps({html_url: '/some_example_url'})} />)
  expect(wrapper.getByText('Introduction to Board Games')).toBeInTheDocument()
})

it('renders out the title as a Text when not given an href prop', () => {
  const wrapper = render(<ToDoItem {...getDefaultProps()} />)
  expect(wrapper.getByText('Introduction to Board Games')).toBeInTheDocument()
})

it('renders unique text for dismiss button', () => {
  const wrapper = render(<ToDoItem {...getDefaultProps()} />)
  expect(wrapper.getByText('Dismiss Introduction to Board Games')).toBeInTheDocument()
})

it('calls the handleDismissClick prop when the dismiss X is clicked', () => {
  const handleDismissClick = jest.fn()
  const item = {
    type: 'Assignment',
    title: 'Introduction to Board Games',
    course_id: null,
    date: moment('2017-07-15T20:00:00-0600'),
  }
  const wrapper = render(
    <ToDoItem
      handleDismissClick={handleDismissClick}
      item={item}
      courses={[
        {id: '1', shortName: 'BGG 101'},
        {id: '2', shortName: 'BGG 201'},
      ]}
    />,
  )
  const btn = wrapper.getByRole('button', {name: /Dismiss Introduction to Board Games/i})
  fireEvent.click(btn)
  expect(handleDismissClick).toHaveBeenCalledWith(item)
})

it('does not render the dismiss button when isObserving', () => {
  const wrapper = render(<ToDoItem {...getDefaultProps()} isObserving={true} />)
  expect(wrapper.queryByTestId('todo-sidebar-item-close-button')).not.toBeInTheDocument()
})

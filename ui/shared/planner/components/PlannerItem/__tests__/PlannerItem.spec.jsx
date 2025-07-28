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
import MockDate from 'mockdate'
import {PlannerItem_raw as PlannerItem} from '../index'

const MY_TIMEZONE = 'America/Los_Angeles'
const DEFAULT_DATE = moment.tz('2011-12-17T03:30:00', MY_TIMEZONE)
const user = {id: '1', displayName: 'Jane', avatarUrl: '/picture/is/here', color: '#03893D'}

function defaultProps(option = {}) {
  return {
    color: '#d71f85',
    id: '1',
    uniqueId: 'one',
    associated_item: option.associated_item || 'Assignment',
    date: DEFAULT_DATE,
    courseName: 'A Course about being Diffrient',
    completed: !!option.completed,
    title: option.title || 'This Assignment is about awesome stuff',
    points: option.points,
    html_url: option.html_url || 'http://example.com',
    timeZone: option.timeZone || 'America/Denver',
    toggleCompletion: () => {},
    updateTodo: () => {},
    currentUser: user,
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
    ...option,
  }
}

function noteProps(option = {}) {
  return {
    id: '22',
    uniqueId: 'twenty-two',
    associated_item: null,
    date: DEFAULT_DATE,
    timeZone: option.timeZone || 'America/Denver',
    courseName: option.courseName,
    completed: !!option.completed,
    title: option.title || 'A note about note taking',
    toggleCompletion: () => {},
    updateTodo: () => {},
    currentUser: user,
    dateStyle: 'todo',
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
    ...option,
  }
}

describe('PlannerItem', () => {
  beforeEach(() => {
    MockDate.set('2017-04-24', 0)
  })

  afterEach(() => {
    MockDate.reset()
  })

  it('renders basic planner item correctly', () => {
    const props = defaultProps({points: 35, date: DEFAULT_DATE})
    const {getByText} = render(<PlannerItem {...props} />)

    expect(getByText(props.title)).toBeInTheDocument()
    expect(getByText('35')).toBeInTheDocument()
    expect(getByText('pts')).toBeInTheDocument()
  })

  it('renders assignment with icon', () => {
    const props = defaultProps({associated_item: 'Assignment'})
    const {container} = render(<PlannerItem {...props} />)

    expect(container.querySelector('[name="IconAssignment"]')).toBeInTheDocument()
  })

  it('renders quiz with icon', () => {
    const props = defaultProps({associated_item: 'Quiz'})
    const {container} = render(<PlannerItem {...props} />)

    expect(container.querySelector('[name="IconQuiz"]')).toBeInTheDocument()
  })

  it('renders discussion with icon', () => {
    const props = defaultProps({associated_item: 'Discussion'})
    const {container} = render(<PlannerItem {...props} />)

    expect(container.querySelector('[name="IconDiscussion"]')).toBeInTheDocument()
  })

  it('renders announcement with icon', () => {
    const props = defaultProps({associated_item: 'Announcement'})
    const {container} = render(<PlannerItem {...props} />)

    expect(container.querySelector('[name="IconAnnouncement"]')).toBeInTheDocument()
  })

  it('renders calendar event with icon', () => {
    const props = defaultProps({associated_item: 'Calendar Event'})
    const {container} = render(<PlannerItem {...props} />)

    expect(container.querySelector('[name="IconCalendarMonth"]')).toBeInTheDocument()
  })

  it('renders page with icon', () => {
    const props = defaultProps({associated_item: 'Page'})
    const {container} = render(<PlannerItem {...props} />)

    expect(container.querySelector('[name="IconDocument"]')).toBeInTheDocument()
  })

  it('renders peer review with icon', () => {
    const props = defaultProps({associated_item: 'Peer Review'})
    const {container} = render(<PlannerItem {...props} />)

    expect(container.querySelector('[name="IconPeerReview"]')).toBeInTheDocument()
  })

  it('renders todo item correctly', () => {
    const props = noteProps({})
    const {getByText, container} = render(<PlannerItem {...props} />)

    expect(getByText(props.title)).toBeInTheDocument()
    // Todo items render user avatar, not an icon
    expect(container.querySelector('[data-fs-exclude="true"]')).toBeInTheDocument()
  })

  it('renders todo item with course name when missing', () => {
    const props = noteProps({courseName: 'some course', isMissingItem: true})
    const {getByText} = render(<PlannerItem {...props} />)

    expect(getByText(props.title)).toBeInTheDocument()
    expect(getByText('some course')).toBeInTheDocument()
  })

  it('renders calendar event with location', () => {
    const props = defaultProps({
      associated_item: 'Calendar Event',
      location: 'A fine location',
    })
    const {getByText} = render(<PlannerItem {...props} />)

    expect(getByText('A fine location')).toBeInTheDocument()
  })

  it('renders new activity badge', () => {
    const props = defaultProps({
      associated_item: 'Discussion',
      title: 'I am a Discussion',
      newActivity: true,
      showNotificationBadge: true,
    })
    const {getByText} = render(<PlannerItem {...props} />)

    expect(getByText('New activity for I am a Discussion')).toBeInTheDocument()
  })

  it('renders missing badge', () => {
    const props = defaultProps({
      associated_item: 'Assignment',
      title: 'I am an Assignment',
      showNotificationBadge: true,
      status: {missing: true},
      context: {type: 'Course'},
    })
    const {getByText} = render(<PlannerItem {...props} />)

    expect(getByText('Missing items for I am an Assignment')).toBeInTheDocument()
  })

  it('renders badges for assignments', () => {
    const props = defaultProps({
      badges: [
        {id: 'late', text: 'Late', type: 'Badge', variant: 'danger'},
        {id: 'feedback', text: 'Feedback', type: 'Badge', variant: 'primary'},
      ],
    })
    const {getByText} = render(<PlannerItem {...props} />)

    expect(getByText('Late')).toBeInTheDocument()
    expect(getByText('Feedback')).toBeInTheDocument()
  })

  it('renders checkbox for non-read-only items', () => {
    const props = defaultProps({completed: false})
    const {getByRole} = render(<PlannerItem {...props} />)

    const checkbox = getByRole('checkbox')
    expect(checkbox).toBeInTheDocument()
    expect(checkbox).not.toBeChecked()
  })

  it('renders checked checkbox for completed items', () => {
    const props = defaultProps({completed: true})
    const {getByRole} = render(<PlannerItem {...props} />)

    const checkbox = getByRole('checkbox')
    expect(checkbox).toBeInTheDocument()
    expect(checkbox).toBeChecked()
  })

  it('renders warning icon for missing items instead of checkbox', () => {
    const props = defaultProps({isMissingItem: true})
    const {queryByRole, container} = render(<PlannerItem {...props} />)

    expect(queryByRole('checkbox')).not.toBeInTheDocument()
    expect(container.querySelector('[name="IconWarning"]')).toBeInTheDocument()
  })

  it('calls toggleCompletion when checkbox is clicked', async () => {
    const toggleCompletion = jest.fn()
    const props = defaultProps({toggleCompletion, completed: false})
    const {getByRole} = render(<PlannerItem {...props} />)

    const checkbox = getByRole('checkbox')
    await userEvent.click(checkbox)

    expect(toggleCompletion).toHaveBeenCalled()
  })

  it('renders link to assignment with correct href', () => {
    const props = defaultProps({html_url: 'http://www.example.com'})
    const {getByRole} = render(<PlannerItem {...props} />)

    const link = getByRole('link', {name: new RegExp(props.title)})
    expect(link).toHaveAttribute('href', 'http://www.example.com')
  })

  it('renders points when provided', () => {
    const props = defaultProps({points: 42})
    const {getByText} = render(<PlannerItem {...props} />)

    expect(getByText('42')).toBeInTheDocument()
    expect(getByText('pts')).toBeInTheDocument()
  })

  it('renders all day events correctly', () => {
    const props = defaultProps({
      associated_item: 'Calendar Event',
      allDay: true,
    })
    const {getByText} = render(<PlannerItem {...props} />)

    expect(getByText('All Day')).toBeInTheDocument()
  })
})

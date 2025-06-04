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
// eslint-disable-next-line no-redeclare
import {render, fireEvent, screen} from '@testing-library/react'
import moment from 'moment-timezone'
import fakeENV from '@canvas/test-utils/fakeENV'
import {Grouping} from '../index'

beforeEach(() => {
  fakeENV.setup()
})

afterEach(() => {
  fakeENV.teardown()
})

const getDefaultProps = () => ({
  items: [
    {
      id: '5',
      uniqueId: 'five',
      title: 'San Juan',
      date: moment.tz('2017-04-25T05:06:07-08:00', 'America/Denver'),
      context: {
        url: 'example.com',
        color: '#5678',
        id: 256,
      },
    },
    {
      id: '6',
      uniqueId: 'six',
      date: moment.tz('2017-04-25T05:06:07-08:00', 'America/Denver'),
      title: 'Roll for the Galaxy',
      context: {
        color: '#5678',
        id: 256,
      },
    },
  ],
  timeZone: 'America/Denver',
  color: '#5678',
  id: 256,
  url: 'example.com',
  title: 'Board Games',
  updateTodo: () => {},
  animatableIndex: 1,
})

it('renders the base component with required props', () => {
  render(<Grouping {...getDefaultProps()} />)

  // Check that the main grouping container is rendered
  expect(document.querySelector('.planner-grouping')).toBeInTheDocument()

  // Check that the grouping link is rendered with the correct href
  const groupLink = screen.getByRole('link')
  expect(groupLink).toHaveAttribute('href', 'example.com')

  // Check that the title is rendered
  expect(screen.getByText('Board Games')).toBeInTheDocument()

  // Check that planner items are rendered
  const plannerItems = screen.getAllByTestId('planner-item-raw')
  expect(plannerItems).toHaveLength(2)
})

it('grouping contains link pointing to course url', () => {
  const props = getDefaultProps()
  render(<Grouping {...props} />)

  const groupLink = screen.getByRole('link')
  expect(groupLink).toHaveAttribute('href', 'example.com')

  // Check that the link contains the title
  expect(groupLink).toHaveTextContent('Board Games')
})

it('renders to do items correctly', () => {
  const props = {
    items: [
      {
        id: '700',
        uniqueId: 'seven hundred',
        title: 'To Do 700',
        date: moment.tz('2017-06-16T05:06:07-06:00', 'America/Denver'),
        context: null,
      },
    ],
    timeZone: 'America/Denver',
    color: null,
    id: null,
    url: null,
    title: null,
    updateTodo: () => {},
    animatableIndex: 1,
  }
  render(<Grouping {...props} />)

  // When no title is provided, should show "To Do"
  expect(screen.getByText('To Do')).toBeInTheDocument()

  // Should not render a link when no URL (no role="link" should be found)
  expect(screen.queryByRole('link')).not.toBeInTheDocument()

  // Should render the to-do item
  const plannerItems = screen.getAllByTestId('planner-item-raw')
  expect(plannerItems).toHaveLength(1)
})

it('does not render completed items by default', () => {
  const props = getDefaultProps()
  props.items[0].completed = true
  const wrapper = render(<Grouping {...props} />)

  expect(wrapper.getAllByTestId('planner-item-raw')).toHaveLength(1)
})

it('renders a CompletedItemsFacade when completed items are present by default', () => {
  const props = getDefaultProps()
  props.items[0].completed = true

  render(<Grouping {...props} />)

  // Should render CompletedItemsFacade for completed items
  const completedToggle = screen.getByTestId('completed-items-toggle')
  expect(completedToggle).toBeInTheDocument()
  expect(completedToggle).toHaveTextContent('1 completed item')

  // Should only render one non-completed item
  const plannerItems = screen.getAllByTestId('planner-item-raw')
  expect(plannerItems).toHaveLength(1)
})

it('renders completed items when the facade is clicked', () => {
  const props = getDefaultProps()
  props.items[0].completed = true

  const wrapper = render(<Grouping {...props} />)

  const detailBtn = wrapper.getByTestId('completed-items-toggle')
  fireEvent.click(detailBtn)
  expect(wrapper.getAllByTestId('planner-item-raw')).toHaveLength(2)
})

it('renders completed items when they have the show property', () => {
  const props = getDefaultProps()
  props.items[0].show = true
  props.items[0].completed = true

  render(<Grouping {...props} />)

  expect(screen.getAllByTestId('planner-item-raw')).toHaveLength(2)
})

it('does not render a CompletedItemsFacade when completed items are shown', () => {
  const props = getDefaultProps()
  props.items[0].completed = true

  render(<Grouping {...props} />)

  // Click to show completed items
  const completedToggle = screen.getByTestId('completed-items-toggle')
  fireEvent.click(completedToggle)

  // Facade should no longer be present
  expect(screen.queryByTestId('completed-items-toggle')).not.toBeInTheDocument()

  // Both items should now be visible
  expect(screen.getAllByTestId('planner-item-raw')).toHaveLength(2)
})

it('renders an activity notification when there is new activity', () => {
  const props = getDefaultProps()
  props.items[1].newActivity = true
  render(<Grouping {...props} />)

  expect(screen.getByText(`New activity for ${props.title}`)).toBeInTheDocument()
})

it('does not render an activity notification when layout is not large', () => {
  const props = getDefaultProps()
  props.items[1].newActivity = true
  props.responsiveSize = 'medium'
  render(<Grouping {...props} />)

  expect(screen.queryByText(`New activity for ${props.title}`)).not.toBeInTheDocument()
})

it('renders a danger activity notification when there is a missing item', () => {
  const props = getDefaultProps()
  props.items[1].status = {missing: true}
  render(<Grouping {...props} />)

  expect(screen.getByText(`Missing items for ${props.title}`)).toBeInTheDocument()
})

it(`does not render a danger activity notification when using simplifiedControls`, () => {
  const props = getDefaultProps()
  const item = props.items[1]
  item.status = {missing: true}
  props.simplifiedControls = true
  render(<Grouping {...props} />)

  expect(screen.queryByText(`Missing items for ${props.title}`)).not.toBeInTheDocument()
})

it(`does not render a danger activity notification when layout is not large`, () => {
  const props = getDefaultProps()
  const item = props.items[1]
  item.status = {missing: true}
  props.responsiveSize = 'medium'
  render(<Grouping {...props} />)

  expect(screen.queryByText(`Missing items for ${props.title}`)).not.toBeInTheDocument()
})

it('renders the to do title when there is no course', () => {
  const props = getDefaultProps()
  props.title = null
  props.items[1].newActivity = true
  render(<Grouping {...props} />)

  expect(screen.getByText('New activity for To Do')).toBeInTheDocument()
})

it('does not render an activity badge when things have no new activity', () => {
  const props = getDefaultProps()
  render(<Grouping {...props} />)

  expect(screen.queryByText(`New activity for ${props.title}`)).not.toBeInTheDocument()
  expect(screen.queryByText(`Missing items for ${props.title}`)).not.toBeInTheDocument()
})

it('does not render activity badge when using simplifiedControls', () => {
  const props = getDefaultProps()
  props.items[0].completed = true
  props.items[1].newActivity = true
  render(<Grouping {...props} simplifiedControls={true} />)

  expect(screen.queryByText(`New activity for ${props.title}`)).not.toBeInTheDocument()
  expect(screen.queryByText(`Missing items for ${props.title}`)).not.toBeInTheDocument()
})

it('does not render the grouping image and title when using singleCourseView', () => {
  render(<Grouping {...getDefaultProps()} singleCourseView={true} />)

  expect(screen.queryByText('Board Games')).not.toBeInTheDocument()
  expect(screen.queryByRole('link')).not.toBeInTheDocument()
})

describe('handleFacadeClick', () => {
  let containerElement = null

  beforeEach(() => {
    containerElement = document.createElement('div')
    document.body.appendChild(containerElement)
  })

  afterEach(() => {
    if (containerElement && containerElement.parentNode) {
      document.body.removeChild(containerElement)
    }
  })

  it('sets focus to the groupingLink when called', () => {
    const ref = React.createRef()
    render(<Grouping {...getDefaultProps()} ref={ref} />, {container: containerElement})
    ref.current.handleFacadeClick()
    expect(document.activeElement).toBe(ref.current.groupingLink)
  })

  it('calls preventDefault on an event if given one', () => {
    const props = getDefaultProps()
    const ref = React.createRef()
    render(<Grouping {...props} ref={ref} />)

    const fakeEvent = {
      preventDefault: jest.fn(),
    }

    ref.current.handleFacadeClick(fakeEvent)

    expect(fakeEvent.preventDefault).toHaveBeenCalled()
  })
})

describe('toggleCompletion', () => {
  it('binds the toggleCompletion method to item', () => {
    const mockToggleCompletion = jest.fn()
    const props = getDefaultProps()
    render(<Grouping {...props} toggleCompletion={mockToggleCompletion} />)

    const input = screen.getAllByTestId('planner-item-completed-checkbox')[0]
    fireEvent.click(input)

    expect(mockToggleCompletion).toHaveBeenCalledWith(props.items[0])
  })
})

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn()
  const fakeDeregister = jest.fn()
  const firstItems = [
    {
      title: 'asdf',
      context: {id: 128},
      id: '1',
      uniqueId: 'first',
      date: moment.tz('2017-04-25T05:06:07-08:00', 'America/Denver'),
    },
    {
      title: 'jkl',
      context: {id: 256},
      id: '2',
      uniqueId: 'second',
      date: moment.tz('2017-04-25T05:06:07-08:00', 'America/Denver'),
    },
  ]
  const secondItems = [
    {
      title: 'qwer',
      context: {id: 128},
      id: '3',
      uniqueId: 'third',
      date: moment.tz('2017-04-25T05:06:07-08:00', 'America/Denver'),
    },
    {
      title: 'uiop',
      context: {id: 256},
      id: '4',
      uniqueId: 'fourth',
      date: moment.tz('2017-04-25T05:06:07-08:00', 'America/Denver'),
    },
  ]
  const ref = React.createRef()
  const {rerender} = render(
    <Grouping
      {...getDefaultProps()}
      items={firstItems}
      animatableIndex={42}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      ref={ref}
    />,
  )
  expect(fakeRegister).toHaveBeenCalledWith('group', ref.current, 42, ['first', 'second'])

  rerender(
    <Grouping
      {...getDefaultProps()}
      items={secondItems}
      animatableIndex={42}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      ref={ref}
    />,
  )
  expect(fakeDeregister).toHaveBeenCalledWith('group', ref.current, ['first', 'second'])
  expect(fakeRegister).toHaveBeenCalledWith('group', ref.current, 42, ['third', 'fourth'])
})

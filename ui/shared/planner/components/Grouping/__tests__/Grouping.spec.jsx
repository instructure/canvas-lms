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
import {shallow} from 'enzyme'
import {render, fireEvent} from '@testing-library/react'
import moment from 'moment-timezone'
import {Grouping} from '../index'

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
  const wrapper = shallow(<Grouping {...getDefaultProps()} />)
  expect(wrapper).toMatchSnapshot()
})

it('grouping contains link pointing to course url', () => {
  const props = getDefaultProps()
  const wrapper = shallow(<Grouping {...props} />)

  expect(wrapper).toMatchSnapshot()
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
  const wrapper = shallow(<Grouping {...props} />)
  expect(wrapper).toMatchSnapshot()
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

  const wrapper = shallow(<Grouping {...props} />)

  expect(wrapper).toMatchSnapshot()
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

  const wrapper = shallow(<Grouping {...props} />)

  expect(wrapper.find('Animatable(PlannerItem_raw)')).toHaveLength(2)
})

it('does not render a CompletedItemsFacade when showCompletedItems state is true', () => {
  const props = getDefaultProps()
  props.items[0].completed = true

  const wrapper = shallow(<Grouping {...props} />)

  wrapper.setState({showCompletedItems: true})
  expect(wrapper.find('Animatable(CompletedItemsFacade)')).toHaveLength(0)
})

it('renders an activity notification when there is new activity', () => {
  const props = getDefaultProps()
  props.items[1].newActivity = true
  const wrapper = shallow(<Grouping {...props} />)
  const nai = wrapper.find('Animatable(NewActivityIndicator)')
  expect(nai).toHaveLength(1)
  expect(nai.prop('title')).toBe(props.title)
})

it('does not render an activity notification when layout is not large', () => {
  const props = getDefaultProps()
  props.items[1].newActivity = true
  props.responsiveSize = 'medium'
  const wrapper = shallow(<Grouping {...props} />)
  const nai = wrapper.find('Animatable(NewActivityIndicator)')
  expect(nai).toHaveLength(0)
})

it('renders a danger activity notification when there is a missing item', () => {
  const props = getDefaultProps()
  props.items[1].status = {missing: true}
  const wrapper = shallow(<Grouping {...props} />)
  expect(wrapper.find('MissingIndicator')).toHaveLength(1)
})

it(`does not render a danger activity notification when there is a missing item
  but the course is not configured to inform students of overdue submissions`, () => {
  const props = getDefaultProps()
  const item = props.items[1]
  item.status = {missing: true}
  const wrapper = shallow(<Grouping {...props} />)
  expect(wrapper.find('Badge')).toHaveLength(0)
  expect(wrapper.find('ScreenReaderContent')).toHaveLength(0)
})

it(`does not render a danger activity notification when there is a missing item
  but the course is not present`, () => {
  const props = getDefaultProps()
  const item = props.items[1]
  item.status = {missing: true}
  delete item.context
  const wrapper = shallow(<Grouping {...props} />)
  expect(wrapper.find('Badge')).toHaveLength(0)
  expect(wrapper.find('ScreenReaderContent')).toHaveLength(0)
})

it('renders the to do title when there is no course', () => {
  const props = getDefaultProps()
  props.title = null
  props.items[1].newActivity = true
  const wrapper = shallow(<Grouping {...props} />)
  expect(wrapper.find('Animatable(NewActivityIndicator)').prop('title')).toBe('To Do')
})

it('does not render an activity badge when things have no new activity', () => {
  const props = getDefaultProps()
  const wrapper = shallow(<Grouping {...props} />)
  expect(wrapper.find('Badge')).toHaveLength(0)
})

it('does not render activity badge or colored completed items facade when using simplifiedControls', () => {
  const props = getDefaultProps()
  props.items[0].completed = true
  const wrapper = shallow(<Grouping {...props} simplifiedControls={true} />)

  expect(wrapper.find('Badge')).toHaveLength(0)
  expect(wrapper.find('Animatable(undefined)').prop('themeOverride').labelColor).toBeUndefined()
})

it('does not render the grouping image and title when using singleCourseView', () => {
  const wrapper = shallow(<Grouping {...getDefaultProps()} singleCourseView={true} />)

  expect(wrapper.find('.Grouping-styles__overlay')).toHaveLength(0)
  expect(wrapper.find('.Grouping-styles__title')).toHaveLength(0)
})

describe('handleFacadeClick', () => {
  let containerElement = null
  const wrapper = null

  beforeEach(() => {
    containerElement = document.createElement('div')
    document.body.appendChild(containerElement)
  })

  afterEach(() => {
    document.body.removeChild(containerElement)
  })

  it('sets focus to the groupingLink when called', () => {
    const ref = React.createRef()
    render(<Grouping {...getDefaultProps()} ref={ref} />, {attachTo: containerElement})
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
    const {getAllByTestId} = render(<Grouping {...props} toggleCompletion={mockToggleCompletion} />)

    const input = getAllByTestId('planner-item-completed-checkbox')[0]
    fireEvent.click(input)

    expect(mockToggleCompletion).toHaveBeenCalledWith(props.items[0])
  })
})

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn()
  const fakeDeregister = jest.fn()
  const firstItems = [
    {title: 'asdf', context: {id: 128}, id: '1', uniqueId: 'first'},
    {title: 'jkl', context: {id: 256}, id: '2', uniqueId: 'second'},
  ]
  const secondItems = [
    {title: 'qwer', context: {id: 128}, id: '3', uniqueId: 'third'},
    {title: 'uiop', context: {id: 256}, id: '4', uniqueId: 'fourth'},
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
    />
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
    />
  )
  expect(fakeDeregister).toHaveBeenCalledWith('group', ref.current, ['first', 'second'])
  expect(fakeRegister).toHaveBeenCalledWith('group', ref.current, 42, ['third', 'fourth'])
})

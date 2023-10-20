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
import {mount, shallow} from 'enzyme'
import moment from 'moment-timezone'
import {Day} from '../index'

const user = {id: '1', displayName: 'Jane', avatarUrl: '/picture/is/here', color: '#0B874B'}
const defaultProps = {registerAnimatable: jest.fn, deregisterAnimatable: jest.fn}

const currentTimeZoneName = moment.tz.guess()
const otherTimeZoneName = ['America/Denver', 'Europe/London'].find(it => it !== currentTimeZoneName)

// Tests need to run in at least one timezone
for (const [timeZoneDesc, timeZoneName] of [
  ['In current timezone', currentTimeZoneName],
  ['In other timezone', otherTimeZoneName],
]) {
  // eslint-disable-next-line jest/valid-describe
  describe(timeZoneDesc, () => {
    beforeAll(() => {
      moment.tz.setDefault(timeZoneName)
    })

    it('renders the base component with required props', () => {
      const wrapper = shallow(<Day {...defaultProps} timeZone={timeZoneName} day="2017-04-25" />)
      expect(wrapper).toMatchSnapshot()
    })

    it('renders the friendly name in large text and rest of the date on a second line when it is today', () => {
      const today = moment()
      const wrapper = shallow(
        <Day {...defaultProps} timeZone={timeZoneName} day={today.format('YYYY-MM-DD')} />
      )
      const friendlyName = wrapper.find('Heading').first().childAt(0)
      const fullDate = wrapper.find('Heading').first().childAt(1)

      expect(friendlyName.props().size).toBe('large')
      expect(fullDate.text()).toBe(today.format('MMMM D'))
    })

    it('renders the full date with friendly name on one line when it is not today', () => {
      const yesterday = moment().subtract(1, 'days')
      const wrapper = shallow(
        <Day {...defaultProps} timeZone={timeZoneName} day={yesterday.format('YYYY-MM-DD')} />
      )
      const fullDate = wrapper.find('Heading').first().childAt(0)

      expect(fullDate.text()).toBe(`Yesterday, ${yesterday.format('MMMM D')}`)
    })

    it('renders missing assignments if showMissingAssignments is true and it is today', () => {
      const today = moment()
      const wrapper = shallow(
        <Day
          {...defaultProps}
          timeZone={timeZoneName}
          day={today.format('YYYY-MM-DD')}
          showMissingAssignments={true}
        />
      )
      expect(wrapper.find('Connect(MissingAssignments)').exists()).toBeTruthy()
    })

    it('does not render missing assignments if it is not today', () => {
      const yesterday = moment().subtract(1, 'days')
      const wrapper = shallow(
        <Day
          {...defaultProps}
          timeZone={timeZoneName}
          day={yesterday.format('YYYY-MM-DD')}
          showMissingAssignments={true}
        />
      )
      expect(wrapper.find('Connect(MissingAssignments)').exists()).toBeFalsy()
    })

    it('only renders the year when the date is not in the current year', () => {
      const lastYear = moment().subtract(1, 'year')
      const wrapper = shallow(
        <Day {...defaultProps} timeZone={timeZoneName} day={lastYear.format('YYYY-MM-DD')} />
      )
      const fullDate = wrapper.find('Heading').first().childAt(0)

      expect(fullDate.text()).toBe(lastYear.format('dddd, MMMM D, YYYY'))
    })
  })
}

it('renders grouping correctly when having itemsForDay', () => {
  const TZ = 'America/Denver'
  const items = [
    {
      title: 'Black Friday',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {
        type: 'Course',
        id: 128,
        url: 'http://www.non_default_url.com',
      },
    },
    {
      title: 'San Juan',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {
        type: 'Course',
        id: 256,
        url: 'http://www.non_default_url.com',
      },
    },
    {
      title: 'Roll for the Galaxy',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {
        type: 'Course',
        id: 256,
        url: 'http://www.non_default_url.com',
      },
    },
    {
      title: 'Same id, different type',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {
        type: 'Group',
        id: 256,
      },
    },
  ]

  const wrapper = shallow(
    <Day
      {...defaultProps}
      timeZone={TZ}
      day="2017-04-25"
      itemsForDay={items}
      animatableIndex={1}
      currentUser={user}
    />
  )
  expect(wrapper).toMatchSnapshot()
})
it('groups itemsForDay that have no context into the "Notes" category', () => {
  const TZ = 'America/Denver'
  const items = [
    {
      title: 'Black Friday',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {
        type: 'Course',
        id: 128,
      },
    },
    {
      title: 'San Juan',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {
        type: 'Course',
        id: 256,
      },
    },
    {
      title: 'Roll for the Galaxy',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {
        type: 'Course',
        id: 256,
      },
    },
    {
      title: 'Get work done!',
    },
  ]

  const wrapper = shallow(
    <Day {...defaultProps} timeZone={TZ} day="2017-04-25" itemsForDay={items} currentUser={user} />
  )
  expect(wrapper).toMatchSnapshot()
})

it('groups itemsForDay that come in on prop changes', () => {
  const TZ = 'America/Denver'
  const items = [
    {
      title: 'Black Friday',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {
        type: 'Course',
        id: 128,
      },
    },
    {
      title: 'San Juan',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {
        type: 'Course',
        id: 256,
      },
    },
  ]

  const wrapper = shallow(
    <Day
      timeZone={TZ}
      day="2017-04-25"
      itemsForDay={items}
      registerAnimatable={() => {}}
      deregisterAnimatable={() => {}}
      currentUser={user}
    />
  )
  expect(wrapper).toMatchSnapshot()

  const newItemsForDay = items.concat([
    {
      title: 'Roll for the Galaxy',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {
        type: 'Course',
        id: 256,
      },
    },
    {
      title: 'Get work done!',
    },
  ])

  wrapper.setProps({itemsForDay: newItemsForDay})
  expect(wrapper).toMatchSnapshot()
})

it('renders even when there are no items', () => {
  const date = moment.tz('Asia/Tokyo').add(13, 'days')
  const wrapper = shallow(
    <Day
      {...defaultProps}
      timeZone="Asia/Tokyo"
      day={date.format('YYYY-MM-DD')}
      itemsForDay={[]}
      currentUser={user}
    />
  )
  expect(wrapper.type).not.toBeNull()
})

it('registers itself as animatable', () => {
  const TZ = 'Asia/Tokyo'
  const fakeRegister = jest.fn()
  const fakeDeregister = jest.fn()
  const firstItems = [
    {
      title: 'asdf',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {id: 128},
      id: '1',
      uniqueId: 'first',
    },
    {
      title: 'jkl',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {id: 256},
      id: '2',
      uniqueId: 'second',
    },
  ]
  const secondItems = [
    {
      title: 'qwer',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {id: 128},
      id: '3',
      uniqueId: 'third',
    },
    {
      title: 'uiop',
      date: moment.tz('2017-04-25T23:59:00Z', TZ),
      context: {id: 256},
      id: '4',
      uniqueId: 'fourth',
    },
  ]
  const wrapper = mount(
    <Day
      day="2017-08-11"
      timeZone={TZ}
      animatableIndex={42}
      itemsForDay={firstItems}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      updateTodo={() => {}}
      currentUser={user}
    />
  )
  const instance = wrapper.instance()
  expect(fakeRegister).toHaveBeenCalledWith('day', instance, 42, ['first', 'second'])

  wrapper.setProps({itemsForDay: secondItems})
  expect(fakeDeregister).toHaveBeenCalledWith('day', instance, ['first', 'second'])
  expect(fakeRegister).toHaveBeenCalledWith('day', instance, 42, ['third', 'fourth'])

  wrapper.unmount()
  expect(fakeDeregister).toHaveBeenCalledWith('day', instance, ['third', 'fourth'])
})

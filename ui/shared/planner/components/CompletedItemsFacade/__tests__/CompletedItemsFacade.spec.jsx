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
import {shallow, mount} from 'enzyme'
import {CompletedItemsFacade} from '../index'

it('renders ToggleDetails with text indicating count', () => {
  const wrapper = shallow(<CompletedItemsFacade onClick={() => {}} itemCount={3} />)

  expect(wrapper.find('ToggleDetails').props().summary).toEqual('Show 3 completed items')
})

it('calls the onClick prop when clicked', () => {
  const fakeOnClick = jest.fn()
  const wrapper = mount(<CompletedItemsFacade onClick={fakeOnClick} itemCount={0} />)

  wrapper.find('button').simulate('click')
  expect(fakeOnClick).toHaveBeenCalled()
})

it('displays Pills when given them', () => {
  const wrapper = shallow(
    <CompletedItemsFacade
      onClick={() => {}}
      itemCount={3}
      badges={[{id: 'new_graded', text: 'Graded'}]}
    />
  )
  expect(wrapper.find('Pill')).toHaveLength(1)
})

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn()
  const fakeDeregister = jest.fn()
  const wrapper = mount(
    <CompletedItemsFacade
      onClick={() => {}}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      animatableIndex={42}
      animatableItemIds={['1', '2', '3']}
      itemCount={3}
    />
  )
  const instance = wrapper.instance()
  expect(fakeRegister).toHaveBeenCalledWith('item', instance, 42, ['1', '2', '3'])

  wrapper.setProps({animatableItemIds: ['2', '3', '4']})
  expect(fakeDeregister).toHaveBeenCalledWith('item', instance, ['1', '2', '3'])
  expect(fakeRegister).toHaveBeenCalledWith('item', instance, 42, ['2', '3', '4'])

  wrapper.unmount()
  expect(fakeDeregister).toHaveBeenCalledWith('item', instance, ['2', '3', '4'])
})

it('renders its own NotificationBadge when asked to', () => {
  const wrapper = mount(
    <CompletedItemsFacade
      onClick={() => {}}
      notificationBadge="newActivity"
      itemCount={3}
      animatableItemIds={['1', '2', '3']}
    />
  )
  expect(wrapper.find('NewActivityIndicator')).toHaveLength(1)
})

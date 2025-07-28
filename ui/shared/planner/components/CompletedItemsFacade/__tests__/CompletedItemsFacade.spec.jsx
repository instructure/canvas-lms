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
import {CompletedItemsFacade} from '../index'

it('renders ToggleDetails with text indicating count', () => {
  const wrapper = render(<CompletedItemsFacade onClick={() => {}} itemCount={3} />)

  expect(wrapper.getByText('Show 3 completed items')).toBeInTheDocument()
})

it('calls the onClick prop when clicked', async () => {
  const fakeOnClick = jest.fn()
  const wrapper = render(<CompletedItemsFacade onClick={fakeOnClick} itemCount={0} />)

  const button = wrapper.getByText('Show 0 completed items')
  await userEvent.click(button)
  expect(fakeOnClick).toHaveBeenCalled()
})

it('displays Pills when given them', () => {
  const wrapper = render(
    <CompletedItemsFacade
      onClick={() => {}}
      itemCount={3}
      badges={[{id: 'new_graded', text: 'Graded'}]}
    />,
  )
  expect(wrapper.getAllByTestId('badgepill')).toHaveLength(1)
})

it('registers itself as animatable', () => {
  const ref = React.createRef()
  const fakeRegister = jest.fn()
  const fakeDeregister = jest.fn()
  const wrapper = render(
    <CompletedItemsFacade
      ref={ref}
      onClick={() => {}}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      animatableIndex={42}
      animatableItemIds={['1', '2', '3']}
      itemCount={3}
    />,
  )
  expect(fakeRegister).toHaveBeenCalledWith('item', ref.current, 42, ['1', '2', '3'])

  wrapper.rerender(
    <CompletedItemsFacade
      ref={ref}
      onClick={() => {}}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      animatableIndex={42}
      animatableItemIds={['2', '3', '4']}
      itemCount={3}
    />,
  )

  const instance = ref.current
  expect(fakeDeregister).toHaveBeenCalledWith('item', instance, ['1', '2', '3'])
  expect(fakeRegister).toHaveBeenCalledWith('item', instance, 42, ['2', '3', '4'])

  wrapper.unmount()
  expect(fakeDeregister).toHaveBeenCalledWith('item', instance, ['2', '3', '4'])
})

it('renders its own NotificationBadge when asked to', () => {
  const wrapper = render(
    <CompletedItemsFacade
      onClick={() => {}}
      notificationBadge="newActivity"
      itemCount={3}
      animatableItemIds={['1', '2', '3']}
    />,
  )
  expect(wrapper.getAllByText('New activity for', {exact: false})).toHaveLength(1)
})

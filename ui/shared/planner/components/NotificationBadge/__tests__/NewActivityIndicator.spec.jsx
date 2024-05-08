/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {NewActivityIndicator} from '../NewActivityIndicator'

it('passes props to Indicator', () => {
  const wrapper = shallow(<NewActivityIndicator title="some title" itemIds={['1', '2']} />)
  expect(wrapper).toMatchSnapshot()
})

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn()
  const fakeDeregister = jest.fn()
  const ref = React.createRef()
  const wrapper = render(
    <NewActivityIndicator
      title="some title"
      itemIds={['first', 'second']}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      animatableIndex={42}
      ref={ref}
    />
  )
  expect(fakeRegister).toHaveBeenCalledWith('new-activity-indicator', ref.current, 42, [
    'first',
    'second',
  ])

  wrapper.rerender(
    <NewActivityIndicator
      title="some title"
      itemIds={['third', 'fourth']}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      animatableIndex={84}
      ref={ref}
    />
  )
  expect(fakeDeregister).toHaveBeenCalledWith('new-activity-indicator', ref.current, [
    'first',
    'second',
  ])
  expect(fakeRegister).toHaveBeenCalledWith('new-activity-indicator', ref.current, 84, [
    'third',
    'fourth',
  ])
})

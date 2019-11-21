/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React from 'react'
import {shallow} from 'enzyme'
import {IconArrowUpSolid, IconArrowDownLine} from '@instructure/ui-icons'
import StickyButton from '../index'

it('renders', () => {
  const wrapper = shallow(<StickyButton id="sb">I am a Sticky Button</StickyButton>)
  expect(wrapper).toMatchSnapshot()
})

it('calls the onClick prop when clicked', () => {
  const fakeOnClick = jest.fn()
  const wrapper = shallow(
    <StickyButton id="sb" onClick={fakeOnClick}>
      Click me
    </StickyButton>
  )

  wrapper.find('button').simulate('click')
  expect(fakeOnClick).toHaveBeenCalled()
})

it('does not call the onClick prop when disabled', () => {
  const fakeOnClick = jest.fn()
  const wrapper = shallow(
    <StickyButton id="sb" onClick={fakeOnClick} disabled>
      Disabled button
    </StickyButton>
  )

  wrapper.find('button').simulate('click', {
    preventDefault() {},
    stopPropagation() {}
  })
  expect(fakeOnClick).not.toHaveBeenCalled()
})

it('renders the correct up icon', () => {
  const wrapper = shallow(
    <StickyButton id="sb" direction="up">
      Click me
    </StickyButton>
  )
  expect(wrapper.find(IconArrowUpSolid)).toHaveLength(1)
})

it('renders the correct down icon', () => {
  const wrapper = shallow(
    <StickyButton id="sb" direction="down">
      Click me
    </StickyButton>
  )
  expect(wrapper.find(IconArrowDownLine)).toHaveLength(1)
})

it('adds aria-hidden when specified', () => {
  const wrapper = shallow(
    <StickyButton id="sb" hidden>
      Click me
    </StickyButton>
  )

  expect(wrapper).toMatchSnapshot()
})

it('shows aria-describedby when a description is given', () => {
  const wrapper = shallow(
    <StickyButton id="sb" description="hello world">
      Click me
    </StickyButton>
  )
  expect(wrapper.find('button[aria-describedby="sb_desc"]')).toHaveLength(1)
  expect(wrapper.find('#sb_desc')).toHaveLength(1)
})

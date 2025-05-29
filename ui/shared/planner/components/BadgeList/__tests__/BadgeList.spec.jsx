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
import {Pill} from '@instructure/ui-pill'
import BadgeList from '../index'

it('renders Pill components as list items', () => {
  const wrapper = shallow(
    <BadgeList>
      <Pill>Pill 1</Pill>
      <Pill>Pill 2</Pill>
      <Pill>Pill 3</Pill>
    </BadgeList>,
  )

  // Should render a ul element
  const list = wrapper.find('ul')
  expect(list).toHaveLength(1)

  // Should have proper CSS class
  expect(list.hasClass('BadgeList-styles__root')).toBe(true)

  // Should render 3 list items
  const items = wrapper.find('li')
  expect(items).toHaveLength(3)

  // Each list item should have the proper CSS class
  items.forEach(item => {
    expect(item.hasClass('BadgeList-styles__item')).toBe(true)
  })

  // Should contain 3 Pill components
  const pills = wrapper.find('Pill')
  expect(pills).toHaveLength(3)

  // Check that Pills have correct text content
  expect(pills.at(0).children().text()).toBe('Pill 1')
  expect(pills.at(1).children().text()).toBe('Pill 2')
  expect(pills.at(2).children().text()).toBe('Pill 3')

  // Pills should have default color
  pills.forEach(pill => {
    expect(pill.prop('color')).toBe('primary')
  })
})

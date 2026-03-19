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
import {Pill} from '@instructure/ui-pill'
import BadgeList from '../index'

it('renders Pill components as list items', () => {
  const {container, getByText} = render(
    <BadgeList>
      <Pill>Pill 1</Pill>
      <Pill>Pill 2</Pill>
      <Pill>Pill 3</Pill>
    </BadgeList>,
  )

  // Should render a ul element
  const list = container.querySelector('ul')
  expect(list).toBeInTheDocument()

  // Should have proper CSS class
  expect(list).toHaveClass('BadgeList-styles__root')

  // Should render 3 list items
  const items = container.querySelectorAll('li')
  expect(items).toHaveLength(3)

  // Each list item should have the proper CSS class
  items.forEach(item => {
    expect(item).toHaveClass('BadgeList-styles__item')
  })

  // Check that Pills have correct text content
  expect(getByText('Pill 1')).toBeInTheDocument()
  expect(getByText('Pill 2')).toBeInTheDocument()
  expect(getByText('Pill 3')).toBeInTheDocument()
})

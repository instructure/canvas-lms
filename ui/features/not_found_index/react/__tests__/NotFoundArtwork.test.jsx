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
import {mount} from 'enzyme'
import NotFoundArtwork from '../NotFoundArtwork'

const defaultProps = () => {}

test('renders the NotFoundArtwork component', () => {
  const tree = mount(<NotFoundArtwork {...defaultProps()} />)
  expect(tree.exists()).toBe(true)
})

test('renders the NotFoundArtwork renders correct header', () => {
  const tree = mount(<NotFoundArtwork {...defaultProps()} />)
  const node = tree.find('Heading').at(0)
  expect(node.text()).toBe('Whoops... Looks like nothing is here!')
})

test('renders the NotFoundArtwork component help description', () => {
  const tree = mount(<NotFoundArtwork {...defaultProps()} />)
  const node = tree.find('Text').at(0)
  expect(node.text()).toBe("We couldn't find that page!")
})

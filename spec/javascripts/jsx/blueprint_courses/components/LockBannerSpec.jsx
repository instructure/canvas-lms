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
import * as enzyme from 'enzyme'
import LockBanner from '@canvas/blueprint-courses/react/components/LockManager/LockBanner'

QUnit.module('LockBanner component')

const defaultProps = () => ({
  isLocked: true,
  itemLocks: {
    content: true,
    points: false,
    due_dates: false,
    availability_dates: false,
  },
})

test('renders an Alert when LockBanner is locked', () => {
  const props = defaultProps()
  props.isLocked = true
  const tree = enzyme.mount(<LockBanner {...props} />)
  const node = tree.find('Alert')
  ok(node.exists())
})

test('does not render Alert when LockBanner is locked', () => {
  const props = defaultProps()
  props.isLocked = false
  const tree = enzyme.mount(<LockBanner {...props} />)
  const node = tree.find('Alert')
  notOk(node.exists())
})

test('displays locked description text appropriately when one attribute is locked', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<LockBanner {...props} />)
  const text = tree.find('Text').at(2).text()
  equal(text, 'Content')
})

test('displays locked description text appropriately when two attributes are locked', () => {
  const props = defaultProps()
  props.itemLocks.points = true
  const tree = enzyme.mount(<LockBanner {...props} />)
  const text = tree.find('Text').at(2).text()
  equal(text, 'Content & Points')
})

test('displays locked description text appropriately when more than two attributes are locked', () => {
  const props = defaultProps()
  props.itemLocks.points = true
  props.itemLocks.due_dates = true
  const tree = enzyme.mount(<LockBanner {...props} />)
  const text = tree.find('Text').at(2).text()
  equal(text, 'Content, Points & Due Dates')
})

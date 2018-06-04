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
import LockToggle from 'jsx/blueprint_courses/components/LockToggle'

QUnit.module('LockToggle component')

const defaultProps = () => ({
  isLocked: true,
  isToggleable: true,
})

test('renders the LockToggle component', () => {
  const tree = enzyme.shallow(<LockToggle {...defaultProps()} />)
  const node = tree.find('.bpc-lock-toggle')
  ok(node.exists())
})

test('renders a button when LockToggle is toggleable', () => {
  const props = defaultProps()
  props.isToggleable = true
  const tree = enzyme.mount(<LockToggle {...props} />)
  const node = tree.find('Button')
  ok(node.exists())
})

test('does not render a button when LockToggle is not toggleable', () => {
  const props = defaultProps()
  props.isToggleable = false
  const tree = enzyme.shallow(<LockToggle {...props} />)
  const node = tree.find('Button')
  notOk(node.exists())
})

test('renders a locked icon when LockToggle is locked', () => {
  const props = defaultProps()
  props.isLocked = true
  const tree = enzyme.shallow(<LockToggle {...props} />)
  const node = tree.find('IconBlueprintLock')
  ok(node.exists())
})

test('renders an unlocked icon when LockToggle is unlocked', () => {
  const props = defaultProps()
  props.isLocked = false
  const tree = enzyme.shallow(<LockToggle {...props} />)
  const node = tree.find('IconBlueprint')
  ok(node.exists())
})

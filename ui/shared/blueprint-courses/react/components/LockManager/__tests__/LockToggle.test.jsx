/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import LockToggle from '../LockToggle'

describe('LockToggle component', () => {
  const defaultProps = () => ({
    isLocked: true,
    isToggleable: true,
  })

  test('renders the LockToggle component', () => {
    const tree = render(<LockToggle {...defaultProps()} />)
    const node = tree.container.querySelector('.bpc-lock-toggle')
    expect(node).toBeTruthy()
  })

  test('renders a button when LockToggle is toggleable', () => {
    const props = defaultProps()
    props.isToggleable = true
    const tree = render(<LockToggle {...props} />)
    const node = tree.container.querySelector('button')
    expect(node).toBeTruthy()
  })

  test('does not render a button when LockToggle is not toggleable', () => {
    const props = defaultProps()
    props.isToggleable = false
    const tree = shallow(<LockToggle {...props} />)
    const node = tree.find('button')
    expect(node.exists()).toBeFalsy()
  })

  test('renders a locked icon when LockToggle is locked', () => {
    const props = defaultProps()
    props.isLocked = true
    const tree = render(<LockToggle {...props} />)
    console.log(tree.container.innerHTML)
    const node = tree.container.querySelector('svg[name="IconBlueprintLock"]')
    expect(node).toBeTruthy()
  })

  test('renders an unlocked icon when LockToggle is unlocked', () => {
    const props = defaultProps()
    props.isLocked = false
    const tree = render(<LockToggle {...props} />)
    console.log(tree.container.innerHTML)
    const node = tree.container.querySelector('svg[name="IconBlueprint"]')
    expect(node).toBeTruthy()
  })
})

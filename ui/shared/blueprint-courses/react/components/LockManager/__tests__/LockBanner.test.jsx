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
import {render} from '@testing-library/react'
import LockBanner from '../LockBanner'

describe('LockBanner component', () => {
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
    const tree = render(<LockBanner {...props} />)
    const node = tree.container.querySelector('div')
    expect(node).toBeTruthy()
  })

  test('does not render Alert when LockBanner is locked', () => {
    const props = defaultProps()
    props.isLocked = false
    const tree = render(<LockBanner {...props} />)
    const node = tree.container.querySelector('div')
    expect(node).toBeFalsy()
  })

  test('displays locked description text appropriately when one attribute is locked', () => {
    const props = defaultProps()
    const tree = render(<LockBanner {...props} />)
    const text = tree.container.querySelector("[data-testid='lockedMessage'").textContent
    expect(text).toEqual('Content')
  })

  test('displays locked description text appropriately when two attributes are locked', () => {
    const props = defaultProps()
    props.itemLocks.points = true
    const tree = render(<LockBanner {...props} />)
    const text = tree.container.querySelector("[data-testid='lockedMessage'").textContent
    expect(text).toEqual('Content & Points')
  })

  test('displays locked description text appropriately when more than two attributes are locked', () => {
    const props = defaultProps()
    props.itemLocks.points = true
    props.itemLocks.due_dates = true
    const tree = render(<LockBanner {...props} />)
    const text = tree.container.querySelector("[data-testid='lockedMessage'").textContent
    expect(text).toEqual('Content, Points & Due Dates')
  })
})

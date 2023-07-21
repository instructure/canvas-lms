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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import ExpandableLockOptions from '../ExpandableLockOptions'

const defaultProps = () => ({
  objectType: 'assignment',
  isOpen: false,
  lockableAttributes: ['content', 'points', 'due_dates', 'availability_dates'],
  locks: {
    content: false,
    points: false,
    due_dates: false,
    availability_dates: false,
  },
})

describe('ExpandableLockOptions', () => {
  it('renders', () => {
    const {queryByText} = render(<ExpandableLockOptions {...defaultProps()} />)
    expect(queryByText('Assignments')).not.toBeNull()
  })

  it('renders the closed toggle Icon', () => {
    const {container} = render(<ExpandableLockOptions {...defaultProps()} />)
    expect(container.querySelector('[name="IconArrowOpenEnd"')).not.toBeNull()
  })

  it('renders the opened toggle Icon', () => {
    const {container} = render(<ExpandableLockOptions {...{...defaultProps(), isOpen: true}} />)
    expect(container.querySelector('[name="IconArrowOpenDown"')).not.toBeNull()
  })

  it('opens the submenu when toggle is clicked', () => {
    const {getByTestId} = render(<ExpandableLockOptions {...defaultProps()} />)
    expect(getByTestId('sub-list').className.includes('bcs_sub-menu-viewable')).toEqual(false)
    fireEvent.click(getByTestId('toggle'))
    expect(getByTestId('sub-list').className.includes('bcs_sub-menu-viewable')).toEqual(true)
  })

  it('renders the unlocked lock Icon when unlocked', () => {
    const {getByTestId, queryByTestId} = render(<ExpandableLockOptions {...defaultProps()} />)
    expect(getByTestId('unlock-icon')).not.toBeNull()
    expect(queryByTestId('lock-icon')).toBeNull()
  })

  it('renders the locked lock Icon when locked', () => {
    const {getByTestId, queryByTestId} = render(
      <ExpandableLockOptions {...{...defaultProps(), locks: {content: true}}} />
    )
    expect(getByTestId('lock-icon')).not.toBeNull()
    expect(queryByTestId('unlock-icon')).toBeNull()
  })
})

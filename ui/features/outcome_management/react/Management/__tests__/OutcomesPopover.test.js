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
import {render, fireEvent} from '@testing-library/react'
import OutcomesPopover from '../OutcomesPopover'

describe('OutcomesPopover', () => {
  const defaultProps = () => ({
    outcomes: new Array(3).fill(0).map((_v, i) => ({
      _id: i,
      title: `Outcome ${i + 1} `
    }))
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the OutcomesPopover component', () => {
    const {getByText, getByRole} = render(<OutcomesPopover {...defaultProps()} />)
    expect(getByText('3 Outcomes Selected')).toBeInTheDocument()
    expect(getByRole('button').hasAttribute('aria-disabled')).toBe(false)
  })

  it('renders the OutcomesPopover component with 0 outcomes selected', () => {
    const {getByText, getByRole} = render(<OutcomesPopover outcomes={[]} />)
    expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
    expect(getByRole('button').hasAttribute('aria-disabled')).toBe(true)
  })

  it('shows details on click', () => {
    const {getByText, getByRole} = render(<OutcomesPopover {...defaultProps()} />)
    const button = getByRole('button')
    fireEvent.click(button)
    expect(getByText('Selected')).toBeInTheDocument()
    expect(button.getAttribute('aria-expanded')).toBe('true')
  })

  it('closes popover when clicking Close button', () => {
    const {getByRole, getByText} = render(<OutcomesPopover {...defaultProps()} />)
    const button = getByRole('button')
    fireEvent.click(button)
    const closeButton = getByText('Close')
    fireEvent.click(closeButton)
    expect(button.getAttribute('aria-expanded')).toBe('false')
  })
})

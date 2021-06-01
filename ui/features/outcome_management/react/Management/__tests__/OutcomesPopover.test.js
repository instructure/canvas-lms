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
  const generateOutcomes = (num, canUnlink) =>
    new Array(num).fill(0).reduce(
      (_val, idx) => ({
        [idx + 1]: {_id: `idx + 1`, title: `Outcome ${idx + 1}`, canUnlink}
      }),
      {}
    )
  const defaultProps = (numberToGenerate, canUnlink = true) => ({
    outcomes: generateOutcomes(numberToGenerate, canUnlink),
    outcomeCount: numberToGenerate
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the OutcomesPopover component', () => {
    const {getByText, getByRole} = render(<OutcomesPopover {...defaultProps(2)} />)
    expect(getByText('2 Outcomes Selected')).toBeInTheDocument()
    expect(getByRole('button').hasAttribute('aria-disabled')).toBe(false)
  })

  it('renders the OutcomesPopover component with 0 outcomes selected', () => {
    const {getByText, getByRole} = render(<OutcomesPopover {...defaultProps(0)} />)
    expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
    expect(getByRole('button').hasAttribute('aria-disabled')).toBe(true)
  })

  it('shows details on click', () => {
    const {getByText, getByRole} = render(<OutcomesPopover {...defaultProps(2)} />)
    const button = getByRole('button')
    fireEvent.click(button)
    expect(getByText('Selected')).toBeInTheDocument()
    expect(button.getAttribute('aria-expanded')).toBe('true')
  })

  it('closes popover when clicking Close button', () => {
    const {getByRole, getByText} = render(<OutcomesPopover {...defaultProps(2)} />)
    const button = getByRole('button')
    fireEvent.click(button)
    const closeButton = getByText('Close')
    fireEvent.click(closeButton)
    expect(button.getAttribute('aria-expanded')).toBe('false')
  })
})

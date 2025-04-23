/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {ContentItems} from '../ContentItems'

describe('ContentItems', () => {
  const defaultProps = {
    label: 'Test Items (2 items)',
    screenReaderLabel: 'Test Items',
    contents: [
      {
        id: 1,
        name: 'Item 1',
        link: '/item/1',
        errors: {
          submission_types: {
            attribute: 'submission_type',
            type: 'unsupported',
            message: 'Submission type not supported',
          },
        },
      },
      {
        id: 2,
        name: 'Item 2',
        link: '/item/2',
        errors: {
          submission_types: {
            attribute: 'submission_type',
            type: 'unsupported',
            message: 'Submission type not supported',
          },
        },
      },
    ],
  }

  it('renders the label', () => {
    render(<ContentItems {...defaultProps} />)
    expect(screen.getByText('Test Items (2 items)')).toBeInTheDocument()
  })

  it('renders all content items', async () => {
    render(<ContentItems {...defaultProps} />)
    const toggle = screen.getByText('Test Items')
    toggle.click()
    expect(screen.getByText('Item 1')).toBeInTheDocument()
    expect(screen.getByText('Item 2')).toBeInTheDocument()
  })

  it('links to the correct URLs', async () => {
    render(<ContentItems {...defaultProps} />)
    const toggle = screen.getByText('Test Items')
    toggle.click()
    const link1 = screen.getByText('Item 1')
    const link2 = screen.getByText('Item 2')
    expect(link1).toHaveAttribute('href', '/item/1')
    expect(link2).toHaveAttribute('href', '/item/2')
  })
})

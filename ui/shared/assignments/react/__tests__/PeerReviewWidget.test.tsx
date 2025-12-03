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
import {PeerReviewWidget} from '../PeerReviewWidget'

describe('PeerReviewWidget', () => {
  const defaultProps = {
    assignmentId: '123',
    courseId: '456',
  }

  it('renders the widget', () => {
    render(<PeerReviewWidget {...defaultProps} />)
    expect(screen.getByText('Peer Review')).toBeInTheDocument()
  })

  it('renders the peer review icon and text', () => {
    render(<PeerReviewWidget {...defaultProps} />)
    expect(screen.getByText('Peer Review')).toBeInTheDocument()
  })

  it('renders the View Configuration button', () => {
    render(<PeerReviewWidget {...defaultProps} />)
    const button = screen.getByTestId('view-configuration-button')
    expect(button).toBeInTheDocument()
    expect(button).toHaveTextContent('View Configuration')
  })

  it('renders the Allocate Peer Reviews button', () => {
    render(<PeerReviewWidget {...defaultProps} />)
    const button = screen.getByTestId('allocate-peer-reviews-button')
    expect(button).toBeInTheDocument()
    expect(button).toHaveTextContent('Allocate Peer Reviews')
  })

  it('renders all buttons', () => {
    render(<PeerReviewWidget {...defaultProps} />)
    expect(screen.getByTestId('view-configuration-button')).toBeInTheDocument()
    expect(screen.getByTestId('allocate-peer-reviews-button')).toBeInTheDocument()
  })
})

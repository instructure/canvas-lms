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
import {ScanningInProgressView} from '../components/ScanningInProgressView'

describe('ScanningInProgressView', () => {
  it('renders loading spinner with correct title', () => {
    render(<ScanningInProgressView />)

    expect(screen.getByTitle('Scanning in progress')).toBeInTheDocument()
  })

  it('renders "Hang tight!" message', () => {
    render(<ScanningInProgressView />)

    expect(screen.getByText('Hang tight!')).toBeInTheDocument()
  })

  it('renders scanning duration message', () => {
    render(<ScanningInProgressView />)

    expect(
      screen.getByText(
        'Scanning might take a few seconds or up to several minutes, depending on how much content your course contains.',
      ),
    ).toBeInTheDocument()
  })

  it('has scan button disabled', () => {
    render(<ScanningInProgressView />)

    const button = screen.getByRole('button', {name: /scan course/i})
    expect(button).toBeDisabled()
  })
})

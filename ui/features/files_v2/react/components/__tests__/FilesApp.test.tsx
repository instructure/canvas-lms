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
import {render, screen} from '@testing-library/react'
import FilesApp from '../FilesApp'

describe('FilesApp', () => {
  it('renders "Files" when contextAssetString starts with "course_"', () => {
    render(<FilesApp contextAssetString="course_12345" />)

    const headingElement = screen.getByText(/Files/i)
    expect(headingElement).toBeInTheDocument()
  })

  it('renders "All My Files" when contextAssetString does not start with "course_"', () => {
    render(<FilesApp contextAssetString="user_67890" />)

    const headingElement = screen.getByText(/All My Files/i)
    expect(headingElement).toBeInTheDocument()
  })
})

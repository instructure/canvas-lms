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
import FilesHeader from '../FilesHeader'
import {render, screen} from '@testing-library/react'

describe('FilesHeader', () => {
  it('renders "Files" when not in a user context', async () => {
    render(<FilesHeader isUserContext={false} size="small" />)

    const headingElement = await screen.findByText('Files', {exact: true})
    expect(headingElement).toBeInTheDocument()
  })

  it('renders "All My Files" when in a user context', async () => {
    render(<FilesHeader isUserContext={true} size="small" />)

    const headingElement = await screen.findByText(/All My Files/i)
    expect(headingElement).toBeInTheDocument()
  })
})

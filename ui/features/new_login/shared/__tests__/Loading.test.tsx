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

import {render, screen, waitFor} from '@testing-library/react'
import React from 'react'
import {Loading} from '..'

describe('Loading Component', () => {
  it('renders with default loading title', async () => {
    render(<Loading />)
    await waitFor(() => {
      expect(screen.getByTitle('Loading …')).toBeInTheDocument()
    })
  })

  it('renders with a custom loading title', async () => {
    const customTitle = 'Fetching Data...'
    render(<Loading title={customTitle} />)
    await waitFor(() => {
      expect(screen.getByTitle(customTitle)).toBeInTheDocument()
    })
  })
})

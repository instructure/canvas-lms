/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import ModuleTooltip from '../ModuleTooltip'

describe('ModuleTooltip', () => {
  const modules = ['Module 1', 'Module 2', 'Module 3']

  it('renders "Multiple Modules" link text', () => {
    render(<ModuleTooltip modules={modules} />)
    expect(screen.getByText('Multiple Modules')).toBeInTheDocument()
  })

  it('shows module names on hover', async () => {
    const user = userEvent.setup()
    render(<ModuleTooltip modules={modules} />)

    await user.hover(screen.getByText('Multiple Modules'))

    expect(await screen.findByText(modules.join(', '))).toBeInTheDocument()
  })
})

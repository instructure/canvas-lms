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
import ContextModuleLink from '../ContextModuleLink'

describe('ContextModuleLink', () => {
  it('renders', async () => {
    render(
      <ContextModuleLink courseId="1" contextModuleId="2" contextModuleName="My fabulous module" />
    )
    expect(await screen.findByTestId('context-module-text')).toBeInTheDocument()
    const link = screen.getByRole('link', {name: 'My fabulous module'})
    expect(link).toHaveAttribute('target', '_blank')
    expect(link).toHaveAttribute('href', '/courses/1/modules#2')
  })

  it('does not render', async () => {
    render(<ContextModuleLink />)
    expect(screen.queryByTestId('temp-context-module-text')).not.toBeInTheDocument()
    expect(screen.queryByTestId('context-module-text')).not.toBeInTheDocument()
    expect(screen.queryByRole('link', {name: 'My fabulous module'})).not.toBeInTheDocument()
  })
})

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

import {render, screen} from '@testing-library/react'
import React from 'react'
import RenderGuard from '../RenderGuard'

describe('RenderGuard', () => {
  const markerId = 'new_login_safe_to_mount'

  afterEach(() => {
    document.getElementById(markerId)?.remove()
    jest.restoreAllMocks()
  })

  it('renders children when marker is present', () => {
    const marker = document.createElement('div')
    marker.setAttribute('id', markerId)
    document.body.appendChild(marker)
    render(
      <RenderGuard>
        <div>App Content</div>
      </RenderGuard>,
    )
    expect(screen.getByText('App Content')).toBeInTheDocument()
  })

  it('renders nothing when marker is missing', () => {
    render(
      <RenderGuard>
        <div>Should Not Appear</div>
      </RenderGuard>,
    )
    expect(screen.queryByText('Should Not Appear')).not.toBeInTheDocument()
  })

  it('renders nothing when blocked', () => {
    render(
      <RenderGuard>
        <div>Blocked</div>
      </RenderGuard>,
    )
    expect(screen.queryByText('Blocked')).not.toBeInTheDocument()
  })
})

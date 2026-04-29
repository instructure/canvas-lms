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
import DeprecationNoticeAlert from '../DeprecationNoticeAlert'

describe('DeprecationNoticeAlert', () => {
  it('renders warning alert with title, body, and link by default', () => {
    render(<DeprecationNoticeAlert />)
    const alert = screen.getByTestId('eportfolio-deprecation-notice')
    expect(alert).toBeVisible()
    expect(screen.getByText('ePortfolios Will Be Sunset')).toBeInTheDocument()
    expect(screen.getByText(/planned for deprecation/i)).toBeInTheDocument()

    const link = screen.getByTestId('eportfolio-deprecation-community-link')
    expect(link).toBeVisible()
    expect(link.getAttribute('href')).toMatch(/^https:\/\/community\.canvaslms\.com\//)
    expect(link).toHaveAttribute('target', '_blank')
    expect(link).toHaveAttribute('rel', 'noopener noreferrer')
  })

  it('does not render when open prop is false', () => {
    const {container} = render(<DeprecationNoticeAlert open={false} />)
    expect(container).toBeEmptyDOMElement()
  })
})

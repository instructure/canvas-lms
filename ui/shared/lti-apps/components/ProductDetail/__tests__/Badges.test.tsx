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
import Badges from '../Badges'
import '@testing-library/jest-dom/extend-expect'
import {Badges as BadgesType} from '../../../models/Product'

// Mock the useBreakpoints hook
jest.mock('../../../hooks/useBreakpoints', () => ({
  __esModule: true,
  default: jest.fn(() => ({
    isDesktop: true,
    isMobile: false,
  })),
}))

describe('Badges', () => {
  const mockBadges: BadgesType = {
    image_url: 'https://example.com/badge.png',
    link: 'https://example.com/badge',
    name: 'Example Badge',
    description: 'This is an example badge description',
  }

  it('renders correctly with provided badges', () => {
    render(<Badges badges={mockBadges} />)

    // Check if the image is rendered
    expect(screen.getByRole('img')).toHaveAttribute('src', mockBadges.image_url)

    // Check if the badge name is rendered as a link
    const badgeLink = screen.getByRole('link', {name: mockBadges.name})
    expect(badgeLink).toHaveAttribute('href', mockBadges.link)
    expect(badgeLink).toHaveAttribute('target', '_blank')

    // Check if the description is rendered
    expect(screen.getByText(mockBadges.description)).toBeInTheDocument()
  })

  it('does not render anything when badges prop is falsy', () => {
    const {container} = render(<Badges badges={null as unknown as BadgesType} />)
    expect(container.firstChild).toBeEmptyDOMElement()
  })
})

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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {DiscoveryPageStatus} from '../DiscoveryPageStatus'
import {openWindow} from '@canvas/util/globalUtils'

vi.mock('@canvas/util/globalUtils', async importOriginal => {
  const original = await importOriginal<typeof import('@canvas/util/globalUtils')>()
  return {
    ...original,
    openWindow: vi.fn(),
  }
})

const mockedOpenWindow = vi.mocked(openWindow)

describe('DiscoveryPageStatus', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  describe('status pill', () => {
    it('renders "Disabled" pill when active is false', () => {
      render(<DiscoveryPageStatus active={false} />)
      expect(screen.getByText('Disabled')).toBeInTheDocument()
      expect(screen.queryByText(/^Enabled$/)).not.toBeInTheDocument()
    })

    it('renders "Enabled" pill when active is true', () => {
      render(<DiscoveryPageStatus active={true} />)
      expect(screen.getByText('Enabled')).toBeInTheDocument()
      expect(screen.queryByText('Disabled')).not.toBeInTheDocument()
    })

    it('renders no pill when active is undefined', () => {
      render(<DiscoveryPageStatus />)
      expect(screen.queryByText('Enabled')).not.toBeInTheDocument()
      expect(screen.queryByText('Disabled')).not.toBeInTheDocument()
    })
  })

  describe('view link', () => {
    it('does not render the link when viewUrl is undefined', () => {
      render(<DiscoveryPageStatus active={false} />)
      expect(screen.queryByText('View Discovery Page')).not.toBeInTheDocument()
    })

    it('does not render the link when viewUrl is empty string', () => {
      render(<DiscoveryPageStatus active={false} viewUrl="" />)
      expect(screen.queryByText('View Discovery Page')).not.toBeInTheDocument()
    })

    it('renders the link when viewUrl is provided', () => {
      render(<DiscoveryPageStatus active={true} viewUrl="https://example.com/discovery" />)
      expect(screen.getByText('View Discovery Page')).toBeInTheDocument()
    })

    it('includes screen reader text indicating the link opens in a new tab', () => {
      render(<DiscoveryPageStatus active={true} viewUrl="https://example.com/discovery" />)
      expect(screen.getByText('(opens in new tab)')).toBeInTheDocument()
    })

    it('calls openWindow with the URL and _blank target when clicked', async () => {
      const user = userEvent.setup()
      render(<DiscoveryPageStatus active={true} viewUrl="https://example.com/discovery" />)
      await user.click(screen.getByText('View Discovery Page'))
      expect(mockedOpenWindow).toHaveBeenCalledWith('https://example.com/discovery', '_blank')
    })
  })
})

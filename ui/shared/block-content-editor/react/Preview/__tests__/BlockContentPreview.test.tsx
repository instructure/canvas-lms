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

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {BlockContentPreview} from '../BlockContentPreview'

vi.mock('../../hooks/useGetSerializedNodes', () => ({
  useGetSerializedNodes: vi.fn(),
}))

const renderPreview = () => {
  return render(<BlockContentPreview />)
}

describe('BlockContentPreview', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should select "desktop" by default', async () => {
    const {getByRole} = renderPreview()
    const desktopTab = getByRole('tab', {name: /desktop/i})

    expect(desktopTab).toHaveAttribute('aria-selected', 'true')
  })

  it('should switch to "tablet" when the tablet tab is clicked', async () => {
    const user = userEvent.setup()
    const {getByRole} = renderPreview()
    const tabletTab = getByRole('tab', {name: /tablet/i})

    await user.click(tabletTab)

    expect(tabletTab).toHaveAttribute('aria-selected', 'true')
  })

  it('should switch to "mobile" when the mobile tab is clicked', async () => {
    const user = userEvent.setup()
    const {getByRole} = renderPreview()
    const mobileTab = getByRole('tab', {name: /mobile/i})

    await user.click(mobileTab)

    expect(mobileTab).toHaveAttribute('aria-selected', 'true')
  })
})

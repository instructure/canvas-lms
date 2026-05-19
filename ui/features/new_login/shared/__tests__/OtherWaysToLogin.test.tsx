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

import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import OtherWaysToLogin from '../OtherWaysToLogin'
import {useNewLogin, useNewLoginData} from '../../context'
import {assignLocation} from '@canvas/util/globalUtils'

vi.mock('../../context', async () => {
  const original = await vi.importActual('../../context')
  return {
    ...original,
    useNewLogin: vi.fn(),
    useNewLoginData: vi.fn(),
  }
})

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

const mockUseNewLogin = useNewLogin as any
const mockUseNewLoginData = useNewLoginData as any
const mockAssignLocation = assignLocation as any

describe('OtherWaysToLogin', () => {
  const defaultUrl = '/login'

  const renderOtherWaysToLogin = (url: string = defaultUrl) =>
    render(<OtherWaysToLogin url={url} />)

  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseNewLoginData.mockReturnValue({
      discoveryEnabled: true,
      isPreviewMode: false,
    })
  })

  it('renders the link if discoveryEnabled is true', () => {
    renderOtherWaysToLogin()
    expect(screen.getByTestId('other-ways-to-login-link')).toBeInTheDocument()
    expect(screen.getByText('Other ways to log in')).toBeInTheDocument()
  })

  it('does not render the link if discoveryEnabled is false', () => {
    mockUseNewLoginData.mockReturnValue({
      discoveryEnabled: false,
      isPreviewMode: false,
    })
    renderOtherWaysToLogin()
    expect(screen.queryByTestId('other-ways-to-login-link')).not.toBeInTheDocument()
  })

  it('does not render the link if discoveryEnabled is undefined', () => {
    mockUseNewLoginData.mockReturnValue({
      discoveryEnabled: undefined,
      isPreviewMode: false,
    })
    renderOtherWaysToLogin()
    expect(screen.queryByTestId('other-ways-to-login-link')).not.toBeInTheDocument()
  })

  it('calls assignLocation on click if not disabled', async () => {
    renderOtherWaysToLogin()
    await userEvent.click(screen.getByTestId('other-ways-to-login-link'))
    expect(mockAssignLocation).toHaveBeenCalledWith(defaultUrl)
  })

  it('does not call assignLocation when isUiActionPending is true', async () => {
    mockUseNewLogin.mockReturnValue({isUiActionPending: true})
    renderOtherWaysToLogin()
    await userEvent.click(screen.getByTestId('other-ways-to-login-link'))
    expect(mockAssignLocation).not.toHaveBeenCalled()
  })

  it('does not call assignLocation when isPreviewMode is true', async () => {
    mockUseNewLoginData.mockReturnValue({
      discoveryEnabled: true,
      isPreviewMode: true,
    })
    renderOtherWaysToLogin()
    await userEvent.click(screen.getByTestId('other-ways-to-login-link'))
    expect(mockAssignLocation).not.toHaveBeenCalled()
  })
})

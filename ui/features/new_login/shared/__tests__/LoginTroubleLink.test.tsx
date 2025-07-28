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
import userEvent from '@testing-library/user-event'
import LoginTroubleLink from '../LoginTroubleLink'
import {useNewLogin, useNewLoginData} from '../../context'
import {assignLocation} from '@canvas/util/globalUtils'

jest.mock('../../context', () => {
  const original = jest.requireActual('../../context')
  return {
    ...original,
    useNewLogin: jest.fn(),
    useNewLoginData: jest.fn(),
  }
})

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

const mockUseNewLogin = useNewLogin as jest.Mock
const mockUseNewLoginData = useNewLoginData as jest.Mock
const mockAssignLocation = assignLocation as jest.Mock

describe('LoginTroubleLink', () => {
  const defaultUrl = 'https://example.com/help'

  const renderLoginTroubleLink = (url: string | null = defaultUrl) =>
    render(<LoginTroubleLink url={url} />)

  beforeEach(() => {
    jest.clearAllMocks()
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
    })
  })

  it('renders the link if url is present', () => {
    renderLoginTroubleLink()
    expect(screen.getByTestId('login-trouble-link')).toBeInTheDocument()
    expect(screen.getByText('Trouble logging in?')).toBeInTheDocument()
  })

  it('does not render the link if url is null', () => {
    renderLoginTroubleLink(null)
    expect(screen.queryByTestId('login-trouble-link')).not.toBeInTheDocument()
  })

  it('calls assignLocation on click if not disabled', async () => {
    renderLoginTroubleLink()
    await userEvent.click(screen.getByTestId('login-trouble-link'))
    expect(mockAssignLocation).toHaveBeenCalledWith(defaultUrl)
  })

  it('does not call assignLocation when isUiActionPending is true', async () => {
    mockUseNewLogin.mockReturnValue({isUiActionPending: true})
    renderLoginTroubleLink()
    await userEvent.click(screen.getByTestId('login-trouble-link'))
    expect(mockAssignLocation).not.toHaveBeenCalled()
  })

  it('does not call assignLocation when isPreviewMode is true', async () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: true,
    })
    renderLoginTroubleLink()
    await userEvent.click(screen.getByTestId('login-trouble-link'))
    expect(mockAssignLocation).not.toHaveBeenCalled()
  })
})

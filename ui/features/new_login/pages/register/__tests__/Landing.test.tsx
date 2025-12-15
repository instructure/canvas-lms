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

import {cleanup, fireEvent, render, screen} from '@testing-library/react'
import React from 'react'
import {MemoryRouter} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider,useNewLogin} from '../../../context'
import Landing from '../Landing'

const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  }
})


vi.mock('../../../context', async () => {
  const originalModule = await vi.importActual('../../../context')
  return {
    ...originalModule,
    useNewLogin: vi.fn(() => ({isUiActionPending: false})),
  }
})
const mockUseNewLogin = vi.mocked(useNewLogin)

describe('Landing', () => {
  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  const renderLanding = () =>
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <Landing />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )

  it('renders heading with the correct text', () => {
    renderLanding()
    expect(screen.getByText('Create Your Account')).toBeInTheDocument()
  })

  it('renders all role selection cards', () => {
    renderLanding()
    expect(screen.getByText('Teacher')).toBeInTheDocument()
    expect(screen.getByText('Student')).toBeInTheDocument()
    expect(screen.getByText('Parent')).toBeInTheDocument()
  })

  it('renders links with correct hrefs', () => {
    renderLanding()
    expect(screen.getByLabelText('Create Teacher Account')).toHaveAttribute(
      'href',
      '/login/canvas/register/teacher',
    )
    expect(screen.getByLabelText('Create Student Account')).toHaveAttribute(
      'href',
      '/login/canvas/register/student',
    )
    expect(screen.getByLabelText('Create Parent Account')).toHaveAttribute(
      'href',
      '/login/canvas/register/parent',
    )
  })

  it('calls navigate function when a card is clicked', () => {
    renderLanding()
    const teacherCard = screen.getByLabelText('Create Teacher Account')
    fireEvent.click(teacherCard)
    expect(mockNavigate).toHaveBeenCalledWith('/login/canvas/register/teacher')
  })

  it('prevents navigation when a "ui action" is pending', () => {
    vi.mocked(mockUseNewLogin).mockReturnValueOnce({
      isUiActionPending: true,
      setIsUiActionPending: vi.fn(),
      rememberMe: false,
      setRememberMe: vi.fn(),
      otpRequired: false,
      setOtpRequired: vi.fn(),
      showForgotPassword: false,
      setShowForgotPassword: vi.fn(),
      otpCommunicationChannelId: null,
      setOtpCommunicationChannelId: vi.fn(),
    })
    renderLanding()
    const teacherCard = screen.getByLabelText('Create Teacher Account')
    fireEvent.click(teacherCard)
    expect(mockNavigate).not.toHaveBeenCalled()
  })
})

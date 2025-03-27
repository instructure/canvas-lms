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

import {fireEvent, render, screen} from '@testing-library/react'
import React from 'react'
import {MemoryRouter} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider} from '../../../context'
import Landing from '../Landing'

const mockNavigate = jest.fn()
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}))

jest.mock('../../../context', () => {
  const originalModule = jest.requireActual('../../../context')
  return {
    ...originalModule,
    useNewLogin: jest.fn(() => ({isUiActionPending: false})),
  }
})
const mockUseNewLogin = require('../../../context').useNewLogin

describe('Landing', () => {
  beforeEach(() => {
    jest.clearAllMocks()
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

  it('prevents navigation when a “ui action” is pending', () => {
    mockUseNewLogin.mockReturnValueOnce({isUiActionPending: true})
    renderLanding()
    const teacherCard = screen.getByLabelText('Create Teacher Account')
    fireEvent.click(teacherCard)
    expect(mockNavigate).not.toHaveBeenCalled()
  })
})

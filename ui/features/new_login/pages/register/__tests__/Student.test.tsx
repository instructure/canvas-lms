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

import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MemoryRouter, useLocation, useNavigate, useNavigationType} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLoginData} from '../../../context'
import Student from '../Student'

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: vi.fn(),
    useNavigationType: vi.fn(),
    useLocation: vi.fn(),
  }
})

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

vi.mock('../../../services', () => ({
  createStudentAccount: vi.fn(),
}))

vi.mock('../../../context', async () => {
  const actual = await vi.importActual<typeof import('../../../context')>('../../../context')
  return {
    ...actual,
    useNewLoginData: vi.fn(() => ({
      isDataLoading: false,
    })),
  }
})

const mockNavigate = vi.fn()
const mockedUseNavigate = useNavigate as ReturnType<typeof vi.fn>
const mockNavigationType = useNavigationType as ReturnType<typeof vi.fn>
const mockedUseLocation = useLocation as ReturnType<typeof vi.fn>

describe('Student - form rendering', () => {
  const setup = () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <Student />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
  }

  beforeEach(() => {
    vi.clearAllMocks()
    vi.restoreAllMocks()
    mockedUseNavigate.mockReturnValue(mockNavigate)
    mockNavigationType.mockReturnValue('PUSH')
    mockedUseLocation.mockReturnValue({key: 'default'})
    ;(useNewLoginData as ReturnType<typeof vi.fn>).mockImplementation(() => ({
      isDataLoading: false,
      loginHandleName: 'Email',
      privacyPolicyUrl: '',
      requireEmail: false,
      termsOfUseUrl: '',
      termsRequired: false,
    }))
  })

  afterEach(() => {
    cleanup()
  })

  it('renders all required input fields', async () => {
    setup()
    expect(await screen.findByTestId('name-input')).toBeInTheDocument()
    expect(screen.getByTestId('username-input')).toBeInTheDocument()
    expect(screen.getByTestId('password-input')).toBeInTheDocument()
    expect(screen.getByTestId('confirm-password-input')).toBeInTheDocument()
    expect(screen.getByTestId('join-code-input')).toBeInTheDocument()
  })

  it('renders terms checkbox when required', async () => {
    ;(useNewLoginData as ReturnType<typeof vi.fn>).mockImplementation(() => ({
      isDataLoading: false,
      termsRequired: true,
      privacyPolicyUrl: 'http://www.example.com/privacy',
      termsOfUseUrl: 'http://www.example.com/terms',
    }))
    setup()
    expect(await screen.findByTestId('terms-and-policy-checkbox')).toBeInTheDocument()
  })

  it('renders email input when required', async () => {
    ;(useNewLoginData as ReturnType<typeof vi.fn>).mockImplementation(() => ({
      isDataLoading: false,
      requireEmail: true,
    }))
    setup()
    expect(await screen.findByTestId('email-input')).toBeInTheDocument()
  })

  describe('navigation behavior', () => {
    describe('when the cancel button is clicked', () => {
      it('navigates to login when there is no previous history', async () => {
        setup()
        const backButton = screen.getByTestId('back-button')
        await userEvent.click(backButton)
        expect(mockNavigate).toHaveBeenCalledWith('/login/canvas')
        expect(mockNavigate).toHaveBeenCalledTimes(1)
      })

      it('navigates back to the previous page when history exists', async () => {
        mockNavigationType.mockReturnValue('PUSH')
        mockedUseLocation.mockReturnValue({key: 'abc123'})
        mockedUseNavigate.mockReturnValue(mockNavigate)
        setup()
        const backButton = screen.getByTestId('back-button')
        await userEvent.click(backButton)
        expect(mockNavigate).toHaveBeenCalledWith(-1)
        expect(mockNavigate).toHaveBeenCalledTimes(1)
      })

      it('navigates to fallback when navigationType is POP or key is default', async () => {
        mockNavigationType.mockReturnValue('POP')
        mockedUseLocation.mockReturnValue({key: 'default'})
        mockedUseNavigate.mockReturnValue(mockNavigate)
        setup()
        const backButton = screen.getByTestId('back-button')
        await userEvent.click(backButton)
        expect(mockNavigate).toHaveBeenCalledWith('/login/canvas')
      })
    })
  })
})

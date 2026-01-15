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
import React from 'react'
import {MemoryRouter} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLoginData} from '../../../context'
import Student from '../Student'

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
})

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
import {act, render, screen, waitFor} from '@testing-library/react'
import {MemoryRouter, Routes} from 'react-router-dom'
import {NewLoginRoutes} from '../NewLoginRoutes'
import '@testing-library/jest-dom'

jest.mock('../../assets/images/instructure-logo.svg', () => 'instructure-logo.svg')
jest.mock('../../pages/SignIn', () => () => <div>Sign In Page</div>)
jest.mock('../../pages/ForgotPassword', () => () => <div>Forgot Password Page</div>)
jest.mock('@instructure/ui-img', () => {
  const Img = ({src, alt}: {src: string; alt: string}) => <img src={src} alt={alt} />
  return {Img}
})
jest.mock('react-router-dom', () => {
  const originalModule = jest.requireActual('react-router-dom')
  return {
    ...originalModule,
    // mock ScrollRestoration to avoid errors since this test uses MemoryRouter, which is not a data
    // router and ScrollRestoration requires a data router to function properly
    ScrollRestoration: () => null,
  }
})

describe('NewLoginRoutes', () => {
  it('renders SignIn component at /login/canvas', async () => {
    await act(async () => {
      render(
        <MemoryRouter initialEntries={['/login/canvas']}>
          <Routes>{NewLoginRoutes}</Routes>
        </MemoryRouter>
      )
    })
    await waitFor(() => expect(screen.getByText('Sign In Page')).toBeInTheDocument())
  })

  it('renders ForgotPassword component at /login/canvas/forgot-password', async () => {
    await act(async () => {
      render(
        <MemoryRouter initialEntries={['/login/canvas/forgot-password']}>
          <Routes>{NewLoginRoutes}</Routes>
        </MemoryRouter>
      )
    })
    await waitFor(() => expect(screen.getByText('Forgot Password Page')).toBeInTheDocument())
  })

  it('redirects to SignIn component for unknown paths', async () => {
    await act(async () => {
      render(
        <MemoryRouter initialEntries={['/login/canvas/unknown']}>
          <Routes>{NewLoginRoutes}</Routes>
        </MemoryRouter>
      )
    })
    await waitFor(() => expect(screen.getByText('Sign In Page')).toBeInTheDocument())
  })
})

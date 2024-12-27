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

import {render} from '@testing-library/react'
import React from 'react'
import {MemoryRouter} from 'react-router-dom'
import {LoginLayout} from '../LoginLayout'
import '@testing-library/jest-dom'
import {HelpTrayProvider, NewLoginDataProvider, NewLoginProvider} from '../../context'

jest.mock('react-router-dom', () => {
  const originalModule = jest.requireActual('react-router-dom')
  return {
    ...originalModule,
    // mock ScrollRestoration to avoid errors since this test uses MemoryRouter, which is not a data
    // router and ScrollRestoration requires a data router to function properly
    ScrollRestoration: () => null,
  }
})

describe('LoginLayout', () => {
  it('renders without crashing', () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <HelpTrayProvider>
              <LoginLayout />
            </HelpTrayProvider>
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
  })
})

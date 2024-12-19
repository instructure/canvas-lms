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
import '@testing-library/jest-dom'
import SignIn from '../SignIn'
import {MemoryRouter} from 'react-router-dom'
import {NewLoginProvider} from '../../context/NewLoginContext'
import {render} from '@testing-library/react'

jest.mock('../../context/NewLoginContext', () => {
  const actualContext = jest.requireActual('../../context/NewLoginContext')
  return {
    ...actualContext,
    useNewLogin: () => ({
      ...actualContext.useNewLogin(),
      // mock the data attribute default values that would normally be provided by the back-end
      loginHandleName: 'Email',
    }),
  }
})

describe('SignIn', () => {
  it('mounts without crashing', () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <SignIn />
        </NewLoginProvider>
      </MemoryRouter>
    )
  })
})
